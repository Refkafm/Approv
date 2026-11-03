import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

/// Baris list berbentuk pill putih di dalam kartu (design.md 7.4). Tinggi minimum 64.
class ListRowPill extends StatelessWidget {
  const ListRowPill({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap});

  final String title;
  final String? subtitle;

  /// Biasanya avatar/ikon bulat 44px.
  final Widget? leading;

  /// Default: chevron bila bisa ditekan.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.ink, width: AppStroke.width),
      ),
      child: Row(
        children: [
          if (leading != null) ...[SizedBox.square(dimension: 44, child: leading), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleMd),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(color: AppColors.inkMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.base),
          trailing ??
              (onTap != null
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(AppIcons.caretRight, size: 18, color: AppColors.ink),
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );

    if (onTap == null) return row;
    return Pressable(onTap: onTap, builder: (context, pressed) => row);
  }
}

/// Avatar/ikon bulat berlatar pastel dengan outline ink.
class CircleBadge extends StatelessWidget {
  const CircleBadge({super.key, required this.color, this.icon, this.initial});

  final Color color;
  final IconData? icon;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: AppStroke.width),
      ),
      alignment: Alignment.center,
      child: icon != null ? Icon(icon, size: 22, color: AppColors.ink) : Text(initial ?? '', style: AppText.titleMd),
    );
  }
}
