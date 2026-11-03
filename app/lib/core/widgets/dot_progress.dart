import 'package:flutter/widgets.dart';

import '../format.dart';
import '../theme/tokens.dart';

/// Progress goal berupa 20 lingkaran membentuk tangga naik ke kanan (design.md 7.5).
/// Setiap lingkaran = 5% dari harga goal, dibulatkan ke bawah.
class DotProgress extends StatelessWidget {
  const DotProgress({
    super.key,
    required this.saved,
    required this.target,
    required this.goalTitle,
    this.color = AppColors.ink,
  });

  final int saved;
  final int target;
  final String goalTitle;

  /// Warna titik; ink di atas kartu sunflower.
  final Color color;

  static const total = 20;

  /// Tinggi tiap kolom tangga (jumlahnya = [total]).
  static const columns = [2, 3, 4, 5, 6];

  static const _dot = 18.0;
  static const _gap = 6.0;

  /// Lingkaran terakhir baru terisi saat poin benar-benar cukup.
  static int filledDots(int saved, int target) {
    if (target <= 0 || saved <= 0) return 0;
    if (saved >= target) return total;
    return saved * total ~/ target;
  }

  static int percent(int saved, int target) {
    if (target <= 0 || saved <= 0) return 0;
    return (saved * 100 ~/ target).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final filled = filledDots(saved, target);
    var index = 0;

    final columnWidgets = <Widget>[];
    for (final height in columns) {
      final dots = <Widget>[];
      for (var i = 0; i < height; i++) {
        dots.add(_Dot(filled: index < filled, color: color));
        index++;
      }
      columnWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: _gap),
          // Diisi dari bawah ke atas
          child: Column(mainAxisSize: MainAxisSize.min, children: dots.reversed.toList()),
        ),
      );
    }

    return Semantics(
      container: true,
      label:
          'Goal $goalTitle, ${formatPoints(saved.clamp(0, target))} dari ${formatPoints(target)} poin, '
          '${percent(saved, target)} persen',
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: columnWidgets),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DotProgress._dot,
      height: DotProgress._dot,
      margin: const EdgeInsets.only(top: DotProgress._gap),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : null,
        border: Border.all(color: color, width: AppStroke.width),
      ),
    );
  }
}
