import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';

import '../format.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Ikon mata uang "Bintang": bintang kuning bergaris ink.
class PointStar extends StatelessWidget {
  const PointStar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Icon(AppIcons.starFill, size: size, color: AppColors.sunflower),
            Icon(AppIcons.star, size: size, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

/// Saldo poin (design.md 7.10): angka besar + keterangan tabungan goal, poin yang sedang
/// ditukar, atau utang poin bila saldo negatif.
class PointsBalance extends StatelessWidget {
  const PointsBalance({super.key, required this.available, this.goalSaved = 0, this.onHold = 0, this.debtReason});

  final int available;
  final int goalSaved;
  final int onHold;

  /// Alasan singkat utang poin (mis. "Tugas otomatis dibatalkan").
  final String? debtReason;

  bool get inDebt => available < 0;

  @override
  Widget build(BuildContext context) {
    final notes = <String>[
      if (inDebt) ...[
        ?debtReason,
        'Akan lunas otomatis dari poin berikutnya.',
      ] else ...[
        if (goalSaved > 0) '+ ${formatPoints(goalSaved)} di tabungan goal',
        if (onHold > 0) '${formatPoints(onHold)} sedang ditukar',
      ],
    ];

    // Angka saldo dibacakan sebagai satu node; keterangan di bawahnya dibacakan terpisah
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          label: inDebt ? 'Utang poin ${formatPoints(-available)}' : 'Saldo ${formatPoints(available)} poin',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inDebt) Text('Utang poin', style: AppText.titleMd.copyWith(color: AppColors.tangerineDeep)),
                Row(
                  children: [
                    const PointStar(),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatPoints(available),
                          style: AppText.numberHero.copyWith(color: inDebt ? AppColors.tangerineDeep : AppColors.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        for (final note in notes)
          Semantics(
            container: true,
            child: Text(note, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
          ),
      ],
    );
  }
}
