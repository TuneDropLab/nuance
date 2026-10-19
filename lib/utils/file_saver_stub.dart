import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> saveOrShareImageBytes(Uint8List bytes, String fileName, {String? title}) async {
  await Share.shareXFiles(
    [
      XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: fileName,
      ),
    ],
    text: title ?? 'Created with Nuance',
  );
}
