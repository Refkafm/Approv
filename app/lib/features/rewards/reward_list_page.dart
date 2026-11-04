import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/app_exception.dart';
import '../../data/reward_models.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/strings.dart';

/// Daftar hadiah orang tua (PRD layar O-8): kelompok Instan & Goal, aktif/arsip.
class RewardListPage extends StatefulWidget {
  const RewardListPage({super.key});

  @override
  State<RewardListPage> createState() => _RewardListPageState();
}

class _RewardListPageState extends State<RewardListPage> with ReloadOnChanges {
  bool _archived = false;
  Future<List<Reward>>? _rewards;

  Future<List<Reward>> _load() {
    final session = SessionScope.read(context);
    return session.repository.listRewards(session.activeMember!.familyId, archived: _archived);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewards ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _rewards = _load();
  });

  void _open([Reward? reward]) =>
      context.push(reward == null ? '/parent/rewards/new' : '/parent/rewards/edit', extra: reward);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Reward>>(
        future: _rewards,
        builder: (context, snapshot) {
          final rewards = snapshot.data ?? const <Reward>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
            children: staggered([
              Row(
                children: [
                  Expanded(child: Text(context.s.rewards, style: AppText.displayLg)),
                  IconCircleButton(icon: AppIcons.plus, semanticLabel: context.s.newReward, onPressed: _open),
                ],
              ),
              const SizedBox(height: 16),
              ChipScroller(
                children: [
                  PillChip(
                    label: context.s.activeFilter,
                    selected: !_archived,
                    onTap: () {
                      _archived = false;
                      reload();
                    },
                  ),
                  PillChip(
                    label: context.s.archivedFilter,
                    selected: _archived,
                    onTap: () {
                      _archived = true;
                      reload();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                Text(
                  snapshot.error is AppException
                      ? (snapshot.error! as AppException).message
                      : context.s.loadRewardsFailed,
                  style: AppText.body.copyWith(color: AppColors.tangerineDeep),
                )
              else if (snapshot.connectionState == ConnectionState.done && rewards.isEmpty)
                Text(
                  _archived ? context.s.noArchivedRewards : context.s.noRewardsYet,
                  style: AppText.body.copyWith(color: AppColors.inkMuted),
                ),
              for (final type in RewardType.values)
                if (rewards.any((r) => r.type == type)) ...[
                  Text(type == RewardType.instant ? context.s.rewardInstant : context.s.goal, style: AppText.titleLg),
                  const SizedBox(height: 10),
                  for (final r in rewards.where((r) => r.type == type)) ...[
                    ListRowPill(
                      title: r.title,
                      subtitle: [
                        r.rulesLabel,
                        if (r.pendingCost != null && r.costEffectiveAt != null)
                          context.s.risesTo(formatPoints(r.pendingCost!), formatDateShort(r.costEffectiveAt!)),
                      ].join(' · '),
                      leading: CircleBadge(color: AppColors.pastelLilac, icon: AppIcons.reward(r.icon)),
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(formatPoints(r.cost), style: AppText.titleMd),
                      ),
                      onTap: () => _open(r),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                ],
            ]),
          );
        },
      ),
    );
  }
}
