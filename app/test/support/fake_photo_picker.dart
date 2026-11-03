import 'dart:typed_data';

import 'package:family_points/core/photo_picker.dart';
import 'package:image/image.dart' as img;

/// Pengganti kamera di tes: mengembalikan JPEG kecil dan mencatat permintaan.
class FakePhotoPicker implements PhotoPicker {
  final requests = <({bool fromGallery, String stamp})>[];

  /// true = pengguna membatalkan kamera.
  bool cancel = false;

  static final Uint8List jpeg = img.encodeJpg(img.Image(width: 30, height: 40));

  @override
  Future<Uint8List?> take({required bool fromGallery, required String stamp}) async {
    requests.add((fromGallery: fromGallery, stamp: stamp));
    return cancel ? null : jpeg;
  }
}
