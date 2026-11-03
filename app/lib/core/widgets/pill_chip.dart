import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

/// Chip pilihan (design.md 7.6): terpilih = isian sunflower + outline ink + bayangan kecil;
/// tidak terpilih = putih dengan outline lembut.
class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: TapTarget.parent),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.sunflower : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: selected
              ? Border.all(color: AppColors.ink, width: AppStroke.width)
              : Border.all(color: AppColors.lineSoft, width: AppStroke.softWidth),
          boxShadow: selected && !pressed ? HardShadow.sm : null,
        ),
        child: Text(label, style: AppText.label.copyWith(color: selected ? AppColors.ink : AppColors.inkMuted)),
      ),
    );
  }
}

/// Deretan chip yang bisa digulir ke samping (untuk filter di bagian atas daftar).
class ChipScroller extends StatelessWidget {
  const ChipScroller({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [for (final child in children) Padding(padding: const EdgeInsets.only(right: 8), child: child)],
      ),
    );
  }
}
