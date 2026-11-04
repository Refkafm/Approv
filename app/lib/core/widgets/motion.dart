import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';

/// Motion bersama (design.md 10). Semua animasi di sini berubah menjadi fade 150ms saat "reduce motion".

/// Halaman detail: masuk dari kanan sambil fade, halaman lama bergeser sedikit ke kiri.
/// Di iOS memakai transisi bawaan agar gestur geser-untuk-kembali tetap ada.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static const _cupertino = CupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduce(context)) return FadeTransition(opacity: animation, child: child);
    if (Theme.of(context).platform == TargetPlatform.iOS && !route.fullscreenDialog) {
      return _cupertino.buildTransitions(route, context, animation, secondaryAnimation, child);
    }
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-0.08, 0)).animate(exit),
      child: SlideTransition(
        position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(enter),
        child: FadeTransition(opacity: enter, child: child),
      ),
    );
  }
}

/// Halaman alur (layar awal, login, onboarding, masuk ke beranda): fade sambil naik sedikit.
/// Dipakai lewat `pageBuilder` GoRoute karena perpindahan ini mengganti seluruh tumpukan halaman.
CustomTransitionPage<void> fadeRisePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.page,
    reverseTransitionDuration: AppMotion.reduced,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.reduce(context)) return FadeTransition(opacity: animation, child: child);
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Isi tab bawah: tab tujuan masuk dari arah tab yang diketuk (kanan/kiri) sambil fade,
/// tab lama memudar. Tab yang tidak aktif tetap hidup (state tersimpan) tetapi offstage.
class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, value: 1);
  late final Animation<double> _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  int? _previous;

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    _previous = oldWidget.currentIndex;
    _controller.duration = AppMotion.reduce(context) ? AppMotion.reduced : AppMotion.tab;
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) setState(() => _previous = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [for (var i = 0; i < widget.children.length; i++) _slot(i)]);
  }

  static const _still = AlwaysStoppedAnimation(1.0);
  static const _noSlide = AlwaysStoppedAnimation(Offset.zero);

  // Struktur widget tiap tab selalu sama (hanya nilainya yang berubah) agar navigator tab
  // tidak dipindah-pindah di pohon widget saat animasi mulai/selesai.
  Widget _slot(int index) {
    final previous = _previous;
    final active = index == widget.currentIndex;
    final leaving = index == previous;

    Animation<double> opacity = _still;
    Animation<Offset> position = _noSlide;
    if (active && previous != null) {
      opacity = _curved;
      if (!AppMotion.reduce(context)) {
        final dx = widget.currentIndex > previous ? 0.06 : -0.06;
        position = Tween(begin: Offset(dx, 0), end: Offset.zero).animate(_curved);
      }
    } else if (leaving) {
      opacity = ReverseAnimation(_curved);
    }

    return Offstage(
      offstage: !active && !leaving,
      child: TickerMode(
        enabled: active || leaving,
        child: IgnorePointer(
          ignoring: !active,
          child: ExcludeSemantics(
            excluding: !active,
            child: FadeTransition(
              opacity: opacity,
              child: SlideTransition(position: position, child: widget.children[index]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu muncul: fade + naik 12px, berurutan 40ms per [index] (design.md 10 "Kartu muncul").
/// Main sekali saat widget pertama kali dibuat, termasuk saat data selesai dimuat.
class Appear extends StatefulWidget {
  const Appear({super.key, this.index = 0, required this.child});

  final int index;
  final Widget child;

  /// Item ke-8 dan seterusnya muncul bersamaan.
  static const maxStaggered = 8;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Animation<double> _progress = const AlwaysStoppedAnimation(1);
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    _reduce = AppMotion.reduce(context);
    final delay = _reduce ? Duration.zero : AppMotion.cardStagger * widget.index.clamp(0, Appear.maxStaggered);
    final total = delay + (_reduce ? AppMotion.reduced : AppMotion.cardIn);
    _controller.duration = total;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t,
          child: _reduce ? child : Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
        );
      },
    );
  }
}

/// Bungkus isi daftar halaman dengan [Appear] berurutan. Jarak ([SizedBox]) tidak dihitung.
List<Widget> staggered(List<Widget> children) {
  var index = 0;
  return [for (final child in children) child is SizedBox ? child : Appear(index: index++, child: child)];
}
