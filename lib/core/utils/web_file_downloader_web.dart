import 'dart:html' as html;

Future<void> downloadTextFileOnWeb({
  required String fileName,
  required String content,
  String mimeType = 'text/plain',
}) async {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
}
