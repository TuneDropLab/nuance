// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveOrShareImageBytes(Uint8List bytes, String fileName, {String? title}) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  // Allow browser time to trigger the download before revoking the object URL
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}
