import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/selectable_card.dart';
import '../../l10n/strings.dart';
import '../shell/session.dart';

/// (kode, nama asli, nama dalam bahasa lain) — nama kedua membantu bila salah pilih bahasa.
const _languages = [('id', 'Bahasa Indonesia', 'Indonesian'), ('en', 'English', 'Inggris')];

/// Tombol bola dunia di pojok kanan atas layar sebelum login; diketuk = pop-up pilihan bahasa.
/// Setelah punya keluarga, bahasa diatur dari Pengaturan keluarga.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = SessionScope.of(context).language;
    final name = _languages.firstWhere((l) => l.$1 == current).$2;
    return IconCircleButton(
      icon: AppIcons.globe,
      semanticLabel: '${context.s.changeLanguage}: $name',
      onPressed: () => showLanguagePicker(context),
    );
  }
}

Future<void> showLanguagePicker(BuildContext context) {
  final session = SessionScope.read(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.globe, size: 24, color: AppColors.ink),
                const SizedBox(width: 10),
                Text(dialogContext.s.chooseLanguage, style: AppText.titleLg),
              ],
            ),
            const SizedBox(height: 16),
            for (final (code, name, other) in _languages) ...[
              SelectableCard(
                title: name,
                subtitle: other,
                selected: session.language == code,
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  await session.setLanguage(code);
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}
