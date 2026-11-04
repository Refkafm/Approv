import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/goal_progress_bar.dart';
import '../../core/widgets/feature_card.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/status_stamp.dart';
import '../../data/reward_models.dart';
import '../../l10n/strings.dart';

/// Kartu "Goal saya" (PRD G-01, G-02, G-04, design.md 7.5): progress 20 titik, persen, estimasi hari,
/// dan stempel TERCAPAI! saat poin cukup.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.onAction, this.actionLabel});

  /// null = belum memilih goal.
  final GoalProgress? goal;
  final VoidCallback? onAction;

  /// Default: "Buka toko hadiah".
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final action = onAction == null
        ? null
        : IconCircleButton(
            icon: AppIcons.arrowUpRight,
            semanticLabel: actionLabel ?? context.s.openRewardShop,
            onPressed: onAction,
          );
    if (g == null) {
      return FeatureCard(
        tone: FeatureCardTone.sunflower,
        title: context.s.myGoal,
        description: context.s.noGoalYet,
        action: action,
      );
    }
    final cost = g.reward.cost;
    final progress = g.progress.clamp(0, cost);
    return FeatureCard(
      tone: FeatureCardTone.sunflower,
      title: context.s.myGoal,
      description: g.reward.title,
      action: action,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (g.reached)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: StatusStamp(status: StampStatus.reached, animate: true),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ExcludeSemantics(child: Text('${GoalProgressBar.percent(g.progress, cost)}%', style: AppText.numberHero)),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ExcludeSemantics(
                    child: Text(
                      '${formatPoints(progress)} / ${formatPoints(cost)}',
                      textAlign: TextAlign.end,
                      style: AppText.titleMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GoalProgressBar(saved: g.progress, target: cost, goalTitle: g.reward.title),
        ],
      ),
    );
  }
}
