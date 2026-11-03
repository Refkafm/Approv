import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_processing.dart';

/// Sumber foto bukti. Di tes diganti versi palsu lewat [PhotoPickerScope].
abstract interface class PhotoPicker {
  /// Ambil satu foto dari kamera (atau galeri bila diizinkan tugasnya, PF-07), lalu kompres
  /// & beri [stamp]. null bila pengguna membatalkan.
  Future<Uint8List?> take({required bool fromGallery, required String stamp});
}

/// Kamera bawaan HP lewat image_picker: selalu memotret foto baru, jadi anak tidak bisa
/// memakai foto lama kecuali tugasnya mengizinkan galeri.
class DevicePhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<Uint8List?> take({required bool fromGallery, required String stamp}) async {
    final file = await _picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      // Perkecil di sisi native dulu supaya decode di Dart tidak berat
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 90,
    );
    if (file == null) return null;
    final raw = await file.readAsBytes();
    return compute(processProofPhoto, ProofPhotoJob(raw, stamp));
  }
}

class PhotoPickerScope extends InheritedWidget {
  const PhotoPickerScope({super.key, required this.picker, required super.child});

  final PhotoPicker picker;

  static PhotoPicker of(BuildContext context) => context.getInheritedWidgetOfExactType<PhotoPickerScope>()!.picker;

  @override
  bool updateShouldNotify(PhotoPickerScope oldWidget) => picker != oldWidget.picker;
}
