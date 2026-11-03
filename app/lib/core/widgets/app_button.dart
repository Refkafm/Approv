import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, secondary, destructive }

/// Tombol pill (design.md 7.1). Semua varian punya outline ink 2px + bayangan keras.
/// Tinggi di sini adalah minimum; tombol ikut memanjang saat teks diperbesar.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fill = !enabled
        ? AppColors.paperGrid
        : variant == AppButtonVariant.primary
        ? AppColors.sunflower
        : AppColors.surface;
    final textColor = !enabled
        ? AppColors.inkFaint
        : variant == AppButtonVariant.destructive
        ? AppColors.tangerineDeep
        : AppColors.ink;
    final leadingIcon = icon ?? (variant == AppButtonVariant.destructive ? AppIcons.x : null);

    return Pressable(
      onTap: onPressed,
      builder: (context, pressed) => Container(
        constraints: BoxConstraints(minHeight: variant == AppButtonVariant.primary ? 56 : 52),
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: enabled ? AppColors.ink : AppColors.lineSoft, width: AppStroke.width),
          boxShadow: enabled && !pressed ? HardShadow.sm : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 20, color: textColor),
              const SizedBox(width: AppSpace.base),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.button.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
