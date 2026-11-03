import 'task_models.dart';
import 'task_rules.dart';
import 'wallet_models.dart';

DayActivity _activityOn(List<SubmissionSummary> submissions, DateTime day) {
  final mine = submissions.where((s) => dateOnly(s.forDate) == day);
  if (mine.any((s) => s.status == SubmissionStatus.approved && !s.reversed)) return DayActivity.success;
  if (mine.any((s) => s.status == SubmissionStatus.pending || s.status == SubmissionStatus.needsRetake)) {
    return DayActivity.pending;
  }
  return DayActivity.empty;
}

/// Aktivitas Senin–Minggu pada minggu ISO yang memuat [today].
List<DayActivity> weekActivity(List<SubmissionSummary> submissions, DateTime today) {
  final monday = weekStart(today);
  return [for (var i = 0; i < 7; i++) _activityOn(submissions, monday.add(Duration(days: i)))];
}

/// Salinan _recompute_streak di SQL (aturan bisnis 8): hari berhasil menambah streak, hari tertunda
/// tidak memutus, hari kosong memutus (kecuali hari ini yang belum selesai).
int computeStreak(List<SubmissionSummary> submissions, DateTime today) {
  final start = dateOnly(today);
  var count = 0;
  for (
    var day = start;
    day.isAfter(start.subtract(const Duration(days: 400)));
    day = day.subtract(const Duration(days: 1))
  ) {
    switch (_activityOn(submissions, day)) {
      case DayActivity.success:
        count++;
      case DayActivity.pending:
        break;
      case DayActivity.empty:
        if (day != start) return count;
    }
  }
  return count;
}

/// Ringkasan minggu ini untuk detail anak (O-10): dari riwayat transaksi.
({int tasksApproved, int pointsIn, int pointsOut}) weekStats(List<LedgerEntry> history, DateTime today) {
  final monday = weekStart(today);
  var tasks = 0;
  var pointsIn = 0;
  var pointsOut = 0;
  for (final e in history.where((e) => !e.goalBucket && !dateOnly(e.createdAt).isBefore(monday))) {
    if (e.type == LedgerType.task && e.amount > 0) tasks++;
    if (e.amount > 0) {
      pointsIn += e.amount;
    } else {
      pointsOut -= e.amount;
    }
  }
  return (tasksApproved: tasks, pointsIn: pointsIn, pointsOut: pointsOut);
}
