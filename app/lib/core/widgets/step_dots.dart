import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Indikator langkah (design.md 7.11): titik 8px bergaris ink; langkah aktif = pill 24×8.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Langkah ${index + 1} dari $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: i == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: i == index ? AppColors.ink : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
