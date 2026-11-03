import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class AppNavItem {
  const AppNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Bottom navigation (design.md 7.12): latar putih, garis atas ink 2px,
/// tab aktif = ikon di dalam pill sunflower bergaris ink.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.tapTarget = TapTarget.parent,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double tapTarget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.ink, width: AppStroke.width),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    tapTarget: tapTarget,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.tapTarget, required this.onTap});

  final AppNavItem item;
  final bool selected;
  final double tapTarget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tapTarget),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: selected
                      ? BoxDecoration(
                          color: AppColors.sunflower,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.ink, width: AppStroke.width),
                        )
                      : const BoxDecoration(
                          border: Border.fromBorderSide(BorderSide(color: Color(0x00000000), width: AppStroke.width)),
                        ),
                  child: Icon(item.icon, size: 22, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(color: selected ? AppColors.ink : AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
