import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/paper_background.dart';

/// Tab bawah mode Orang Tua: Beranda · Persetujuan · Tugas · Hadiah · Keluarga
class ParentShell extends StatelessWidget {
  const ParentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const items = [
    AppNavItem(icon: AppIcons.house, label: 'Beranda'),
    AppNavItem(icon: AppIcons.sealCheck, label: 'Persetujuan'),
    AppNavItem(icon: AppIcons.listChecks, label: 'Tugas'),
    AppNavItem(icon: AppIcons.gift, label: 'Hadiah'),
    AppNavItem(icon: AppIcons.usersThree, label: 'Keluarga'),
  ];

  @override
  Widget build(BuildContext context) =>
      _ModeShell(navigationShell: navigationShell, items: items, tapTarget: TapTarget.parent);
}

/// Tab bawah mode Anak: Beranda · Tugas · Hadiah · Riwayat
class ChildShell extends StatelessWidget {
  const ChildShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const items = [
    AppNavItem(icon: AppIcons.house, label: 'Beranda'),
    AppNavItem(icon: AppIcons.listChecks, label: 'Tugas'),
    AppNavItem(icon: AppIcons.gift, label: 'Hadiah'),
    AppNavItem(icon: AppIcons.clockCounterClockwise, label: 'Riwayat'),
  ];

  @override
  Widget build(BuildContext context) =>
      _ModeShell(navigationShell: navigationShell, items: items, tapTarget: TapTarget.child);
}

class _ModeShell extends StatelessWidget {
  const _ModeShell({required this.navigationShell, required this.items, required this.tapTarget});

  final StatefulNavigationShell navigationShell;
  final List<AppNavItem> items;
  final double tapTarget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(child: navigationShell),
      bottomNavigationBar: AppBottomNav(
        items: items,
        currentIndex: navigationShell.currentIndex,
        tapTarget: tapTarget,
        onTap: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      ),
    );
  }
}
