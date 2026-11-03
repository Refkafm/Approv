import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

/// Kartu pilihan (design.md 7.7): terpilih = outline ink + bayangan besar + centang;
/// tidak terpilih = outline lembut, teks ink-muted.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  /// Teks badge pill bubblegum di kanan, mis. "Disarankan".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? AppColors.ink : AppColors.inkMuted;
    return Pressable(
      onTap: onTap,
      selected: selected,
      builder: (context, pressed) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.select),
          border: selected
              ? Border.all(color: AppColors.ink, width: AppStroke.width)
              : Border.all(color: AppColors.lineSoft, width: AppStroke.softWidth),
          boxShadow: selected && !pressed ? HardShadow.lg : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.titleMd.copyWith(color: textColor)),
                  if (subtitle != null) Text(subtitle!, style: AppText.body.copyWith(color: textColor)),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bubblegum,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(badge!, style: AppText.label),
              ),
            ],
            const SizedBox(width: 8),
            Icon(selected ? AppIcons.checkCircle : AppIcons.circle, size: 24, color: textColor),
          ],
        ),
      ),
    );
  }
}
