import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../../l10n/strings.dart';

/// Status satu hari di indikator streak (design.md 7.10b, PRD aturan bisnis 8).
enum StreakDay {
  success,
  pending,

  /// Putus, atau hari yang belum terjadi.
  empty,
  today;

  String get spoken => switch (this) {
    success => S.current.streakSuccess,
    pending => S.current.streakPending,
    empty => S.current.streakEmpty,
    today => S.current.streakToday,
  };
}

/// Deretan 7 hari (Senin–Minggu) + jumlah hari berturut-turut.
class StreakRow extends StatelessWidget {
  /// [days] berisi tepat 7 hari, Senin sampai Minggu.
  const StreakRow({super.key, required this.days, required this.count});

  final List<StreakDay> days;
  final int count;

  bool get hasPending => days.contains(StreakDay.pending);

  @override
  Widget build(BuildContext context) {
    assert(days.length == 7, 'StreakRow butuh tepat 7 hari');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$count', style: AppText.titleLg),
              TextSpan(text: context.s.daysInARow, style: AppText.body),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 7; i++)
              Semantics(
                label: '${context.s.isoDayLong(i + 1)}: ${days[i].spoken}',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DayCircle(state: days[i]),
                      const SizedBox(height: 4),
                      Text(context.s.isoDayShort(i + 1), style: AppText.label),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (hasPending) ...[
          const SizedBox(height: 8),
          Text(context.s.streakPendingNote, style: AppText.bodySm.copyWith(color: AppColors.inkMuted)),
        ],
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.state});

  final StreakDay state;

  static const _size = 28.0;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      StreakDay.success => _circle(fill: AppColors.matcha, border: AppColors.ink, icon: AppIcons.check),
      StreakDay.pending => CustomPaint(
        painter: const _DashedCirclePainter(),
        child: _circle(fill: AppColors.sunflower, border: null, icon: AppIcons.hourglass),
      ),
      StreakDay.empty => _circle(fill: AppColors.surface, border: AppColors.lineSoft),
      StreakDay.today => _circle(fill: null, border: AppColors.ink),
    };
  }

  Widget _circle({required Color? fill, required Color? border, IconData? icon}) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: border == null ? null : Border.all(color: border, width: AppStroke.width),
      ),
      child: icon == null ? null : Icon(icon, size: 14, color: AppColors.ink),
    );
  }
}

/// Outline putus-putus untuk hari "tertunda".
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.width;
    final rect = Offset.zero & size;
    const dashes = 10;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(1), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}
