import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Efek tekan khas design.md: saat ditekan, bayangan keras hilang dan elemen bergeser (2, 3),
/// seperti ditekan ke kertas. [builder] menerima status tekan untuk mengatur bayangan.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.builder, required this.onTap, this.semanticLabel, this.selected});

  final Widget Function(BuildContext context, bool pressed) builder;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Untuk elemen yang bisa dipilih (kartu pilihan, avatar).
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final offset = _pressed ? AppMotion.pressOffset : Offset.zero;
    // container: tombol jadi node sendiri bagi pembaca layar, tidak tergabung dengan teks di sebelahnya
    return Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: AppMotion.reduce(context) ? Duration.zero : AppMotion.press,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
          child: widget.builder(context, _pressed),
        ),
      ),
    );
  }
}
