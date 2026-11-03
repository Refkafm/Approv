import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/paper_background.dart';
import '../../core/widgets/step_dots.dart';

/// Kerangka layar onboarding: tombol kembali opsional, indikator langkah, judul display, isi.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.step,
    this.stepCount,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final int? step;
  final int? stepCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 12, AppSpace.screenX, 32),
            children: [
              SizedBox(
                height: TapTarget.parent,
                child: Row(
                  children: [
                    if (onBack != null)
                      IconCircleButton(icon: AppIcons.arrowLeft, semanticLabel: 'Kembali', onPressed: onBack),
                    const Spacer(),
                    if (step != null && stepCount != null) StepDots(count: stepCount!, index: step!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppText.displayXl),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(subtitle!, style: AppText.body.copyWith(color: AppColors.inkMuted)),
              ],
              const SizedBox(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Pesan error di bawah tombol.
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        liveRegion: true,
        child: Text(message!, style: AppText.body.copyWith(color: AppColors.tangerineDeep)),
      ),
    );
  }
}

/// Catatan kecil mode demo.
class DemoNote extends StatelessWidget {
  const DemoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(text, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
    );
  }
}
