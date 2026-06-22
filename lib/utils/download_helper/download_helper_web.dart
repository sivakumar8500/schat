import 'dart:html' as html;

void downloadFile(String url, String fileName) {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..target = '_blank';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
