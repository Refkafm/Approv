import 'package:family_points/data/task_models.dart';
import 'package:family_points/data/wallet_models.dart';
import 'package:family_points/data/wallet_rules.dart';
import 'package:flutter_test/flutter_test.dart';

// Kamis, 5 November 2026
final _thursday = DateTime(2026, 11, 5);

SubmissionSummary _sub(DateTime day, SubmissionStatus status, {bool reversed = false}) => SubmissionSummary(
  taskId: 't',
  status: status,
  forDate: day,
  createdAt: day.add(const Duration(hours: 8)),
  reversed: reversed,
);

DateTime _daysAgo(int n) => _thursday.subtract(Duration(days: n));

void main() {
  group('computeStreak (salinan _recompute_streak, aturan bisnis 8)', () {
    test('hari berturut-turut yang disetujui', () {
      final subs = [for (var i = 0; i < 4; i++) _sub(_daysAgo(i), SubmissionStatus.approved)];
      expect(computeStreak(subs, _thursday), 4);
    });

    test('hari ini belum ada laporan tidak memutus streak', () {
      final subs = [_sub(_daysAgo(1), SubmissionStatus.approved), _sub(_daysAgo(2), SubmissionStatus.approved)];
      expect(computeStreak(subs, _thursday), 2);
    });

    test('hari tertunda tidak memutus dan tidak menambah', () {
      final subs = [
        _sub(_daysAgo(0), SubmissionStatus.approved),
        _sub(_daysAgo(1), SubmissionStatus.pending),
        _sub(_daysAgo(2), SubmissionStatus.approved),
      ];
      expect(computeStreak(subs, _thursday), 2);
    });

    test('hari kosong, ditolak, atau dibatalkan memutus streak', () {
      expect(
        computeStreak([
          _sub(_daysAgo(0), SubmissionStatus.approved),
          _sub(_daysAgo(2), SubmissionStatus.approved),
        ], _thursday),
        1,
      );
      expect(
        computeStreak([
          _sub(_daysAgo(0), SubmissionStatus.approved),
          _sub(_daysAgo(1), SubmissionStatus.rejected),
        ], _thursday),
        1,
      );
      expect(computeStreak([_sub(_daysAgo(0), SubmissionStatus.approved, reversed: true)], _thursday), 0);
    });
  });

  test('weekActivity: Senin–Minggu minggu ini', () {
    final week = weekActivity([
      _sub(DateTime(2026, 11, 2), SubmissionStatus.approved), // Senin
      _sub(DateTime(2026, 11, 4), SubmissionStatus.needsRetake), // Rabu
      _sub(DateTime(2026, 10, 30), SubmissionStatus.approved), // minggu lalu
    ], _thursday);
    expect(week, [
      DayActivity.success,
      DayActivity.empty,
      DayActivity.pending,
      DayActivity.empty,
      DayActivity.empty,
      DayActivity.empty,
      DayActivity.empty,
    ]);
  });

  test('weekStats: tugas disetujui, poin masuk & keluar minggu ini', () {
    LedgerEntry entry(int amount, LedgerType type, DateTime at, {bool goal = false}) =>
        LedgerEntry(id: '$amount', amount: amount, type: type, createdAt: at, goalBucket: goal);
    final stats = weekStats([
      entry(50, LedgerType.task, DateTime(2026, 11, 5, 9)),
      entry(20, LedgerType.task, DateTime(2026, 11, 3, 9)),
      entry(10, LedgerType.bonus, DateTime(2026, 11, 3, 9)),
      entry(-100, LedgerType.redeemHold, DateTime(2026, 11, 4, 9)),
      entry(-50, LedgerType.goalSave, DateTime(2026, 11, 4, 9)),
      entry(50, LedgerType.goalSave, DateTime(2026, 11, 4, 9), goal: true),
      entry(300, LedgerType.task, DateTime(2026, 10, 30, 9)), // minggu lalu
    ], _thursday);
    expect(stats.tasksApproved, 2);
    expect(stats.pointsIn, 80);
    expect(stats.pointsOut, 150);
  });

  test('judul riwayat menampilkan alasan', () {
    LedgerEntry e(LedgerType type, String? reason) =>
        LedgerEntry(id: '1', amount: 1, type: type, reason: reason, createdAt: _thursday);
    expect(e(LedgerType.task, 'Rapikan kasur').title, 'Rapikan kasur');
    expect(e(LedgerType.penalty, 'Main melebihi waktu').title, 'Penalti: Main melebihi waktu');
    expect(e(LedgerType.reversal, 'Kasur belum rapi').title, 'Dibatalkan: Kasur belum rapi');
    expect(e(LedgerType.redeemRelease, null).title, 'Poin kembali');
  });

  test('LedgerEntry.fromRow', () {
    final entry = LedgerEntry.fromRow({
      'id': 42,
      'amount': -20,
      'type': 'reversal',
      'reason': 'x',
      'ref_id': 'sub-1',
      'bucket': 'available',
      'created_at': '2026-11-05T03:00:00Z',
    });
    expect(entry.id, '42');
    expect(entry.type, LedgerType.reversal);
    expect(entry.goalBucket, isFalse);
    expect(entry.createdAt.isUtc, isFalse);
  });
}
