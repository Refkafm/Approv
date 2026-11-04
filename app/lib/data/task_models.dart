/// Model tugas & laporan. Kolom & batasan mengikuti tabel tasks / task_submissions
/// di supabase/migrations/20261102000100_schema.sql.
library;

import '../l10n/strings.dart';

enum TaskFrequency {
  once('once'),
  daily('daily'),
  daysOfWeek('days_of_week'),
  weekly('weekly'),
  repeat('repeat');

  const TaskFrequency(this.db);

  final String db;

  String get label => switch (this) {
    once => S.current.freqOnce,
    daily => S.current.freqDaily,
    daysOfWeek => S.current.freqDaysOfWeek,
    weekly => S.current.freqWeekly,
    repeat => S.current.freqRepeat,
  };

  static TaskFrequency parse(String value) => values.firstWhere((f) => f.db == value);

  /// Frekuensi yang batas laporan per harinya bisa diatur (T-05). Sekali & mingguan selalu 1.
  bool get hasDailyLimit => this == daily || this == daysOfWeek || this == repeat;
}

enum TaskVerification {
  auto('auto'),
  approve('approve'),
  photo('photo');

  const TaskVerification(this.db);

  final String db;

  String get label => switch (this) {
    auto => S.current.verifyAuto,
    approve => S.current.verifyApprove,
    photo => S.current.verifyPhoto,
  };

  static TaskVerification parse(String value) => values.firstWhere((v) => v.db == value);
}

/// Nama hari ISO singkat (1 = Senin), sesuai bahasa aktif.
Map<int, String> get isoDayNames => {for (var d = 1; d <= 7; d++) d: S.current.isoDayShort(d)};

/// Isi form tugas (PRD T-01–T-05).
class TaskInput {
  const TaskInput({
    required this.title,
    required this.points,
    required this.frequency,
    required this.verification,
    this.icon,
    this.description,
    this.daysOfWeek = const [],
    this.maxPerDay = 1,
    this.minPhotos = 1,
    this.beforeAfter = false,
    this.allowGallery = false,
    this.assigneeIds = const [],
  });

  final String title;
  final int points;
  final TaskFrequency frequency;
  final TaskVerification verification;
  final String? icon;
  final String? description;

  /// Hari ISO, hanya untuk [TaskFrequency.daysOfWeek].
  final List<int> daysOfWeek;
  final int maxPerDay;

  /// Hanya untuk [TaskVerification.photo].
  final int minPhotos;
  final bool beforeAfter;
  final bool allowGallery;

  /// Kosong = untuk semua anak (T-04).
  final List<String> assigneeIds;

  bool get needsPhoto => verification == TaskVerification.photo;

  int get effectiveMaxPerDay => frequency.hasDailyLimit ? maxPerDay : 1;

  /// Pesan untuk pengguna bila tidak valid; sama dengan CHECK di tabel tasks.
  String? validate() {
    final name = title.trim();
    if (name.isEmpty) return S.current.taskNameRequired;
    if (name.length > 60) return S.current.taskNameTooLong;
    if (points < 1 || points > 100000) return S.current.taskPointsRange;
    if (frequency == TaskFrequency.daysOfWeek && daysOfWeek.isEmpty) return S.current.pickAtLeastOneDay;
    if (frequency.hasDailyLimit && (maxPerDay < 1 || maxPerDay > 20)) return S.current.dailyLimitRange;
    if (needsPhoto && (minPhotos < 1 || minPhotos > 3)) return S.current.photoCountRange;
    if ((description?.length ?? 0) > 500) return S.current.descriptionTooLong;
    return null;
  }

  /// Kolom tabel tasks (tanpa id, family_id, is_archived). Penugasan disimpan terpisah.
  Map<String, dynamic> toRow() => {
    'title': title.trim(),
    'icon': icon,
    'description': (description?.trim().isEmpty ?? true) ? null : description!.trim(),
    'points': points,
    'frequency': frequency.db,
    'days_of_week': frequency == TaskFrequency.daysOfWeek ? (List.of(daysOfWeek)..sort()) : null,
    'max_per_day': effectiveMaxPerDay,
    'verification': verification.db,
    'min_photos': needsPhoto ? minPhotos : 0,
    'before_after': needsPhoto && beforeAfter,
    'allow_gallery': needsPhoto && allowGallery,
  };
}

class Task extends TaskInput {
  const Task({
    required this.id,
    required this.familyId,
    this.isArchived = false,
    required super.title,
    required super.points,
    required super.frequency,
    required super.verification,
    super.icon,
    super.description,
    super.daysOfWeek,
    super.maxPerDay,
    super.minPhotos,
    super.beforeAfter,
    super.allowGallery,
    super.assigneeIds,
  });

  factory Task.fromInput(TaskInput input, {required String id, required String familyId, bool isArchived = false}) {
    final row = input.toRow();
    return Task(
      id: id,
      familyId: familyId,
      isArchived: isArchived,
      title: row['title'] as String,
      icon: input.icon,
      description: row['description'] as String?,
      points: input.points,
      frequency: input.frequency,
      daysOfWeek: (row['days_of_week'] as List<int>?) ?? const [],
      maxPerDay: input.effectiveMaxPerDay,
      verification: input.verification,
      minPhotos: input.needsPhoto ? input.minPhotos : 1,
      beforeAfter: input.needsPhoto && input.beforeAfter,
      allowGallery: input.needsPhoto && input.allowGallery,
      assigneeIds: List.unmodifiable(input.assigneeIds),
    );
  }

  /// Baris tasks dengan relasi `task_assignments(member_id)`.
  factory Task.fromRow(Map<String, dynamic> row) => Task(
    id: row['id'] as String,
    familyId: row['family_id'] as String,
    isArchived: row['is_archived'] as bool? ?? false,
    title: row['title'] as String,
    icon: row['icon'] as String?,
    description: row['description'] as String?,
    points: row['points'] as int,
    frequency: TaskFrequency.parse(row['frequency'] as String),
    daysOfWeek: ((row['days_of_week'] as List?) ?? const []).cast<int>(),
    maxPerDay: row['max_per_day'] as int? ?? 1,
    verification: TaskVerification.parse(row['verification'] as String),
    minPhotos: (row['min_photos'] as int? ?? 0).clamp(1, 3),
    beforeAfter: row['before_after'] as bool? ?? false,
    allowGallery: row['allow_gallery'] as bool? ?? false,
    assigneeIds: [for (final a in (row['task_assignments'] as List?) ?? const []) (a as Map)['member_id'] as String],
  );

  final String id;
  final String familyId;
  final bool isArchived;

  bool isFor(String memberId) => assigneeIds.isEmpty || assigneeIds.contains(memberId);

  /// Ringkasan aturan untuk daftar tugas, mis. "Harian · maks 2×/hari · Persetujuan + foto".
  String get scheduleLabel {
    final parts = <String>[
      frequency == TaskFrequency.daysOfWeek ? daysOfWeek.map((d) => isoDayNames[d]).join(', ') : frequency.label,
      if (frequency.hasDailyLimit && maxPerDay > 1) S.current.maxPerDayShortLabel(maxPerDay),
      verification.label,
    ];
    return parts.join(' · ');
  }
}

enum SubmissionStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  needsRetake('needs_retake');

  const SubmissionStatus(this.db);

  final String db;

  static SubmissionStatus parse(String value) => values.firstWhere((s) => s.db == value);
}

/// Laporan tugas secukupnya untuk menghitung status "tugas hari ini".
class SubmissionSummary {
  const SubmissionSummary({
    required this.taskId,
    required this.status,
    required this.forDate,
    required this.createdAt,
    this.id,
    this.reason,
    this.reversed = false,
  });

  factory SubmissionSummary.fromRow(Map<String, dynamic> row) => SubmissionSummary(
    id: row['id'] as String?,
    reason: row['reject_reason'] as String?,
    taskId: row['task_id'] as String,
    status: SubmissionStatus.parse(row['status'] as String),
    forDate: DateTime.parse(row['for_date'] as String),
    createdAt: DateTime.parse(row['created_at'] as String),
    reversed: row['reversed_at'] != null,
  );

  /// task_submissions.id; dibutuhkan untuk mengirim foto ulang (resubmit_photos).
  final String? id;

  /// Alasan ditolak / catatan foto ulang dari orang tua (terlihat oleh anak, PRD L-04).
  final String? reason;
  final String taskId;
  final SubmissionStatus status;

  /// Tanggal lapor di zona waktu keluarga (tanpa jam).
  final DateTime forDate;
  final DateTime createdAt;

  /// Tugas otomatis yang dibatalkan admin.
  final bool reversed;

  /// Menghabiskan jatah laporan (sama dengan cek di RPC submit_task).
  bool get countsTowardLimit => status != SubmissionStatus.rejected && !reversed;
}
