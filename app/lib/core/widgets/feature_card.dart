import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Warna kartu besar. Warna teks mengikuti tabel kontras design.md bagian 2:
/// tangerine & sunflower memakai ink, grape memakai putih.
enum FeatureCardTone {
  tangerine(AppColors.tangerine, AppColors.ink),
  sunflower(AppColors.sunflower, AppColors.ink),
  grape(AppColors.grape, AppColors.surface);

  const FeatureCardTone(this.fill, this.text);

  final Color fill;
  final Color text;
}

/// Kartu warna penuh (design.md 7.3): judul + deskripsi + aksi di kanan atas + konten.
/// Tidak punya outline/bayangan karena tidak bisa ditekan sebagai satu kesatuan.
class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.tone, required this.title, this.description, this.action, this.child});

  final FeatureCardTone tone;
  final String title;
  final String? description;
  final Widget? action;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.cardPadding),
      decoration: BoxDecoration(color: tone.fill, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: tone.text),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.titleLg.copyWith(color: tone.text)),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(description!, style: AppText.body.copyWith(color: tone.text)),
                      ],
                    ],
                  ),
                ),
                ?action,
              ],
            ),
            if (child != null) ...[const SizedBox(height: AppSpace.cardGap), child!],
          ],
        ),
      ),
    );
  }
}
