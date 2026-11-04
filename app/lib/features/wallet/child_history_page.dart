import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../data/app_exception.dart';
import '../../data/reward_models.dart';
import '../../data/wallet_models.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import 'ledger_list.dart';
import 'wallet_views.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

/// Riwayat anak (PRD layar A-9, P-02): saldo, status penukaran hadiah, dan transaksi poin.
class ChildHistoryPage extends StatefulWidget {
  const ChildHistoryPage({super.key});

  @override
  State<ChildHistoryPage> createState() => _ChildHistoryPageState();
}

class _ChildHistoryPageState extends State<ChildHistoryPage> with ReloadOnChanges {
  Future<(WalletSummary, List<LedgerEntry>, List<Redemption>)>? _data;

  Future<(WalletSummary, List<LedgerEntry>, List<Redemption>)> _load() async {
    final session = SessionScope.read(context);
    final me = session.activeMember!;
    final repo = session.repository;
    return (await repo.wallet(me), await repo.history(me.id), await repo.memberRedemptions(me.id));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _data = _load();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<(WalletSummary, List<LedgerEntry>, List<Redemption>)>(
        future: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
            children: staggered([
              Text(context.s.navHistory, style: AppText.displayLg),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : context.s.loadHistoryFailed,
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                ),
              BalanceView(data?.$1),
              const SizedBox(height: 28),
              if (data != null && data.$3.isNotEmpty) ...[
                Text(context.s.rewardRedemptions, style: AppText.titleLg),
                const SizedBox(height: 10),
                for (final r in data.$3.take(10)) ...[
                  ListRowPill(
                    title: r.rewardTitle,
                    subtitle: [
                      formatReportTime(r.createdAt),
                      switch (r.status) {
                        RedemptionStatus.requested => context.s.statusWaitingParent,
                        RedemptionStatus.approved => context.s.statusApproved,
                        RedemptionStatus.fulfilled => context.s.statusGiven,
                        RedemptionStatus.rejected => context.s.statusRejected(r.rejectReason ?? '-'),
                        RedemptionStatus.cancelled => context.s.statusCancelled,
                      },
                    ].join(' · '),
                    leading: CircleBadge(color: AppColors.pastelLilac, icon: AppIcons.reward(r.rewardIcon)),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                Text(context.s.pointTransactions, style: AppText.titleLg),
                const SizedBox(height: 10),
              ],
              if (data != null) LedgerList(entries: data.$2),
            ]),
          );
        },
      ),
    );
  }
}
