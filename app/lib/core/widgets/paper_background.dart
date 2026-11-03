import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Latar krem bergaris grid 24px (design.md 2, "Latar grid"). Hanya untuk latar layar,
/// tidak dipakai di dalam kartu berwarna.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GridPainter(), child: child);
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  static const _cell = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.paper);
    final line = Paint()
      ..color = AppColors.paperGrid
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y <= size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
