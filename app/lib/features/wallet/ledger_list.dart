import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../data/task_rules.dart';
import '../../data/wallet_models.dart';

/// Riwayat transaksi poin dikelompokkan per hari (P-02, layar A-9 & O-10).
/// Baris di [reversible] (tugas otomatis ≤ 24 jam) bisa diketuk untuk dibatalkan.
class LedgerList extends StatelessWidget {
  const LedgerList({super.key, required this.entries, this.reversible = const {}, this.onReverse});

  final List<LedgerEntry> entries;

  /// Id laporan (ref_id) yang masih bisa dibatalkan.
  final Set<String> reversible;
  final ValueChanged<LedgerEntry>? onReverse;

  static String _dayLabel(DateTime day, DateTime today) {
    final diff = dateOnly(today).difference(day).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return formatDateShort(day);
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text('Belum ada transaksi poin.', style: AppText.body.copyWith(color: AppColors.inkMuted));
    }
    final today = DateTime.now();
    final children = <Widget>[];
    DateTime? currentDay;
    for (final e in entries) {
      final day = dateOnly(e.createdAt);
      if (day != currentDay) {
        currentDay = day;
        children.add(
          Padding(
            padding: EdgeInsets.only(top: children.isEmpty ? 0 : 16, bottom: 8),
            child: Text(_dayLabel(day, today), style: AppText.label.copyWith(color: AppColors.inkMuted)),
          ),
        );
      }
      final canReverse = e.type == LedgerType.task && e.refId != null && reversible.contains(e.refId);
      final time = '${e.createdAt.hour.toString().padLeft(2, '0')}.${e.createdAt.minute.toString().padLeft(2, '0')}';
      children
        ..add(
          ListRowPill(
            title: e.title,
            subtitle: [time, if (e.goalBucket) 'tabungan goal', if (canReverse) 'ketuk untuk membatalkan'].join(' · '),
            leading: CircleBadge(
              color: e.amount >= 0 ? AppColors.pastelLime : AppColors.pastelPeach,
              icon: switch (e.type) {
                LedgerType.task => AppIcons.checkSquare,
                LedgerType.bonus || LedgerType.streak => AppIcons.star,
                LedgerType.redeemHold || LedgerType.redeemRelease => AppIcons.gift,
                LedgerType.goalSave || LedgerType.goalUnsave => AppIcons.flag,
                LedgerType.penalty || LedgerType.reversal => AppIcons.minus,
              },
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                '${e.amount > 0 ? '+' : ''}${formatPoints(e.amount)}',
                style: AppText.titleMd.copyWith(color: e.amount >= 0 ? AppColors.matchaDeep : AppColors.tangerineDeep),
              ),
            ),
            onTap: canReverse && onReverse != null ? () => onReverse!(e) : null,
          ),
        )
        ..add(const SizedBox(height: 10));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
