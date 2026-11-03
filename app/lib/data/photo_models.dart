import 'dart:typed_data';

/// Foto bukti (PRD 4b). Kolom mengikuti tabel submission_photos.
enum PhotoKind {
  single('single', ''),
  before('before', 'Sebelum'),
  after('after', 'Sesudah');

  const PhotoKind(this.db, this.label);

  final String db;
  final String label;

  static PhotoKind parse(String value) => values.firstWhere((k) => k.db == value);
}

enum PhotoOrigin { camera, gallery }

/// Foto yang baru diambil di HP, sudah dikompres & diberi stempel, belum diunggah.
class PhotoCapture {
  const PhotoCapture({required this.bytes, required this.kind, required this.origin, required this.takenAt});

  final Uint8List bytes;
  final PhotoKind kind;
  final PhotoOrigin origin;
  final DateTime takenAt;
}

/// Foto yang sudah tersimpan di bucket privat "proofs".
class ProofPhoto {
  const ProofPhoto({
    required this.id,
    required this.kind,
    required this.path,
    required this.takenAt,
    required this.origin,
  });

  factory ProofPhoto.fromRow(Map<String, dynamic> row) => ProofPhoto(
    id: row['id'] as String,
    kind: PhotoKind.parse(row['kind'] as String),
    path: row['storage_path'] as String,
    takenAt: DateTime.parse(row['taken_at'] as String).toLocal(),
    origin: PhotoOrigin.values.byName(row['source'] as String),
  );

  final String id;
  final PhotoKind kind;

  /// {family_id}/{member_id}/{nama file}
  final String path;
  final DateTime takenAt;
  final PhotoOrigin origin;
}

/// Cek jumlah & jenis foto sebelum dikirim; sama dengan _insert_photos di SQL.
/// Mengembalikan teks tombol kirim yang belum bisa ditekan, atau null bila sudah lengkap.
String? missingPhotosLabel({required List<PhotoCapture> photos, required int minPhotos, required bool beforeAfter}) {
  if (beforeAfter) {
    final hasBefore = photos.any((p) => p.kind == PhotoKind.before);
    final hasAfter = photos.any((p) => p.kind == PhotoKind.after);
    if (!hasBefore && !hasAfter) return 'Butuh foto sebelum & sesudah';
    if (!hasBefore) return 'Butuh foto sebelum';
    if (!hasAfter) return 'Butuh foto sesudah';
    return null;
  }
  final missing = minPhotos - photos.length;
  return missing > 0 ? 'Butuh $missing foto lagi' : null;
}
