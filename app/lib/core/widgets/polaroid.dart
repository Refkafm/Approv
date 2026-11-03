import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

/// Kartu foto bukti gaya polaroid (design.md 7.8): putih, outline ink, bayangan keras,
/// diputar −5°…+5° (tetap untuk [seed] yang sama). Saat dibuka layar penuh, foto selalu tegak.
class Polaroid extends StatelessWidget {
  const Polaroid({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.caption,
    this.label,
    this.seed = 0,
    this.width = 140,
    this.onTap,
  });

  /// null = sedang dimuat.
  final ImageProvider? image;
  final String semanticLabel;

  /// Teks kecil di bawah foto, mis. waktu pengambilan.
  final String? caption;

  /// Label di pojok, mis. "Sebelum" / "Sesudah".
  final String? label;
  final int seed;
  final double width;
  final VoidCallback? onTap;

  double get _angle => ((seed * 7 + 3) % 11 - 5) * tiltMaxDeg / 5 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.photo),
        border: Border.all(color: AppColors.ink, width: AppStroke.width),
        boxShadow: HardShadow.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.photo - 8),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: image == null
                      ? const ColoredBox(color: AppColors.paperGrid)
                      : Image(image: image!, fit: BoxFit.cover, gaplessPlayback: true),
                ),
              ),
              if (label != null && label!.isNotEmpty)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sunflower,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: Text(label!, style: AppText.label),
                  ),
                ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySm.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ],
      ),
    );

    final tilted = Transform.rotate(angle: _angle, child: card);
    if (onTap == null) {
      return Semantics(
        image: true,
        label: semanticLabel,
        child: ExcludeSemantics(child: tilted),
      );
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => ExcludeSemantics(child: tilted),
    );
  }
}
