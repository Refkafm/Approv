import 'dart:math';
import 'dart:typed_data';

import 'package:family_points/core/photo_processing.dart';
import 'package:family_points/data/photo_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Foto 12 MP berisi derau acak: kasus terburuk untuk kompresi JPEG.
Uint8List _noisyPhoto({int width = 4000, int height = 3000}) {
  final random = Random(42);
  final image = img.Image(width: width, height: height);
  for (final p in image) {
    p
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return img.encodeJpg(image, quality: 95);
}

void main() {
  group('processProofPhoto (PRD 4b)', () {
    test('foto besar dikecilkan dan dikompres sampai ≤ 500 KB', () {
      final input = _noisyPhoto();
      expect(input.length, greaterThan(maxProofPhotoBytes));

      final out = processProofPhoto(ProofPhotoJob(input, '05/11/2026 10.30 - Raka - Bersihkan kamar'));
      expect(out.length, lessThanOrEqualTo(maxProofPhotoBytes));

      final decoded = img.decodeJpg(out)!;
      expect(max(decoded.width, decoded.height), lessThanOrEqualTo(1600));
      expect(decoded.width / decoded.height, closeTo(4 / 3, 0.01));
    });

    test('foto potret tetap potret', () {
      final out = processProofPhoto(ProofPhotoJob(_noisyPhoto(width: 900, height: 1600), 'x'));
      final decoded = img.decodeJpg(out)!;
      expect(decoded.height, greaterThan(decoded.width));
    });

    test('stempel tergambar di pojok kiri bawah', () {
      final plain = img.Image(width: 800, height: 600)..clear(img.ColorRgb8(255, 255, 255));
      final out = img.decodeJpg(processProofPhoto(ProofPhotoJob(img.encodeJpg(plain), 'Raka - Cuci piring')))!;
      final corner = out.getPixel(4, out.height - 4);
      final center = out.getPixel(400, 300);
      expect(corner.r, lessThan(120), reason: 'latar gelap stempel');
      expect(center.r, greaterThan(230), reason: 'bagian lain foto tidak berubah');
    });

    test('teks non-ASCII aman untuk font bitmap', () {
      final plain = img.encodeJpg(img.Image(width: 200, height: 200));
      expect(() => processProofPhoto(ProofPhotoJob(plain, 'Nilai ujian ≥ 85 · Raka')), returnsNormally);
    });

    test('file bukan gambar ditolak', () {
      expect(() => processProofPhoto(ProofPhotoJob(Uint8List.fromList([1, 2, 3]), 'x')), throwsFormatException);
    });
  });

  test('proofStampText: tanggal, jam, nama anak, nama tugas', () {
    expect(
      proofStampText(DateTime(2026, 11, 5, 9, 7), 'Raka', 'Bersihkan kamar'),
      '05/11/2026 09.07 - Raka - Bersihkan kamar',
    );
  });

  group('missingPhotosLabel (tombol kirim aktif bila foto cukup)', () {
    PhotoCapture photo(PhotoKind kind) =>
        PhotoCapture(bytes: Uint8List(0), kind: kind, origin: PhotoOrigin.camera, takenAt: DateTime(2026));

    test('jumlah minimal', () {
      expect(missingPhotosLabel(photos: const [], minPhotos: 2, beforeAfter: false), 'Butuh 2 foto lagi');
      expect(
        missingPhotosLabel(photos: [photo(PhotoKind.single)], minPhotos: 2, beforeAfter: false),
        'Butuh 1 foto lagi',
      );
      expect(
        missingPhotosLabel(
          photos: [photo(PhotoKind.single), photo(PhotoKind.single)],
          minPhotos: 2,
          beforeAfter: false,
        ),
        isNull,
      );
    });

    test('sebelum & sesudah', () {
      expect(missingPhotosLabel(photos: const [], minPhotos: 1, beforeAfter: true), 'Butuh foto sebelum & sesudah');
      expect(
        missingPhotosLabel(photos: [photo(PhotoKind.before)], minPhotos: 1, beforeAfter: true),
        'Butuh foto sesudah',
      );
      expect(
        missingPhotosLabel(photos: [photo(PhotoKind.before), photo(PhotoKind.after)], minPhotos: 1, beforeAfter: true),
        isNull,
      );
    });
  });
}
