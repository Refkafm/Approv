import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'pressable.dart';

/// Lingkaran putih 40px dengan outline ink (design.md 7.1). Area tap tetap ≥ [tapTarget].
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tapTarget = TapTarget.parent,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double tapTarget;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => SizedBox.square(
        dimension: tapTarget,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: AppStroke.width),
              boxShadow: pressed ? null : HardShadow.sm,
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
