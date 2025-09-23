// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebDownload {
  static void downloadText(
    String text, {
    required String filename,
    String mime = 'text/plain',
  }) {
    final bytes = html.Blob([text], mime);
    final url = html.Url.createObjectUrlFromBlob(bytes);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
