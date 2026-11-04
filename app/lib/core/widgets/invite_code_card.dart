import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../../l10n/strings.dart';

/// Kode undangan besar untuk diketik di HP anak/pengasuh (PRD A-04, M-02).
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.code, required this.forName});

  final String code;
  final String forName;

  /// "K7M2QX" -> "K7M 2QX" agar mudah dibaca.
  static String grouped(String code) => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.photo),
        border: Border.all(color: AppColors.ink, width: AppStroke.width),
        boxShadow: HardShadow.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.s.codeFor(forName), style: AppText.titleMd),
          const SizedBox(height: 8),
          Semantics(
            label: context.s.codeSemantic(code.split('').join(' ')),
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(grouped(code), style: AppText.numberHero.copyWith(letterSpacing: 4)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(context.s.codeValidity, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
