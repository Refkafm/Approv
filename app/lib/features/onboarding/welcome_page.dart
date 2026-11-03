import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_button.dart';
import '../shell/session.dart';
import 'onboarding_scaffold.dart';

/// Layar awal (PRD Flow 1 & 2): orang tua masuk dengan akun, anak masuk dengan kode.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return OnboardingScaffold(
      title: 'Siapa yang pakai HP ini?',
      subtitle: 'Orang tua mengatur tugas dan hadiah. Anak mengumpulkan poin.',
      children: [
        AppButton(label: 'Saya orang tua', onPressed: () => context.go('/login')),
        const SizedBox(height: 16),
        AppButton(label: 'Saya anak', variant: AppButtonVariant.secondary, onPressed: () => context.go('/join')),
        if (session.isDemo)
          const DemoNote('Mode demo: belum tersambung ke server, data hanya tersimpan selama app terbuka.'),
        if (kDebugMode) ...[
          const SizedBox(height: 24),
          AppButton(
            label: 'Lihat komponen desain',
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push('/dev/components'),
          ),
        ],
      ],
    );
  }
}
