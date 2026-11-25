import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:docx_viewer_plus/docx_viewer_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:xml/xml.dart';

enum WordBlockType { heading, paragraph, table, list }

class WordRun {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrike;
  final Color? color;

  WordRun({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrike = false,
    this.color,
  });
}

class WordBlock {
  final WordBlockType type;
  final int headingLevel;
  final TextAlign alignment;
  final List<WordRun> runs;
  final List<List<String>> tableData;

  WordBlock({
    required this.type,
    this.headingLevel = 1,
    this.alignment = TextAlign.left,
    this.runs = const [],
    this.tableData = const [],
  });

  String get plainText {
    if (type == WordBlockType.table) {
      return tableData.map((row) => row.join('\t')).join('\n');
    }
    return runs.map((r) => r.text).join();
  }
}

class InAppWordViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const InAppWordViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<InAppWordViewer> createState() => _InAppWordViewerState();
}

class _InAppWordViewerState extends State<InAppWordViewer> {
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isDocx = false;
  bool _useFormattedView = true;
  List<WordBlock> _blocks = [];
  int _wordCount = 0;
  int _paragraphCount = 0;

  // Search
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _matchedBlockIndices = [];
  int _currentMatchIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Zoom
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _cleanAndInit();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _cleanPath => widget.filePath.replaceAll('file://', '');

  void _cleanAndInit() {
    final lower = widget.fileName.toLowerCase();
    _isDocx = lower.endsWith('.docx') || _cleanPath.toLowerCase().endsWith('.docx');

    // Parse blocks for reader mode and stats in background
    _loadDocument();
  }

  Future<void> _loadDocument() async {
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
            _errorMessage = 'The document file is empty';
          });
        }
        return;
      }

      final blocks = await _parseWordBytes(bytes);
      int words = 0;
      int paras = 0;
      for (final b in blocks) {
        final text = b.plainText.trim();
        if (text.isNotEmpty) {
          paras++;
          words += text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        }
      }

      if (mounted) {
        setState(() {
          _blocks = blocks;
          _wordCount = words;
          _paragraphCount = paras;
          _isLoading = false;
          // If not docx or if blocks are empty for docx, use reader view
          if (!_isDocx) {
            _useFormattedView = false;
          }
        });
      }
    } catch (e) {
      debugPrint('InAppWordViewer error loading: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // If error loading docx formatted, fall back to reader view
          _useFormattedView = false;
          if (_blocks.isEmpty) {
            _errorMessage = 'Could not display document content';
          }
        });
      }
    }
  }

  Future<List<WordBlock>> _parseWordBytes(Uint8List bytes) async {
    // 1. Check if it's a zip archive (DOCX format, starts with PK\x03\x04)
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      try {
        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile = archive.findFile('word/document.xml');
        if (docFile != null) {
          final content = utf8.decode(docFile.content as List<int>, allowMalformed: true);
          final blocks = _parseDocxXml(content);
          if (blocks.isNotEmpty) return blocks;
        }
      } catch (e) {
        debugPrint('Failed to parse docx xml: $e');
      }
    }

    // 2. Check if RTF format
    if (bytes.length >= 5 && bytes[0] == 0x7B && bytes[1] == 0x5C && bytes[2] == 0x72 && bytes[3] == 0x74 && bytes[4] == 0x66) {
      try {
        final rtfText = utf8.decode(bytes, allowMalformed: true);
        return _parseRtf(rtfText);
      } catch (_) {}
    }

    // 3. Check if HTML format (frequent in generated .doc reports)
    final sample = utf8.decode(bytes.take(512).toList(), allowMalformed: true).toLowerCase();
    if (sample.contains('<html') || sample.contains('<!doctype') || sample.contains('<body')) {
      try {
        final htmlText = utf8.decode(bytes, allowMalformed: true);
        return _parseHtml(htmlText);
      } catch (_) {}
    }

    // 4. Binary OLE2 DOC extraction (extract readable text runs)
    return _parseBinaryDoc(bytes);
  }

  List<WordBlock> _parseDocxXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final blocks = <WordBlock>[];
      final body = document.findAllElements('w:body').firstOrNull;
      if (body == null) return blocks;

      for (final node in body.children.whereType<XmlElement>()) {
        if (node.name.local == 'p') {
          final runs = <WordRun>[];
          bool isHeading = false;
          int headingLevel = 1;
          TextAlign alignment = TextAlign.left;

          final pPr = node.findElements('w:pPr').firstOrNull;
          if (pPr != null) {
            final pStyle = pPr.findElements('w:pStyle').firstOrNull;
            final styleVal = pStyle?.getAttribute('w:val')?.toLowerCase() ?? '';
            if (styleVal.contains('heading1') || styleVal.contains('title')) {
              isHeading = true;
              headingLevel = 1;
            } else if (styleVal.contains('heading2')) {
              isHeading = true;
              headingLevel = 2;
            } else if (styleVal.contains('heading3')) {
              isHeading = true;
              headingLevel = 3;
            }

            final jc = pPr.findElements('w:jc').firstOrNull;
            final jcVal = jc?.getAttribute('w:val')?.toLowerCase();
            if (jcVal == 'center') {
              alignment = TextAlign.center;
            } else if (jcVal == 'right') {
              alignment = TextAlign.right;
            } else if (jcVal == 'both' || jcVal == 'justify') {
              alignment = TextAlign.justify;
            }
          }

          for (final child in node.children.whereType<XmlElement>()) {
            if (child.name.local == 'r') {
              final rPr = child.findElements('w:rPr').firstOrNull;
              final isBold = rPr?.findElements('w:b').isNotEmpty == true;
              final isItalic = rPr?.findElements('w:i').isNotEmpty == true;
              final isUnderline = rPr?.findElements('w:u').isNotEmpty == true;
              final isStrike = rPr?.findElements('w:strike').isNotEmpty == true;

              final colorElem = rPr?.findElements('w:color').firstOrNull;
              final colorVal = colorElem?.getAttribute('w:val');
              Color? textColor;
              if (colorVal != null && colorVal.length == 6) {
                textColor = Color(int.parse('FF$colorVal', radix: 16));
              }

              final textBuffer = StringBuffer();
              for (final t in child.findElements('w:t')) {
                textBuffer.write(t.innerText);
              }
              if (textBuffer.isNotEmpty) {
                runs.add(WordRun(
                  text: textBuffer.toString(),
                  isBold: isBold,
                  isItalic: isItalic,
                  isUnderline: isUnderline,
                  isStrike: isStrike,
                  color: textColor,
                ));
              }
            }
          }

          if (runs.isNotEmpty) {
            blocks.add(WordBlock(
              type: isHeading ? WordBlockType.heading : WordBlockType.paragraph,
              headingLevel: headingLevel,
              alignment: alignment,
              runs: runs,
            ));
          }
        } else if (node.name.local == 'tbl') {
          final tableRows = <List<String>>[];
          for (final tr in node.findElements('w:tr')) {
            final rowCells = <String>[];
            for (final tc in tr.findElements('w:tc')) {
              final cellText = tc.findAllElements('w:t').map((e) => e.innerText).join(' ').trim();
              rowCells.add(cellText);
            }
            if (rowCells.isNotEmpty) tableRows.add(rowCells);
          }
          if (tableRows.isNotEmpty) {
            blocks.add(WordBlock(
              type: WordBlockType.table,
              tableData: tableRows,
            ));
          }
        }
      }
      return blocks;
    } catch (e) {
      debugPrint('Error in _parseDocxXml: $e');
      return [];
    }
  }

  List<WordBlock> _parseRtf(String rtf) {
    final blocks = <WordBlock>[];
    final clean = rtf
        .replaceAll(RegExp(r'\\[a-zA-Z]+[0-9\-]* ?'), ' ')
        .replaceAll(RegExp(r'[{}]'), '')
        .replaceAll(RegExp(r'\r\n|\r|\n'), '\n');

    final lines = clean.split('\n');
    for (final line in lines) {
      final t = line.trim();
      if (t.isNotEmpty) {
        blocks.add(WordBlock(
          type: WordBlockType.paragraph,
          runs: [WordRun(text: t)],
        ));
      }
    }
    return blocks;
  }

  List<WordBlock> _parseHtml(String html) {
    final blocks = <WordBlock>[];
    final clean = html
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</?(h1|h2|h3|p|div|br|tr)[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    final lines = clean.split('\n');
    for (final line in lines) {
      final t = line.trim();
      if (t.isNotEmpty) {
        blocks.add(WordBlock(
          type: WordBlockType.paragraph,
          runs: [WordRun(text: t)],
        ));
      }
    }
    return blocks;
  }

  List<WordBlock> _parseBinaryDoc(Uint8List bytes) {
    final blocks = <WordBlock>[];
    final buffer = StringBuffer();

    // Scan for printable ASCII runs (length >= 4)
    int i = 0;
    while (i < bytes.length) {
      final b = bytes[i];
      if ((b >= 32 && b <= 126) || b == 10 || b == 13 || b == 9) {
        buffer.writeCharCode(b);
      } else {
        if (buffer.length >= 4) {
          final str = buffer.toString().trim();
          // Filter out typical Word binary metadata noise
          if (str.length > 3 &&
              !str.startsWith('Microsoft Word') &&
              !str.startsWith('Normal.dotm') &&
              !str.startsWith('Times New Roman') &&
              !str.startsWith('Calibri')) {
            blocks.add(WordBlock(
              type: WordBlockType.paragraph,
              runs: [WordRun(text: str)],
            ));
          }
        }
        buffer.clear();
      }
      i++;
    }

    if (buffer.length >= 4) {
      final str = buffer.toString().trim();
      if (str.isNotEmpty) {
        blocks.add(WordBlock(
          type: WordBlockType.paragraph,
          runs: [WordRun(text: str)],
        ));
      }
    }

    return blocks;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
      _matchedBlockIndices = [];
      _currentMatchIndex = 0;

      if (_searchQuery.isNotEmpty) {
        for (int i = 0; i < _blocks.length; i++) {
          if (_blocks[i].plainText.toLowerCase().contains(_searchQuery)) {
            _matchedBlockIndices.add(i);
          }
        }
      }
    });
  }

  void _jumpToMatch(int dir) {
    if (_matchedBlockIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + dir) % _matchedBlockIndices.length;
      if (_currentMatchIndex < 0) _currentMatchIndex = _matchedBlockIndices.length - 1;
    });

    final targetBlock = _matchedBlockIndices[_currentMatchIndex];
    final estimatedOffset = targetBlock * 45.0 * _zoomScale;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Document Sub-bar
        _buildDocumentTopBar(context),

        // Search Bar (if visible)
        if (_showSearch) _buildSearchBar(context),

        // Main Viewer Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty && _blocks.isEmpty
                  ? _buildErrorView(context)
                  : (_isDocx && _useFormattedView)
                      ? _buildDocxPlusViewer(context)
                      : _buildReaderView(context),
        ),
      ],
    );
  }

  Widget _buildDocumentTopBar(BuildContext context) {
    const wordBlue = Color(0xFF2B579A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.8)),
      ),
      child: Row(
        children: [
          // Word format badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: wordBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _isDocx ? 'DOCX' : 'DOC',
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
                  ? 'Loading document...'
                  : '$_wordCount words • $_paragraphCount paragraphs',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // View Switcher (Formatted vs Clean Reader)
          if (_isDocx && _blocks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 6),
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewToggleOption(
                    title: 'Formatted',
                    isSelected: _useFormattedView,
                    onTap: () => setState(() => _useFormattedView = true),
                  ),
                  _buildViewToggleOption(
                    title: 'Reader',
                    isSelected: !_useFormattedView,
                    onTap: () => setState(() => _useFormattedView = false),
                  ),
                ],
              ),
            ),
          // Search toggle
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: _showSearch ? context.colors.primary : Colors.white70,
              size: 20,
            ),
            tooltip: 'Search in document',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                  _matchedBlockIndices = [];
                }
              });
            },
          ),
          // Zoom controls (Reader view)
          if (!_useFormattedView || !_isDocx) ...[
            IconButton(
              icon: const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
              tooltip: 'Zoom out',
              onPressed: () => setState(() => _zoomScale = (_zoomScale - 0.15).clamp(0.7, 2.5)),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
              tooltip: 'Zoom in',
              onPressed: () => setState(() => _zoomScale = (_zoomScale + 0.15).clamp(0.7, 2.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final matchCount = _matchedBlockIndices.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search in document...',
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
            matchCount > 0 ? '${_currentMatchIndex + 1} of $matchCount' : (_searchQuery.isNotEmpty ? '0 found' : ''),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          CommonSpaces.w4,
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 20),
            onPressed: matchCount > 0 ? () => _jumpToMatch(-1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
            onPressed: matchCount > 0 ? () => _jumpToMatch(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDocxPlusViewer(BuildContext context) {
    return Container(
      color: Colors.white,
      child: DocxViewerWidget(
        filePath: _cleanPath,
        config: const DocxViewerConfig(
          isReadOnly: true,
        ),
      ),
    );
  }

  Widget _buildReaderView(BuildContext context) {
    if (_blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, color: Colors.white54, size: 56),
            CommonSpaces.h16,
            const Text(
              'No readable text extracted from this Word document',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E222B),
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 820),
              padding: EdgeInsets.symmetric(
                horizontal: (24 * _zoomScale).clamp(16.0, 48.0),
                vertical: (28 * _zoomScale).clamp(20.0, 56.0),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFD),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(_blocks.length, (index) {
                    final block = _blocks[index];
                    final isCurrentSearchMatch = _matchedBlockIndices.isNotEmpty &&
                        _currentMatchIndex < _matchedBlockIndices.length &&
                        _matchedBlockIndices[_currentMatchIndex] == index;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: isCurrentSearchMatch
                          ? BoxDecoration(
                              color: const Color(0xFFFFF9C4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFBC02D), width: 1.5),
                            )
                          : null,
                      child: _buildBlockWidget(block),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockWidget(WordBlock block) {
    if (block.type == WordBlockType.table) {
      return _buildTableWidget(block.tableData);
    }

    double fontSize = 15.0 * _zoomScale;
    FontWeight fontWeight = FontWeight.normal;
    Color defaultColor = const Color(0xFF262626);

    if (block.type == WordBlockType.heading) {
      if (block.headingLevel == 1) {
        fontSize = 24.0 * _zoomScale;
        fontWeight = FontWeight.bold;
        defaultColor = const Color(0xFF1A1A1A);
      } else if (block.headingLevel == 2) {
        fontSize = 19.0 * _zoomScale;
        fontWeight = FontWeight.bold;
        defaultColor = const Color(0xFF2C3E50);
      } else {
        fontSize = 17.0 * _zoomScale;
        fontWeight = FontWeight.w600;
        defaultColor = const Color(0xFF34495E);
      }
    }

    return Text.rich(
      TextSpan(
        children: block.runs.map((run) {
          final isMatch = _searchQuery.isNotEmpty && run.text.toLowerCase().contains(_searchQuery);

          return TextSpan(
            text: run.text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: run.isBold ? FontWeight.bold : fontWeight,
              fontStyle: run.isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: TextDecoration.combine([
                if (run.isUnderline) TextDecoration.underline,
                if (run.isStrike) TextDecoration.lineThrough,
              ]),
              color: isMatch
                  ? const Color(0xFF000000)
                  : (run.color ?? defaultColor),
              backgroundColor: isMatch ? const Color(0xFFFFEB3B) : null,
              height: 1.55,
            ),
          );
        }).toList(),
      ),
      textAlign: block.alignment,
    );
  }

  Widget _buildTableWidget(List<List<String>> tableData) {
    if (tableData.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE5E7EB), width: 1.0),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: tableData.asMap().entries.map((entry) {
          final isHeader = entry.key == 0;
          return TableRow(
            decoration: BoxDecoration(
              color: isHeader ? const Color(0xFFF3F4F6) : Colors.transparent,
            ),
            children: entry.value.map((cellText) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  cellText,
                  style: TextStyle(
                    fontSize: 13.0 * _zoomScale,
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
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
            const Icon(Icons.error_outline_rounded, color: Colors.orangeAccent, size: 54),
            CommonSpaces.h16,
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Unable to view Word document',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h20,
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: _loadDocument,
            ),
          ],
        ),
      ),
    );
  }
}
