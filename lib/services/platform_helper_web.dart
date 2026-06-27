// ignore_for_file: avoid_web_libraries_in_flutter
// ignore_for_file: deprecated_member_use
import 'dart:html' as html;

void saveFile(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}
