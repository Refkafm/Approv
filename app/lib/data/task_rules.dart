import 'task_models.dart';

/// Status satu tugas untuk satu anak pada hari ini (layar A-3).
class TodayTask {
  const TodayTask({
    required this.task,
    required this.scheduledToday,
    required this.used,
    required this.limit,
    this.latest,
  });

  final Task task;

  /// Tugas "hari tertentu" yang bukan jadwal hari ini = false.
  final bool scheduledToday;

  /// Laporan yang menghabiskan jatah dalam periode ini (hari / minggu / selamanya).
  final int used;
  final int limit;

  /// Laporan terakhir dalam periode ini (termasuk yang ditolak).
  final SubmissionSummary? latest;

  bool get canReport => scheduledToday && used < limit;

  /// Laporan terakhir menunggu foto ulang (PF-05): anak mengirim foto baru ke laporan yang sama.
  bool get needsRetake => latest?.status == SubmissionStatus.needsRetake;

  /// Status yang ditampilkan ke anak (A-3: belum / menunggu / disetujui / ditolak / perlu foto ulang).
  String get statusLabel {
    if (!scheduledToday) return 'Bukan jadwal hari ini';
    final latest = this.latest;
    if (latest == null) return 'Belum dikerjakan';
    return switch (latest.status) {
      SubmissionStatus.pending => 'Menunggu persetujuan',
      SubmissionStatus.needsRetake => 'Perlu foto ulang',
      SubmissionStatus.rejected =>
        latest.reason == null ? 'Ditolak, coba lagi ya' : 'Ditolak: ${latest.reason}. Coba lagi ya',
      SubmissionStatus.approved when latest.reversed => 'Dibatalkan orang tua',
      SubmissionStatus.approved => canReport ? 'Disetujui · bisa lagi ($used/$limit)' : 'Disetujui',
    };
  }

  /// Urutan tampil: yang bisa dikerjakan dulu, lalu yang menunggu tindakan, lalu yang selesai.
  int get sortGroup {
    if (!scheduledToday) return 4;
    if (latest?.status == SubmissionStatus.needsRetake) return 0;
    if (canReport) return 1;
    if (latest?.status == SubmissionStatus.pending) return 2;
    return 3;
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Senin pada minggu ISO yang memuat [day].
DateTime weekStart(DateTime day) => dateOnly(day).subtract(Duration(days: day.weekday - 1));

/// Daftar tugas hari ini untuk [memberId]. Aturannya sama dengan pengecekan di RPC submit_task:
/// sekali = selamanya, mingguan = minggu ISO ini, lainnya = hari ini; laporan yang ditolak
/// atau dibatalkan tidak menghabiskan jatah.
List<TodayTask> buildTodayTasks({
  required List<Task> tasks,
  required List<SubmissionSummary> submissions,
  required String memberId,
  required DateTime today,
}) {
  final day = dateOnly(today);
  final monday = weekStart(day);

  bool inPeriod(Task task, SubmissionSummary s) => switch (task.frequency) {
    TaskFrequency.once => true,
    TaskFrequency.weekly => !s.forDate.isBefore(monday) && s.forDate.isBefore(monday.add(const Duration(days: 7))),
    _ => dateOnly(s.forDate) == day,
  };

  final result = <TodayTask>[];
  for (final task in tasks) {
    if (task.isArchived || !task.isFor(memberId)) continue;
    final mine = submissions.where((s) => s.taskId == task.id && inPeriod(task, s)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    result.add(
      TodayTask(
        task: task,
        scheduledToday: task.frequency != TaskFrequency.daysOfWeek || task.daysOfWeek.contains(day.weekday),
        used: mine.where((s) => s.countsTowardLimit).length,
        limit: task.effectiveMaxPerDay,
        latest: mine.isEmpty ? null : mine.last,
      ),
    );
  }
  result.sort((a, b) => a.sortGroup.compareTo(b.sortGroup));
  return result;
}
