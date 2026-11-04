import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/pill_chip.dart';
import '../shell/session.dart';
import 'onboarding_scaffold.dart';
import '../../l10n/strings.dart';

/// Layar awal (PRD Flow 1 & 2): orang tua masuk dengan akun, anak masuk dengan kode.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return OnboardingScaffold(
      title: context.s.welcomeTitle,
      subtitle: context.s.welcomeSubtitle,
      children: [
        AppButton(label: context.s.welcomeParent, onPressed: () => context.go('/login')),
        const SizedBox(height: 16),
        AppButton(
          label: context.s.welcomeChild,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.go('/join'),
        ),
        const SizedBox(height: 32),
        // Bahasa sebelum login; setelah punya keluarga, mengikuti pengaturan keluarga
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final (code, label) in const [('id', 'Bahasa Indonesia'), ('en', 'English')])
              PillChip(label: label, selected: session.language == code, onTap: () => session.setLanguage(code)),
          ],
        ),
        if (session.isDemo) DemoNote(context.s.demoModeNote),
        if (kDebugMode) ...[
          const SizedBox(height: 24),
          AppButton(
            label: context.s.devComponents,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push('/dev/components'),
          ),
        ],
      ],
    );
  }
}
