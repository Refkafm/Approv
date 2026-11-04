import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/member_avatar.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/app_exception.dart';
import '../../data/reward_models.dart';
import '../../data/submission_repository.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import 'redemption_sheet.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

/// Antrean persetujuan (PRD layar O-4, L-03): laporan tugas yang menunggu, terlama di atas.
/// Tab penukaran hadiah diisi di minggu 7; setujui banyak sekaligus (L-05, P1) menyusul.
class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> with ReloadOnChanges {
  Future<List<ReviewItem>>? _items;
  Future<List<Redemption>>? _redemptions;
  bool _rewardsTab = false;

  Future<List<Redemption>> _loadRedemptions() {
    final session = SessionScope.read(context);
    return session.repository.openRedemptions(session.activeMember!.familyId);
  }

  Future<List<ReviewItem>> _load() {
    final session = SessionScope.read(context);
    return session.repository.pendingReviews(session.activeMember!.familyId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= _load();
    _redemptions ??= _loadRedemptions();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _items = _load();
    _redemptions = _loadRedemptions();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<ReviewItem>>(
        future: _items,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <ReviewItem>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
            children: staggered([
              Text(context.s.navApprovals, style: AppText.displayLg),
              const SizedBox(height: 16),
              ChipScroller(
                children: [
                  PillChip(
                    label: items.isEmpty ? context.s.taskReports : context.s.taskReportsWithCount(items.length),
                    selected: !_rewardsTab,
                    onTap: () => setState(() => _rewardsTab = false),
                  ),
                  PillChip(
                    label: context.s.rewardRedemptions,
                    selected: _rewardsTab,
                    onTap: () => setState(() => _rewardsTab = true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_rewardsTab)
                _RedemptionQueue(_redemptions)
              else if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : context.s.loadReportsFailed,
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                )
              else if (snapshot.connectionState == ConnectionState.done && items.isEmpty)
                Text(context.s.noPendingReports, style: AppText.body.copyWith(color: AppColors.inkMuted))
              else
                for (final item in items) ...[
                  ListRowPill(
                    title: item.taskTitle,
                    subtitle: [
                      item.memberName,
                      formatReportTime(item.createdAt),
                      if (item.isFlagged) context.s.waitingOver3Days,
                    ].join(' · '),
                    leading: MemberAvatar(name: item.memberName, avatarKey: item.memberAvatar),
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text('+${formatPoints(item.points)}', style: AppText.titleMd),
                    ),
                    onTap: () => context.push('/parent/approvals/review', extra: item),
                  ),
                  const SizedBox(height: 10),
                ],
            ]),
          );
        },
      ),
    );
  }
}

/// Penukaran yang diajukan, dan yang disetujui tapi belum diberikan (H-04, H-05).
class _RedemptionQueue extends StatelessWidget {
  const _RedemptionQueue(this.redemptions);

  final Future<List<Redemption>>? redemptions;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Redemption>>(
      future: redemptions,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <Redemption>[];
        if (snapshot.connectionState == ConnectionState.done && list.isEmpty) {
          return Text(context.s.noPendingRedemptions, style: AppText.body.copyWith(color: AppColors.inkMuted));
        }
        return Column(
          children: [
            for (final r in list) ...[
              ListRowPill(
                title: r.rewardTitle,
                subtitle: [
                  r.memberName,
                  r.status == RedemptionStatus.requested
                      ? context.s.redemptionRequested
                      : context.s.redemptionApprovedNotGiven,
                  formatReportTime(r.createdAt),
                ].join(' · '),
                leading: MemberAvatar(name: r.memberName, avatarKey: r.memberAvatar),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(formatPoints(r.cost), style: AppText.titleMd),
                ),
                onTap: () => showRedemptionSheet(context, r),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}
