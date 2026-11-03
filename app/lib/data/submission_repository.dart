import 'package:flutter/painting.dart';

import 'models.dart';
import 'photo_models.dart';
import 'task_models.dart';

/// Laporan tugas yang menunggu persetujuan (antrean O-4, detail O-5).
class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.taskTitle,
    required this.verification,
    required this.points,
    required this.forDate,
    required this.createdAt,
    this.memberAvatar,
    this.taskIcon,
    this.note,
    this.isFlagged = false,
  });

  /// Baris task_submissions dengan relasi `task:tasks(...)` dan `member:members!member_id(...)`.
  factory ReviewItem.fromRow(Map<String, dynamic> row) {
    final task = row['task'] as Map<String, dynamic>;
    final member = row['member'] as Map<String, dynamic>;
    return ReviewItem(
      id: row['id'] as String,
      memberId: row['member_id'] as String,
      memberName: member['name'] as String,
      memberAvatar: member['avatar'] as String?,
      taskTitle: task['title'] as String,
      taskIcon: task['icon'] as String?,
      verification: TaskVerification.parse(task['verification'] as String),
      points: row['points_snapshot'] as int,
      forDate: DateTime.parse(row['for_date'] as String),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      note: row['note'] as String?,
      isFlagged: row['is_flagged'] as bool? ?? false,
    );
  }

  final String id;
  final String memberId;
  final String memberName;
  final String? memberAvatar;
  final String taskTitle;
  final String? taskIcon;
  final TaskVerification verification;

  /// Poin yang dikunci saat dilaporkan (points_snapshot).
  final int points;
  final DateTime forDate;
  final DateTime createdAt;
  final String? note;

  /// Menunggu lebih dari 72 jam.
  final bool isFlagged;
}

enum ReviewAction {
  approve,
  reject,

  /// Minta foto ulang (PF-05), hanya untuk tugas berfoto.
  retake,
}

/// Laporan & persetujuan (PRD modul 4). Semua method melempar AppException saat gagal.
abstract interface class SubmissionRepository {
  /// Anak melapor tugas selesai (L-01). Untuk tugas berfoto (L-02), [photos] diunggah dulu ke bucket
  /// privat, lalu dikaitkan ke laporan; jumlah & jenisnya diperiksa server (_insert_photos).
  ///
  /// [reportedAt]: waktu lapor sebenarnya untuk laporan dari antrean offline; server menghitung
  /// "hari tugas" dari waktu ini (maks 24 jam ke belakang). Melempar AppException('offline') bila
  /// tidak ada sinyal.
  Future<void> submitTask({
    required Member member,
    required String taskId,
    String? note,
    List<PhotoCapture> photos = const [],
    DateTime? reportedAt,
  });

  /// Kirim foto ulang untuk laporan berstatus "perlu foto ulang" (PF-05), tanpa laporan baru.
  Future<void> resubmitPhotos({
    required Member member,
    required String submissionId,
    required List<PhotoCapture> photos,
  });

  /// Foto bukti sebuah laporan (yang belum dihapus/diganti).
  Future<List<ProofPhoto>> submissionPhotos(String submissionId);

  /// Gambar foto bukti untuk ditampilkan (signed URL yang kedaluwarsa di Supabase).
  Future<ImageProvider> proofImage(ProofPhoto photo);

  /// Antrean laporan yang menunggu, terlama di atas.
  Future<List<ReviewItem>> pendingReviews(String familyId);

  /// L-03, L-04, L-06: setujui (dengan bonus opsional), tolak (alasan wajib), atau minta foto ulang.
  Future<void> reviewSubmission(String submissionId, ReviewAction action, {String? reason, int bonus = 0});

  /// Berbunyi setiap kali laporan di keluarga ini berubah (realtime), untuk memuat ulang layar.
  Stream<void> watchFamily(String familyId);
}
