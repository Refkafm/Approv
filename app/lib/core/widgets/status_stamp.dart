import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Status laporan & penukaran (design.md 7.9). Warna memakai varian `-deep` agar lolos AA.
enum StampStatus {
  pending('MENUNGGU', 'PENDING', AppColors.ink, AppColors.sunflower),
  approved('DISETUJUI', 'APPROVED', AppColors.matchaDeep, null),
  rejected('DITOLAK', 'REJECTED', AppColors.tangerineDeep, null),
  retake('FOTO ULANG', 'RETAKE', AppColors.cobaltDeep, null),
  fulfilled('DIBERIKAN', 'GIVEN', AppColors.grape, null),
  cancelled('DIBATALKAN', 'CANCELLED', AppColors.inkMuted, null),
  reached('TERCAPAI!', 'REACHED!', AppColors.matchaDeep, null);

  const StampStatus(this.labelId, this.labelEn, this.color, this.fill);

  final String labelId;
  final String labelEn;

  /// Warna garis & teks.
  final Color color;

  /// Isian (hanya MENUNGGU).
  final Color? fill;

  String label(Locale locale) => locale.languageCode == 'en' ? labelEn : labelId;

  /// Ukuran stempel mengikuti label terpanjang agar tata letak tidak bergeser saat ganti bahasa.
  String get longestLabel => labelId.length >= labelEn.length ? labelId : labelEn;
}

/// Stempel bergaris ganda, diputar −12°. Bila [animate], muncul dengan hentakan skala
/// 1.4 → 0.95 → 1.0 (atau fade 150ms saat reduce motion).
class StatusStamp extends StatefulWidget {
  const StatusStamp({super.key, required this.status, this.animate = false});

  final StampStatus status;
  final bool animate;

  @override
  State<StatusStamp> createState() => _StatusStampState();
}

class _StatusStampState extends State<StatusStamp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate) {
      _controller.value = 1;
      return;
    }
    if (_controller.isAnimating || _controller.value == 1) return;
    _controller.duration = AppMotion.reduce(context) ? AppMotion.reduced : AppMotion.stamp;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final label = status.label(Localizations.maybeLocaleOf(context) ?? const Locale('id'));
    final textStyle = AppText.stamp.copyWith(color: status.color);

    final stamp = Transform.rotate(
      angle: -12 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: status.fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: status.color, width: 2.5),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: status.color, width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(status.longestLabel, style: textStyle.copyWith(color: const Color(0x00000000))),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );

    final reduce = AppMotion.reduce(context);
    final animated = reduce
        ? FadeTransition(opacity: _controller, child: stamp)
        : ScaleTransition(
            scale: TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.95), weight: 60),
              TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
            ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
            child: stamp,
          );

    // container: dibacakan sendiri, tidak tergabung dengan teks di sekitarnya
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(child: animated),
    );
  }
}
