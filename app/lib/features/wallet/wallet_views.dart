import 'package:flutter/widgets.dart';

import '../../core/widgets/points_balance.dart';
import '../../core/widgets/streak_row.dart';
import '../../data/task_rules.dart';
import '../../data/wallet_models.dart';

/// Status 7 hari (Senin–Minggu) untuk [StreakRow]: hari mendatang kosong, hari ini tanpa laporan = "hari ini".
List<StreakDay> streakDaysOf(WalletSummary summary) {
  final monday = weekStart(summary.today);
  return [
    for (var i = 0; i < 7; i++)
      switch (summary.week[i]) {
        DayActivity.success => StreakDay.success,
        DayActivity.pending => StreakDay.pending,
        DayActivity.empty => monday.add(Duration(days: i)) == summary.today ? StreakDay.today : StreakDay.empty,
      },
  ];
}

/// Saldo dari ledger (P-01); null = sedang dimuat.
class BalanceView extends StatelessWidget {
  const BalanceView(this.summary, {super.key});

  final WalletSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) return const SizedBox(height: 64);
    return PointsBalance(
      available: s.balance.available,
      goalSaved: s.balance.goalSaved,
      onHold: s.balance.onHold,
      debtReason: s.debtReason,
    );
  }
}

/// Streak & 7 hari minggu ini (X-01).
class StreakView extends StatelessWidget {
  const StreakView(this.summary, {super.key});

  final WalletSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) return const SizedBox(height: 80);
    return StreakRow(days: streakDaysOf(s), count: s.streak);
  }
}
