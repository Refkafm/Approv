import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/feature_card.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/member_avatar.dart';
import '../../core/widgets/goal_progress_bar.dart';
import '../../data/models.dart';
import '../../data/reward_models.dart';
import '../../data/wallet_models.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

/// Beranda orang tua (PRD O-3, design.md 8): ringkasan per anak → persetujuan menunggu → keluarga.
class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
        children: staggered([
          Row(
            children: [
              Expanded(
                child: Text(
                  context.s.helloName(SessionScope.of(context).activeMember?.name ?? ''),
                  style: AppText.displayLg,
                ),
              ),
              IconCircleButton(
                icon: AppIcons.gear,
                semanticLabel: context.s.familySettingsLabel,
                onPressed: () => context.go('/parent/family'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ChildrenOverview(),
          const SizedBox(height: 14),
          const _PendingCard(),
          const SizedBox(height: AppSpace.cardGap),
          FeatureCard(
            tone: FeatureCardTone.grape,
            title: context.s.navFamily,
            description: context.s.familyCardDesc,
            action: IconCircleButton(
              icon: AppIcons.arrowUpRight,
              semanticLabel: context.s.openFamily,
              onPressed: () => context.go('/parent/family'),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Jumlah laporan yang menunggu persetujuan; ikut berubah saat anak melapor (realtime).
class _PendingCard extends StatefulWidget {
  const _PendingCard();

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> with ReloadOnChanges {
  Future<(int, int)>? _pending;

  Future<(int, int)> _load() async {
    final session = SessionScope.read(context);
    final familyId = session.activeMember!.familyId;
    final reports = await session.repository.pendingReviews(familyId);
    final redemptions = await session.repository.openRedemptions(familyId);
    return (reports.length, redemptions.where((r) => r.status == RedemptionStatus.requested).length);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pending ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _pending = _load();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(int, int)>(
      future: _pending,
      builder: (context, snapshot) {
        final (reports, redemptions) = snapshot.data ?? (0, 0);
        final count = reports + redemptions;
        return FeatureCard(
          tone: FeatureCardTone.sunflower,
          title: context.s.pendingApprovalsTitle,
          description: count == 0
              ? context.s.nothingWaiting
              : [
                  if (reports > 0) context.s.taskReportsCount(reports),
                  if (redemptions > 0) context.s.redemptionsCount(redemptions),
                ].join(' · '),
          action: IconCircleButton(
            icon: AppIcons.arrowUpRight,
            semanticLabel: context.s.openApprovalQueue,
            onPressed: () => context.go('/parent/approvals'),
          ),
          child: Text('$count', style: AppText.numberHero),
        );
      },
    );
  }
}

/// Kartu per anak (PRD M-04): saldo & streak; ketuk untuk detail anak (O-10).
class _ChildrenOverview extends StatefulWidget {
  const _ChildrenOverview();

  @override
  State<_ChildrenOverview> createState() => _ChildrenOverviewState();
}

class _ChildrenOverviewState extends State<_ChildrenOverview> with ReloadOnChanges {
  Future<List<(Member, WalletSummary, GoalProgress?)>>? _children;

  Future<List<(Member, WalletSummary, GoalProgress?)>> _load() async {
    final session = SessionScope.read(context);
    final members = await session.repository.familyMembers(session.activeMember!.familyId);
    return [
      for (final m in members.where((m) => m.role == MemberRole.member))
        (m, await session.repository.wallet(m), await session.repository.activeGoal(m)),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _children ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _children = _load();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(Member, WalletSummary, GoalProgress?)>>(
      future: _children,
      builder: (context, snapshot) {
        final children = snapshot.data ?? const <(Member, WalletSummary, GoalProgress?)>[];
        if (snapshot.connectionState == ConnectionState.done && children.isEmpty) {
          return Text(context.s.noChildrenYet, style: AppText.body.copyWith(color: AppColors.inkMuted));
        }
        return Column(
          children: [
            for (final (child, wallet, goal) in children) ...[
              ListRowPill(
                title: child.name,
                subtitle: [
                  context.s.pointsAmount(formatPoints(wallet.balance.available)),
                  if (wallet.streak > 0) context.s.streakDays(wallet.streak),
                  if (goal != null) context.s.goalPercent(GoalProgressBar.percent(goal.progress, goal.reward.cost)),
                  if (!child.isConnected) context.s.notConnected,
                ].join(' · '),
                leading: MemberAvatar(name: child.name, avatarKey: child.avatar),
                onTap: () => context.push('/parent/home/child', extra: child),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}
