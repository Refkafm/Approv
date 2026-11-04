import 'package:flutter/widgets.dart';

import '../../l10n/strings.dart';
import '../format.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

/// Progress goal (design.md 7.5): pill bergaris tebal yang terisi dari kiri, penanda 25/50/75%,
/// dan bendera finish di kanan. Isian bertambah dengan animasi saat muncul.
class GoalProgressBar extends StatelessWidget {
  const GoalProgressBar({super.key, required this.saved, required this.target, required this.goalTitle});

  final int saved;
  final int target;
  final String goalTitle;

  static const _height = 32.0;

  /// Persen dibulatkan ke bawah, jadi 100% hanya saat poin benar-benar cukup.
  static int percent(int saved, int target) {
    if (target <= 0 || saved <= 0) return 0;
    return (saved * 100 ~/ target).clamp(0, 100);
  }

  static double fraction(int saved, int target) {
    if (target <= 0 || saved <= 0) return 0;
    return (saved / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final reached = target > 0 && saved >= target;
    return Semantics(
      container: true,
      label: context.s.goalProgressSemantic(
        goalTitle,
        formatPoints(saved.clamp(0, target)),
        formatPoints(target),
        percent(saved, target),
      ),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction(saved, target)),
          duration: AppMotion.reduce(context) ? Duration.zero : AppMotion.countUp,
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => Container(
            width: double.infinity,
            height: _height,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.ink, width: AppStroke.width),
              boxShadow: HardShadow.sm,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Penanda 25 / 50 / 75%
                  for (final mark in const [0.25, 0.5, 0.75])
                    Align(
                      alignment: Alignment(mark * 2 - 1, 0),
                      child: Container(width: 2, height: _height / 2, color: AppColors.lineSoft),
                    ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: reached ? AppColors.matcha : AppColors.tangerine,
                        border: t > 0 && t < 1 ? const Border(right: BorderSide(width: AppStroke.width)) : null,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(AppIcons.flag, size: 16, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
