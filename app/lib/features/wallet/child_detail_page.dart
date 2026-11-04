import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/app_exception.dart';
import '../../data/models.dart';
import '../../data/wallet_models.dart';
import '../../data/wallet_rules.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import 'adjust_sheet.dart';
import 'ledger_list.dart';
import 'wallet_views.dart';
import '../../l10n/strings.dart';

typedef _ChildData = ({WalletSummary wallet, List<LedgerEntry> history, Set<String> reversible});

/// Detail anak (PRD layar O-10, Flow 6): saldo, streak, statistik minggu ini, bonus/penalti,
/// riwayat poin, dan pembatalan tugas otomatis. Goal & galeri bukti menyusul (minggu 7, PF-08).
class ChildDetailPage extends StatefulWidget {
  const ChildDetailPage({super.key, required this.member});

  /// null bila data hilang (mis. app dipulihkan setelah ditutup sistem).
  final Member? member;

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage> with ReloadOnChanges {
  Future<_ChildData>? _data;

  Future<_ChildData> _load() async {
    final repo = SessionScope.read(context).repository;
    final member = widget.member!;
    final wallet = await repo.wallet(member);
    final history = await repo.history(member.id);
    final reversible = await repo.reversibleSubmissions(member.id);
    return (wallet: wallet, history: history, reversible: reversible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.member == null) return;
    _data ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _data = _load();
  });

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    if (member == null) {
      return OnboardingScaffold(title: context.s.childNotFound, onBack: () => context.pop(), children: const []);
    }

    return FutureBuilder<_ChildData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final stats = data == null ? null : weekStats(data.history, data.wallet.today);
        return OnboardingScaffold(
          title: member.name,
          onBack: () => context.pop(),
          children: [
            if (snapshot.hasError)
              Text(
                snapshot.error is AppException ? (snapshot.error! as AppException).message : context.s.loadDataFailed,
                style: AppText.body.copyWith(color: AppColors.tangerineDeep),
              ),
            BalanceView(data?.wallet),
            const SizedBox(height: 24),
            StreakView(data?.wallet),
            const SizedBox(height: 24),
            Text(context.s.thisWeek, style: AppText.titleLg),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatTile(label: context.s.tasksApproved, value: stats == null ? '–' : '${stats.tasksApproved}'),
                const SizedBox(width: 10),
                _StatTile(label: context.s.pointsIn, value: stats == null ? '–' : '+${formatPoints(stats.pointsIn)}'),
                const SizedBox(width: 10),
                _StatTile(label: context.s.pointsOut, value: stats == null ? '–' : '−${formatPoints(stats.pointsOut)}'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.s.bonus,
                    icon: AppIcons.plus,
                    onPressed: data == null
                        ? null
                        : () => showAdjustSheet(
                            context,
                            member: member,
                            penalty: false,
                            available: data.wallet.balance.available,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: context.s.penalty,
                    icon: AppIcons.minus,
                    variant: AppButtonVariant.secondary,
                    onPressed: data == null
                        ? null
                        : () => showAdjustSheet(
                            context,
                            member: member,
                            penalty: true,
                            available: data.wallet.balance.available,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(context.s.pointsHistory, style: AppText.titleLg),
            const SizedBox(height: 10),
            if (data != null)
              LedgerList(
                entries: data.history,
                reversible: data.reversible,
                onReverse: (e) =>
                    showReverseSheet(context, submissionId: e.refId!, taskTitle: e.reason ?? context.s.taskFallback),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.ink, width: AppStroke.width),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppText.titleLg),
            ),
            Text(label, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}
