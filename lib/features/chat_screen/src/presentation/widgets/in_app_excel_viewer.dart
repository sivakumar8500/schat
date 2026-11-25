import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:excel_community/excel_community.dart' hide Border, TextSpan;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:xml/xml.dart';

class ExcelSheetData {
  final String name;
  final List<List<String>> rows;
  final int maxColumns;

  ExcelSheetData({
    required this.name,
    required this.rows,
    required this.maxColumns,
  });
}

class InAppExcelViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const InAppExcelViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<InAppExcelViewer> createState() => _InAppExcelViewerState();
}

class _InAppExcelViewerState extends State<InAppExcelViewer> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<ExcelSheetData> _sheets = [];
  int _selectedSheetIndex = 0;

  // Selected cell
  int? _selectedRow;
  int? _selectedCol;
  String _selectedCellAddress = '';
  String _selectedCellValue = '';

  // Search
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Point<int>> _searchResults = []; // (row, col)
  int _currentSearchMatchIndex = 0;

  // Zoom & Pan
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    _loadSpreadsheet();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05 && mounted) {
      setState(() => _currentScale = scale);
    }
  }

  String get _cleanPath => widget.filePath.replaceAll('file://', '');

  Future<void> _loadSpreadsheet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final file = File(_cleanPath);
      if (!await file.exists()) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'File not found on device';
          });
        }
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'The spreadsheet file is empty';
          });
        }
        return;
      }

      final sheets = await _parseExcelBytes(bytes);

      if (mounted) {
        setState(() {
          _sheets = sheets;
          _isLoading = false;
          _selectedSheetIndex = 0;
          if (_sheets.isEmpty) {
            _errorMessage = 'No sheets or data found in spreadsheet';
          } else {
            // Select first cell by default if available
            final currentSheet = _sheets.first;
            if (currentSheet.rows.isNotEmpty && currentSheet.rows.first.isNotEmpty) {
              _selectCell(0, 0);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading spreadsheet: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load spreadsheet: $e';
        });
      }
    }
  }

  Future<List<ExcelSheetData>> _parseExcelBytes(Uint8List bytes) async {
    final sheets = <ExcelSheetData>[];

    // 0. Primary for legacy .xls (BIFF8 / OLE2 Compound Document)
    if (bytes.length >= 8 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0 &&
        bytes[4] == 0xA1 &&
        bytes[5] == 0xB1 &&
        bytes[6] == 0x1A &&
        bytes[7] == 0xE1) {
      try {
        final biffSheets = _parseBiff8Spreadsheet(bytes);
        if (biffSheets.isNotEmpty) return biffSheets;
      } catch (e) {
        debugPrint('BIFF8 .xls parser failed: $e');
      }
    }

    // 1. Primary for modern .xlsx: Use excel_community
    try {
      final excel = Excel.decodeBytes(bytes);
      for (final sheetName in excel.tables.keys) {
        final table = excel.tables[sheetName];
        if (table == null) continue;

        final rows = <List<String>>[];
        int maxCols = 0;

        for (final row in table.rows) {
          final rowStrings = row.map((cell) => _cleanCellText(_formatCellValue(cell?.value))).toList();
          if (rowStrings.length > maxCols) maxCols = rowStrings.length;
          rows.add(rowStrings);
        }

        // Clean trailing empty rows
        while (rows.isNotEmpty && rows.last.every((c) => c.trim().isEmpty)) {
          rows.removeLast();
        }

        if (rows.isNotEmpty) {
          sheets.add(ExcelSheetData(name: sheetName, rows: rows, maxColumns: maxCols));
        }
      }
    } catch (e) {
      debugPrint('excel_community decode failed, falling back: $e');
    }

    if (sheets.isNotEmpty) return sheets;

    // 2. Fallback: Direct OpenXML zip + xml parser
    try {
      final openXmlSheets = _parseOpenXmlSpreadsheet(bytes);
      if (openXmlSheets.isNotEmpty) return openXmlSheets;
    } catch (e) {
      debugPrint('OpenXML fallback failed: $e');
    }

    // 3. Fallback: HTML table (common for banking / exported .xls)
    try {
      final htmlSheets = _parseHtmlTable(bytes);
      if (htmlSheets.isNotEmpty) return htmlSheets;
    } catch (e) {
      debugPrint('HTML table fallback failed: $e');
    }

    // 4. Fallback: CSV / TSV
    try {
      final textSheets = _parseCsvTsv(bytes);
      if (textSheets.isNotEmpty) return textSheets;
    } catch (e) {
      debugPrint('CSV/TSV fallback failed: $e');
    }

    return sheets;
  }

  String _formatCellValue(CellValue? val) {
    if (val == null) return '';
    switch (val) {
      case TextCellValue(:final value):
        return value.text ?? value.toString();
      case FormulaCellValue(:final formula):
        return formula;
      case IntCellValue(:final value):
        return value.toString();
      case DoubleCellValue(:final value):
        // Avoid scientific notation for clean numbers if reasonable
        if (value == value.roundToDouble() && value.abs() < 1e12) {
          return value.toInt().toString();
        }
        return value.toString();
      case BoolCellValue(:final value):
        return value ? 'TRUE' : 'FALSE';
      case DateCellValue():
        return val.toString();
      case DateTimeCellValue():
        return val.toString();
      case TimeCellValue():
        return val.toString();
    }
  }

  List<ExcelSheetData> _parseOpenXmlSpreadsheet(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) return [];

    final archive = ZipDecoder().decodeBytes(bytes);

    // Parse shared strings
    final sharedStrings = <String>[];
    final ssFile = archive.findFile('xl/sharedStrings.xml');
    if (ssFile != null) {
      final xml = XmlDocument.parse(utf8.decode(ssFile.content as List<int>, allowMalformed: true));
      for (final si in xml.findAllElements('si')) {
        final tBuffer = StringBuffer();
        for (final t in si.findAllElements('t')) {
          tBuffer.write(t.innerText);
        }
        sharedStrings.add(tBuffer.toString());
      }
    }

    // Parse workbook
    final sheetNames = <String>[];
    final wbFile = archive.findFile('xl/workbook.xml');
    if (wbFile != null) {
      final xml = XmlDocument.parse(utf8.decode(wbFile.content as List<int>, allowMalformed: true));
      for (final s in xml.findAllElements('sheet')) {
        sheetNames.add(s.getAttribute('name') ?? 'Sheet ${sheetNames.length + 1}');
      }
    }

    final results = <ExcelSheetData>[];
    int sheetIdx = 1;

    while (true) {
      final sFile = archive.findFile('xl/worksheets/sheet$sheetIdx.xml');
      if (sFile == null) break;

      final xml = XmlDocument.parse(utf8.decode(sFile.content as List<int>, allowMalformed: true));
      final rowsMap = <int, Map<int, String>>{};
      int maxCol = 0;
      int maxRow = 0;

      for (final rowElem in xml.findAllElements('row')) {
        final rAttr = rowElem.getAttribute('r');
        final rIdx = (rAttr != null ? int.tryParse(rAttr) : null) ?? (maxRow + 1);
        if (rIdx > maxRow) maxRow = rIdx;

        for (final cElem in rowElem.findAllElements('c')) {
          final rCoord = cElem.getAttribute('r') ?? '';
          final tAttr = cElem.getAttribute('t') ?? '';

          int colIdx = 0;
          final colLetters = RegExp(r'[A-Za-z]+').firstMatch(rCoord)?.group(0)?.toUpperCase();
          if (colLetters != null) {
            int c = 0;
            for (int i = 0; i < colLetters.length; i++) {
              c = c * 26 + (colLetters.codeUnitAt(i) - 64);
            }
            colIdx = c;
          }
          if (colIdx > maxCol) maxCol = colIdx;

          String cellVal = '';
          if (tAttr == 's') {
            final vElem = cElem.findElements('v').firstOrNull;
            final sIdx = int.tryParse(vElem?.innerText ?? '');
            if (sIdx != null && sIdx >= 0 && sIdx < sharedStrings.length) {
              cellVal = sharedStrings[sIdx];
            }
          } else if (tAttr == 'inlineStr') {
            cellVal = cElem.findAllElements('t').map((e) => e.innerText).join();
          } else if (tAttr == 'b') {
            final vElem = cElem.findElements('v').firstOrNull;
            cellVal = vElem?.innerText == '1' ? 'TRUE' : 'FALSE';
          } else {
            final vElem = cElem.findElements('v').firstOrNull;
            cellVal = vElem?.innerText ?? '';
          }

          rowsMap.putIfAbsent(rIdx, () => {})[colIdx] = cellVal;
        }
      }

      final sheetRows = <List<String>>[];
      for (int r = 1; r <= maxRow; r++) {
        final row = <String>[];
        final rowData = rowsMap[r] ?? {};
        for (int c = 1; c <= maxCol; c++) {
          row.add(rowData[c] ?? '');
        }
        sheetRows.add(row);
      }

      final sheetName = (sheetIdx - 1 < sheetNames.length)
          ? sheetNames[sheetIdx - 1]
          : 'Sheet $sheetIdx';

      if (sheetRows.isNotEmpty) {
        results.add(ExcelSheetData(name: sheetName, rows: sheetRows, maxColumns: maxCol));
      }
      sheetIdx++;
    }

    return results;
  }

  List<ExcelSheetData> _parseHtmlTable(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    if (!text.toLowerCase().contains('<table')) return [];

    final rows = <List<String>>[];
    int maxCols = 0;

    final trReg = RegExp(r'<tr[^>]*>([\s\S]*?)<\/tr>', caseSensitive: false);
    final tdReg = RegExp(r'<(td|th)[^>]*>([\s\S]*?)<\/\1>', caseSensitive: false);

    for (final trMatch in trReg.allMatches(text)) {
      final trContent = trMatch.group(1) ?? '';
      final rowCells = <String>[];

      for (final tdMatch in tdReg.allMatches(trContent)) {
        var cellContent = tdMatch.group(2) ?? '';
        cellContent = cellContent
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .trim();
        rowCells.add(cellContent);
      }

      if (rowCells.isNotEmpty) {
        if (rowCells.length > maxCols) maxCols = rowCells.length;
        rows.add(rowCells);
      }
    }

    if (rows.isEmpty) return [];
    return [ExcelSheetData(name: 'Table', rows: rows, maxColumns: maxCols)];
  }

  List<ExcelSheetData> _parseCsvTsv(Uint8List bytes) {
    // If bytes look binary (contain null bytes in the first 512 bytes or start with OLE/ZIP header), NEVER parse as CSV/TSV
    if (bytes.length >= 4 &&
        ((bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0) ||
         (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04))) {
      return [];
    }
    final sampleLen = bytes.length > 512 ? 512 : bytes.length;
    for (int i = 0; i < sampleLen; i++) {
      if (bytes[i] == 0) return []; // Null byte means binary file, not CSV!
    }

    final text = utf8.decode(bytes, allowMalformed: true);
    final isTsv = text.contains('\t');
    final delimiter = isTsv ? '\t' : ',';

    final lines = text.split(RegExp(r'\r\n|\r|\n'));
    final rows = <List<String>>[];
    int maxCols = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final cells = line.split(delimiter).map((c) => _cleanCellText(c.trim().replaceAll('"', ''))).toList();
      if (cells.length > maxCols) maxCols = cells.length;
      rows.add(cells);
    }

    if (rows.isEmpty) return [];
    return [ExcelSheetData(name: 'Data', rows: rows, maxColumns: maxCols)];
  }

  List<ExcelSheetData> _parseBiff8Spreadsheet(Uint8List bytes) {
    if (bytes.length < 512) return [];
    if (bytes[0] != 0xD0 ||
        bytes[1] != 0xCF ||
        bytes[2] != 0x11 ||
        bytes[3] != 0xE0 ||
        bytes[4] != 0xA1 ||
        bytes[5] != 0xB1 ||
        bytes[6] != 0x1A ||
        bytes[7] != 0xE1) {
      return [];
    }

    try {
      final byteData = ByteData.sublistView(bytes);

      final sectorShift = byteData.getUint16(30, Endian.little);
      final sectorSize = 1 << sectorShift;
      final numFatSectors = byteData.getUint32(44, Endian.little);
      final firstDirSector = byteData.getUint32(48, Endian.little);

      final fatSectors = <int>[];
      for (int i = 0; i < numFatSectors && i < 109; i++) {
        fatSectors.add(byteData.getUint32(76 + i * 4, Endian.little));
      }

      int getSectorOffset(int secIndex) => 512 + secIndex * sectorSize;

      final fat = <int>[];
      for (final fs in fatSectors) {
        final off = getSectorOffset(fs);
        final count = sectorSize ~/ 4;
        for (int i = 0; i < count; i++) {
          if (off + (i + 1) * 4 <= bytes.length) {
            fat.add(byteData.getUint32(off + i * 4, Endian.little));
          }
        }
      }

      Uint8List readStream(int startSec) {
        final builder = BytesBuilder();
        int curr = startSec;
        int guard = 0;
        while (curr >= 0 && curr < fat.length && curr < 0xFFFFFFFE && guard < 10000) {
          guard++;
          final off = getSectorOffset(curr);
          if (off + sectorSize <= bytes.length) {
            builder.add(bytes.sublist(off, off + sectorSize));
          } else if (off < bytes.length) {
            builder.add(bytes.sublist(off));
          }
          curr = fat[curr];
        }
        return builder.toBytes();
      }

      final dirBytes = readStream(firstDirSector);
      if (dirBytes.isEmpty) return [];
      final dirData = ByteData.sublistView(dirBytes);

      int? workbookStartSec;
      int workbookSize = 0;

      for (int i = 0; i + 128 <= dirBytes.length; i += 128) {
        final nameLen = dirData.getUint16(i + 64, Endian.little);
        if (nameLen > 2) {
          final nameChars = <int>[];
          for (int c = 0; c < nameLen - 2; c += 2) {
            nameChars.add(dirData.getUint16(i + c, Endian.little));
          }
          final name = String.fromCharCodes(nameChars);
          if (name == 'Workbook' || name == 'Book') {
            workbookStartSec = dirData.getUint32(i + 116, Endian.little);
            workbookSize = dirData.getUint32(i + 120, Endian.little);
            break;
          }
        }
      }

      if (workbookStartSec == null) return [];

      final fullWb = readStream(workbookStartSec);
      final wb = (workbookSize > 0 && workbookSize <= fullWb.length)
          ? fullWb.sublist(0, workbookSize)
          : fullWb;
      final wbData = ByteData.sublistView(wb);

      final sst = <String>[];
      final sheetMeta = <_BiffSheetMeta>[];

      int pos = 0;
      while (pos + 4 <= wb.length) {
        final recType = wbData.getUint16(pos, Endian.little);
        final recLen = wbData.getUint16(pos + 2, Endian.little);
        pos += 4;
        if (pos + recLen > wb.length) break;

        if (recType == 0x0085) {
          // BOUNDSHEET
          final substreamPos = wbData.getUint32(pos, Endian.little);
          final cch = wb[pos + 6];
          final flag = wb[pos + 7];
          String name;
          if ((flag & 1) != 0 && pos + 8 + cch * 2 <= wb.length) {
            final chars = <int>[];
            for (int c = 0; c < cch * 2; c += 2) {
              chars.add(wbData.getUint16(pos + 8 + c, Endian.little));
            }
            name = String.fromCharCodes(chars);
          } else if (pos + 8 + cch <= wb.length) {
            name = String.fromCharCodes(wb.sublist(pos + 8, pos + 8 + cch));
          } else {
            name = 'Sheet';
          }
          sheetMeta.add(_BiffSheetMeta(name, substreamPos));
        } else if (recType == 0x00FC) {
          // SST (Shared String Table)
          if (recLen >= 8) {
            final uniqueCount = wbData.getUint32(pos + 4, Endian.little);
            int p = pos + 8;
            for (int s = 0; s < uniqueCount && p + 3 <= pos + recLen; s++) {
              final cch = wbData.getUint16(p, Endian.little);
              final flags = wb[p + 2];
              p += 3;
              final is16Bit = (flags & 1) != 0;
              final hasRichSt = (flags & 8) != 0;
              final hasExtSt = (flags & 4) != 0;
              int richRuns = 0;
              int extLen = 0;
              if (hasRichSt && p + 2 <= pos + recLen) {
                richRuns = wbData.getUint16(p, Endian.little);
                p += 2;
              }
              if (hasExtSt && p + 4 <= pos + recLen) {
                extLen = wbData.getInt32(p, Endian.little);
                p += 4;
              }
              String str = '';
              if (is16Bit) {
                final byteLen = cch * 2;
                if (p + byteLen <= pos + recLen) {
                  final chars = <int>[];
                  for (int c = 0; c < byteLen; c += 2) {
                    chars.add(wbData.getUint16(p + c, Endian.little));
                  }
                  str = String.fromCharCodes(chars);
                  p += byteLen;
                }
              } else {
                if (p + cch <= pos + recLen) {
                  str = String.fromCharCodes(wb.sublist(p, p + cch));
                  p += cch;
                }
              }
              p += richRuns * 4;
              p += extLen;
              sst.add(str);
            }
          }
        }
        pos += recLen;
      }

      String decodeRk(int rk) {
        double num;
        if ((rk & 2) != 0) {
          num = (rk >> 2).toDouble();
        } else {
          final b = ByteData(8);
          b.setUint32(4, rk & 0xFFFFFFFC, Endian.little);
          num = b.getFloat64(0, Endian.little);
        }
        if ((rk & 1) != 0) {
          num /= 100.0;
        }
        if (num.isFinite && num == num.roundToDouble() && num.abs() < 1e12) {
          return num.toInt().toString();
        }
        return num.toString();
      }

      final results = <ExcelSheetData>[];

      for (final meta in sheetMeta) {
        final cellMap = <int, Map<int, String>>{};
        int p = meta.substreamOffset;
        int maxCol = 0;
        int maxRow = 0;

        while (p + 4 <= wb.length) {
          final recType = wbData.getUint16(p, Endian.little);
          final recLen = wbData.getUint16(p + 2, Endian.little);
          p += 4;
          if (p + recLen > wb.length) break;

          if (recType == 0x000A) {
            // EOF
            break;
          } else if (recType == 0x00FD) {
            // LABELSST
            if (recLen >= 10) {
              final r = wbData.getUint16(p, Endian.little);
              final c = wbData.getUint16(p + 2, Endian.little);
              final idx = wbData.getUint32(p + 6, Endian.little);
              final val = (idx < sst.length) ? sst[idx] : '';
              cellMap.putIfAbsent(r, () => {})[c] = val;
              if (c + 1 > maxCol) maxCol = c + 1;
              if (r + 1 > maxRow) maxRow = r + 1;
            }
          } else if (recType == 0x0204) {
            // LABEL
            if (recLen >= 8) {
              final r = wbData.getUint16(p, Endian.little);
              final c = wbData.getUint16(p + 2, Endian.little);
              final cch = wbData.getUint16(p + 6, Endian.little);
              String str = '';
              if (p + 8 + cch <= wb.length) {
                str = String.fromCharCodes(wb.sublist(p + 8, p + 8 + cch));
              }
              cellMap.putIfAbsent(r, () => {})[c] = str;
              if (c + 1 > maxCol) maxCol = c + 1;
              if (r + 1 > maxRow) maxRow = r + 1;
            }
          } else if (recType == 0x027E) {
            // RK
            if (recLen >= 10) {
              final r = wbData.getUint16(p, Endian.little);
              final c = wbData.getUint16(p + 2, Endian.little);
              final rk = wbData.getUint32(p + 6, Endian.little);
              cellMap.putIfAbsent(r, () => {})[c] = decodeRk(rk);
              if (c + 1 > maxCol) maxCol = c + 1;
              if (r + 1 > maxRow) maxRow = r + 1;
            }
          } else if (recType == 0x00BD) {
            // MULRK
            if (recLen >= 6) {
              final r = wbData.getUint16(p, Endian.little);
              final cFirst = wbData.getUint16(p + 2, Endian.little);
              final cLast = wbData.getUint16(p + recLen - 2, Endian.little);
              int currC = cFirst;
              int off = p + 4;
              while (currC <= cLast && off + 6 <= p + recLen) {
                final rk = wbData.getUint32(off + 2, Endian.little);
                cellMap.putIfAbsent(r, () => {})[currC] = decodeRk(rk);
                off += 6;
                currC++;
              }
              if (cLast + 1 > maxCol) maxCol = cLast + 1;
              if (r + 1 > maxRow) maxRow = r + 1;
            }
          } else if (recType == 0x0203) {
            // NUMBER
            if (recLen >= 14) {
              final r = wbData.getUint16(p, Endian.little);
              final c = wbData.getUint16(p + 2, Endian.little);
              final val = wbData.getFloat64(p + 6, Endian.little);
              String str;
              if (val.isFinite && val == val.roundToDouble() && val.abs() < 1e12) {
                str = val.toInt().toString();
              } else {
                str = val.toString();
              }
              cellMap.putIfAbsent(r, () => {})[c] = str;
              if (c + 1 > maxCol) maxCol = c + 1;
              if (r + 1 > maxRow) maxRow = r + 1;
            }
          }

          p += recLen;
        }

        final rows = <List<String>>[];
        for (int r = 0; r < maxRow; r++) {
          final rowCells = <String>[];
          final rowData = cellMap[r];
          for (int c = 0; c < maxCol; c++) {
            rowCells.add(_cleanCellText(rowData?[c] ?? ''));
          }
          rows.add(rowCells);
        }

        while (rows.isNotEmpty && rows.last.every((c) => c.trim().isEmpty)) {
          rows.removeLast();
        }

        if (rows.isNotEmpty) {
          results.add(ExcelSheetData(name: meta.name, rows: rows, maxColumns: maxCol));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error parsing BIFF8 spreadsheet: $e');
      return [];
    }
  }

  static String _cleanCellText(String s) {
    if (s.isEmpty) return '';
    return s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
  }

  static String getColumnLetter(int index) {
    int num = index + 1;
    String result = '';
    while (num > 0) {
      int rem = (num - 1) % 26;
      result = String.fromCharCode(65 + rem) + result;
      num = (num - 1) ~/ 26;
    }
    return result;
  }

  void _selectCell(int row, int col) {
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
      _selectedCellAddress = '${getColumnLetter(col)}${row + 1}';

      final currentSheet = _currentSheet;
      if (currentSheet != null &&
          row < currentSheet.rows.length &&
          col < currentSheet.rows[row].length) {
        _selectedCellValue = currentSheet.rows[row][col];
      } else {
        _selectedCellValue = '';
      }
    });
  }

  ExcelSheetData? get _currentSheet {
    if (_sheets.isEmpty) return null;
    if (_selectedSheetIndex >= 0 && _selectedSheetIndex < _sheets.length) {
      return _sheets[_selectedSheetIndex];
    }
    return _sheets.first;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
      _searchResults = [];
      _currentSearchMatchIndex = 0;

      final currentSheet = _currentSheet;
      if (currentSheet != null && _searchQuery.isNotEmpty) {
        for (int r = 0; r < currentSheet.rows.length; r++) {
          final row = currentSheet.rows[r];
          for (int c = 0; c < row.length; c++) {
            if (row[c].toLowerCase().contains(_searchQuery)) {
              _searchResults.add(Point(r, c));
            }
          }
        }

        if (_searchResults.isNotEmpty) {
          final first = _searchResults.first;
          _selectCell(first.x, first.y);
        }
      }
    });
  }

  void _jumpToSearchMatch(int dir) {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex = (_currentSearchMatchIndex + dir) % _searchResults.length;
      if (_currentSearchMatchIndex < 0) _currentSearchMatchIndex = _searchResults.length - 1;
      final target = _searchResults[_currentSearchMatchIndex];
      _selectCell(target.x, target.y);
    });
  }

  void _zoomBy(double factor) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.5, 3.0);
    _transformationController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    setState(() => _currentScale = newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isXlsx = widget.fileName.toLowerCase().endsWith('.xlsx') ||
        _cleanPath.toLowerCase().endsWith('.xlsx');

    return Column(
      children: [
        // Top Toolbar
        _buildTopBar(context, isXlsx),

        // Search Bar (if visible)
        if (_showSearch) _buildSearchBar(context),

        // Formula / Cell Inspector Bar
        if (_selectedCellAddress.isNotEmpty) _buildCellInspectorBar(context),

        // Multi-sheet tabs bar
        if (_sheets.length > 1) _buildSheetTabBar(context),

        // Spreadsheet Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty && _sheets.isEmpty
                  ? _buildErrorView(context)
                  : _buildGridArea(context),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, bool isXlsx) {
    const excelGreen = Color(0xFF107C41);
    final sheet = _currentSheet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.8)),
      ),
      child: Row(
        children: [
          // Excel Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: excelGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isXlsx ? 'XLSX' : 'XLS',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          CommonSpaces.w12,
          // Stats
          Expanded(
            child: Text(
              _isLoading
                  ? 'Loading spreadsheet...'
                  : (sheet != null
                      ? '${sheet.name} • ${sheet.rows.length} rows × ${sheet.maxColumns} cols'
                      : 'Spreadsheet'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Search Toggle
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: _showSearch ? excelGreen : Colors.white70,
              size: 20,
            ),
            tooltip: 'Find in sheet',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchResults = [];
                }
              });
            },
          ),
          // Zoom out
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
            tooltip: 'Zoom out',
            onPressed: () => _zoomBy(0.8),
          ),
          // Reset zoom
          GestureDetector(
            onTap: _resetZoom,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(_currentScale * 100).round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Zoom in
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
            tooltip: 'Zoom in',
            onPressed: () => _zoomBy(1.25),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final count = _searchResults.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.85),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search in sheet...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                isDense: true,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          CommonSpaces.w8,
          Text(
            count > 0 ? '${_currentSearchMatchIndex + 1} of $count' : (_searchQuery.isNotEmpty ? '0 found' : ''),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          CommonSpaces.w4,
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 20),
            onPressed: count > 0 ? () => _jumpToSearchMatch(-1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
            onPressed: count > 0 ? () => _jumpToSearchMatch(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCellInspectorBar(BuildContext context) {
    const excelGreen = Color(0xFF107C41);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.8)),
      ),
      child: Row(
        children: [
          // Cell Coordinate Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: excelGreen.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: excelGreen.withValues(alpha: 0.6), width: 1.0),
            ),
            child: Text(
              _selectedCellAddress,
              style: const TextStyle(
                color: Color(0xFF4ADE80),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          CommonSpaces.w12,
          // Cell Value
          Expanded(
            child: SelectableText(
              _selectedCellValue.isNotEmpty ? _selectedCellValue : '(empty)',
              style: TextStyle(
                color: _selectedCellValue.isNotEmpty ? Colors.white : Colors.white38,
                fontSize: 13,
                fontStyle: _selectedCellValue.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
            ),
          ),
          // Copy button
          if (_selectedCellValue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
              tooltip: 'Copy cell value',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _selectedCellValue));
                context.showSuccessNotification('Cell [$_selectedCellAddress] copied');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSheetTabBar(BuildContext context) {
    const excelGreen = Color(0xFF107C41);

    return Container(
      height: 38,
      color: const Color(0xFF14171D),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _sheets.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedSheetIndex;
          final sheet = _sheets[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSheetIndex = index;
                _selectedRow = null;
                _selectedCol = null;
                _selectedCellAddress = '';
                _selectedCellValue = '';
                _onSearchChanged(_searchQuery);
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? excelGreen.withValues(alpha: 0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFF4ADE80) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${sheet.name} (${sheet.rows.length})',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridArea(BuildContext context) {
    final sheet = _currentSheet;
    if (sheet == null || sheet.rows.isEmpty) {
      return const Center(
        child: Text(
          'This sheet is empty',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Limit initial display rows for extreme sheets to prevent UI lockup
    final displayRowCount = min(sheet.rows.length, 1000);
    final colCount = max(sheet.maxColumns, 1);

    return Container(
      color: const Color(0xFF0F1117),
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 3.0,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222B),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: corner + Column Letters (A, B, C...)
              _buildHeaderRow(colCount),

              // Data Rows
              ...List.generate(displayRowCount, (rowIndex) {
                final row = sheet.rows[rowIndex];
                return _buildDataRow(rowIndex, row, colCount);
              }),

              // If sheet was clipped
              if (sheet.rows.length > displayRowCount)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Showing first $displayRowCount of ${sheet.rows.length} rows',
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(int colCount) {
    const headerBg = Color(0xFF161920);

    return Container(
      decoration: const BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Color(0xFF2E3440), width: 1.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Corner cell (row index column width)
          Container(
            width: 50,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFF2E3440), width: 1.0)),
            ),
            child: const Icon(Icons.grid_on_rounded, color: Colors.white38, size: 14),
          ),
          // Column letters
          ...List.generate(colCount, (colIndex) {
            final isColSelected = _selectedCol == colIndex;

            return Container(
              width: 120,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isColSelected ? const Color(0xFF107C41).withValues(alpha: 0.3) : null,
                border: const Border(right: BorderSide(color: Color(0xFF2E3440), width: 1.0)),
              ),
              child: Text(
                getColumnLetter(colIndex),
                style: TextStyle(
                  color: isColSelected ? const Color(0xFF4ADE80) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataRow(int rowIndex, List<String> rowData, int colCount) {
    final isRowSelected = _selectedRow == rowIndex;
    final rowBg = rowIndex.isEven ? const Color(0xFF1E222B) : const Color(0xFF222731);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2F3B), width: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row Index Header Cell
          Container(
            width: 50,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isRowSelected
                  ? const Color(0xFF107C41).withValues(alpha: 0.3)
                  : const Color(0xFF161920),
              border: const Border(right: BorderSide(color: Color(0xFF2E3440), width: 1.0)),
            ),
            child: Text(
              '${rowIndex + 1}',
              style: TextStyle(
                color: isRowSelected ? const Color(0xFF4ADE80) : Colors.white54,
                fontSize: 11,
                fontWeight: isRowSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Data Cells
          ...List.generate(colCount, (colIndex) {
            final cellText = colIndex < rowData.length ? rowData[colIndex] : '';
            final isCellSelected = _selectedRow == rowIndex && _selectedCol == colIndex;
            final isSearchMatch = _searchQuery.isNotEmpty &&
                cellText.toLowerCase().contains(_searchQuery);

            Color? cellBg;
            if (isSearchMatch) {
              cellBg = const Color(0xFFB45309).withValues(alpha: 0.5); // Warm gold match
            } else if (isCellSelected) {
              cellBg = const Color(0xFF107C41).withValues(alpha: 0.25);
            } else {
              cellBg = rowBg;
            }

            return GestureDetector(
              onTap: () => _selectCell(rowIndex, colIndex),
              onDoubleTap: () {
                _selectCell(rowIndex, colIndex);
                if (cellText.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: cellText));
                  context.showSuccessNotification('Copied: $cellText');
                }
              },
              child: Container(
                width: 120,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: cellBg,
                  border: Border(
                    right: const BorderSide(color: Color(0xFF2A2F3B), width: 0.8),
                    top: isCellSelected ? const BorderSide(color: Color(0xFF4ADE80), width: 1.5) : BorderSide.none,
                    bottom: isCellSelected ? const BorderSide(color: Color(0xFF4ADE80), width: 1.5) : BorderSide.none,
                    left: isCellSelected ? const BorderSide(color: Color(0xFF4ADE80), width: 1.5) : BorderSide.none,
                  ),
                ),
                child: Text(
                  cellText,
                  style: TextStyle(
                    color: isSearchMatch ? const Color(0xFFFDE047) : Colors.white,
                    fontSize: 12,
                    fontWeight: isCellSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_chart_outlined, color: Colors.orangeAccent, size: 54),
            CommonSpaces.h16,
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Unable to view spreadsheet',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h20,
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: _loadSpreadsheet,
            ),
          ],
        ),
      ),
    );
  }
}

class _BiffSheetMeta {
  final String name;
  final int substreamOffset;
  _BiffSheetMeta(this.name, this.substreamOffset);
}
