import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Batas ukuran foto bukti (PRD 4b: "dikompres ±500 KB").
const maxProofPhotoBytes = 500 * 1024;

class ProofPhotoJob {
  const ProofPhotoJob(this.bytes, this.stamp);

  final Uint8List bytes;

  /// Teks stempel di pojok foto, lihat [proofStampText].
  final String stamp;
}

/// "05/11/2026 10.30 - Raka - Bersihkan kamar" (PRD 4b: stempel waktu, nama anak, nama tugas).
String proofStampText(DateTime takenAt, String childName, String taskTitle) {
  String two(int n) => n.toString().padLeft(2, '0');
  final when = '${two(takenAt.day)}/${two(takenAt.month)}/${takenAt.year} ${two(takenAt.hour)}.${two(takenAt.minute)}';
  return '$when - $childName - $taskTitle';
}

/// Siapkan foto bukti: luruskan orientasi, perkecil, beri stempel, lalu kompres JPEG sampai
/// ≤ [maxProofPhotoBytes]. Berat untuk HP kelas menengah, jadi jalankan lewat `compute`.
Uint8List processProofPhoto(ProofPhotoJob job) {
  final decoded = img.decodeImage(job.bytes);
  if (decoded == null) throw const FormatException('File bukan gambar');
  final upright = img.bakeOrientation(decoded);

  // (sisi terpanjang, kualitas JPEG), dicoba berurutan sampai cukup kecil
  const steps = [(1600, 80), (1600, 65), (1280, 60), (1024, 55), (800, 50), (640, 45)];
  late Uint8List out;
  for (final (side, quality) in steps) {
    final frame = _fit(upright, side);
    _drawStamp(frame, job.stamp);
    out = img.encodeJpg(frame, quality: quality);
    if (out.length <= maxProofPhotoBytes) break;
  }
  return out;
}

img.Image _fit(img.Image source, int longestSide) {
  if (math.max(source.width, source.height) <= longestSide) return source.clone();
  return source.width >= source.height
      ? img.copyResize(source, width: longestSide, interpolation: img.Interpolation.average)
      : img.copyResize(source, height: longestSide, interpolation: img.Interpolation.average);
}

void _drawStamp(img.Image image, String text) {
  final font = image.width >= 1000 ? img.arial24 : img.arial14;
  final ascii = _toAscii(text);
  const pad = 10;
  var textWidth = 0;
  for (final code in ascii.codeUnits) {
    textWidth += font.characters[code]?.xAdvance ?? font.size ~/ 2;
  }
  final boxHeight = font.lineHeight + pad * 2;
  img.fillRect(
    image,
    x1: 0,
    y1: image.height - boxHeight,
    x2: math.min(image.width, textWidth + pad * 2),
    y2: image.height,
    color: img.ColorRgba8(22, 22, 22, 180),
  );
  img.drawString(
    image,
    ascii,
    font: font,
    x: pad,
    y: image.height - font.lineHeight - pad,
    color: img.ColorRgb8(255, 255, 255),
  );
}

/// Font bitmap hanya punya ASCII.
String _toAscii(String text) => String.fromCharCodes(
  text.replaceAll('≥', '>=').replaceAll('≤', '<=').replaceAll('·', '-').codeUnits.where((c) => c >= 32 && c < 127),
);
