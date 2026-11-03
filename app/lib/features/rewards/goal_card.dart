import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/dot_progress.dart';
import '../../core/widgets/feature_card.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/status_stamp.dart';
import '../../data/reward_models.dart';

/// Kartu "Goal saya" (PRD G-01, G-02, G-04, design.md 7.5): progress 20 titik, persen, estimasi hari,
/// dan stempel TERCAPAI! saat poin cukup.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.onAction, this.actionLabel = 'Buka toko hadiah'});

  /// null = belum memilih goal.
  final GoalProgress? goal;
  final VoidCallback? onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final action = onAction == null
        ? null
        : IconCircleButton(icon: AppIcons.arrowUpRight, semanticLabel: actionLabel, onPressed: onAction);
    if (g == null) {
      return FeatureCard(
        tone: FeatureCardTone.sunflower,
        title: 'Goal saya',
        description: 'Belum ada goal. Pilih hadiah besar yang mau kamu tabung.',
        action: action,
      );
    }
    final cost = g.reward.cost;
    final progress = g.progress.clamp(0, cost);
    return FeatureCard(
      tone: FeatureCardTone.sunflower,
      title: 'Goal saya',
      description: g.reward.title,
      action: action,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          DotProgress(saved: g.progress, target: cost, goalTitle: g.reward.title),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (g.reached)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: StatusStamp(status: StampStatus.reached, animate: true),
                  ),
                ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${DotProgress.percent(g.progress, cost)}%', style: AppText.numberHero),
                  ),
                ),
                ExcludeSemantics(
                  child: Text('${formatPoints(progress)} / ${formatPoints(cost)}', style: AppText.titleMd),
                ),
                Text(
                  g.reached
                      ? 'Poinmu cukup! Tukar sekarang.'
                      : (g.daysLeft == null ? 'Kumpulkan poin dulu ya.' : '±${g.daysLeft} hari lagi'),
                  style: AppText.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
