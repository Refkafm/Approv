import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_button.dart';
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
      showLanguage: true,
      children: [
        AppButton(label: context.s.welcomeParent, onPressed: () => context.go('/login')),
        const SizedBox(height: 16),
        AppButton(
          label: context.s.welcomeChild,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.go('/join'),
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
