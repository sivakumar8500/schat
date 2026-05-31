import 'dart:io';

void main() {
  final dir = Directory('d:/Siva_Pro/schat');
  final regexHeight = RegExp(r'SizedBox\(\s*height:\s*([0-9\.]+)\s*\)');
  final regexWidth = RegExp(r'SizedBox\(\s*width:\s*([0-9\.]+)\s*\)');

  final heights = <double>{};
  final widths = <double>{};

  final files = dir.listSync(recursive: true);
  for (final file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      // Ignore some generated/build files if any
      if (file.path.contains('.dart_tool') || file.path.contains('.git')) continue;
      final content = file.readAsStringSync();
      for (final match in regexHeight.allMatches(content)) {
        final val = double.parse(match.group(1)!);
        heights.add(val);
      }
      for (final match in regexWidth.allMatches(content)) {
        final val = double.parse(match.group(1)!);
        widths.add(val);
      }
    }
  }

  print('Heights found: $heights');
  print('Widths found: $widths');
}
