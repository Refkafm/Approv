import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/feature_card.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/pressable.dart';
import '../../data/task_rules.dart';
import '../../data/wallet_models.dart';
import '../../data/reward_models.dart';
import '../rewards/goal_card.dart';
import '../shell/reload_on_changes.dart';
import '../shell/session.dart';
import '../wallet/wallet_views.dart';

/// Beranda anak (PRD A-2, design.md 8): sapaan → saldo → shortcut → goal → streak → tugas hari ini.
/// Saldo, goal, & streak ikut berubah saat orang tua menyetujui/memberi bonus (realtime).
class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> with ReloadOnChanges {
  Future<(WalletSummary, GoalProgress?)>? _data;

  Future<(WalletSummary, GoalProgress?)> _load() async {
    final session = SessionScope.read(context);
    final me = session.activeMember!;
    return (await session.repository.wallet(me), await session.repository.activeGoal(me));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _data = _load();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(WalletSummary, GoalProgress?)>(
      future: _data,
      builder: (context, snapshot) => _buildContent(context, snapshot.data?.$1, snapshot.data?.$2),
    );
  }

  Widget _buildContent(BuildContext context, WalletSummary? wallet, GoalProgress? goal) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 16, AppSpace.screenX, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Halo, ${SessionScope.of(context).activeMember?.name ?? ''}!', style: AppText.displayLg),
              ),
              IconCircleButton(
                icon: AppIcons.gear,
                semanticLabel: 'Pengaturan',
                tapTarget: TapTarget.child,
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BalanceView(wallet),
          const SizedBox(height: 24),
          const _Shortcuts(),
          const SizedBox(height: 24),
          GoalCard(goal: goal, onAction: () => context.go('/child/rewards')),
          const SizedBox(height: 24),
          StreakView(wallet),
          const SizedBox(height: 24),
          const _TodayTasksCard(),
        ],
      ),
    );
  }
}

/// Kartu "Tugas hari ini": maksimal 3 tugas yang masih bisa dikerjakan. Yang sudah dilaporkan,
/// disetujui, atau habis jatahnya hanya terlihat di tab Tugas (A-3).
class _TodayTasksCard extends StatefulWidget {
  const _TodayTasksCard();

  @override
  State<_TodayTasksCard> createState() => _TodayTasksCardState();
}

class _TodayTasksCardState extends State<_TodayTasksCard> with ReloadOnChanges {
  Future<List<TodayTask>>? _tasks;

  Future<List<TodayTask>> _load() {
    final session = SessionScope.read(context);
    return session.repository.todayTasks(session.activeMember!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tasks ??= _load();
    listenForChanges();
  }

  @override
  void reload() => setState(() {
    _tasks = _load();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TodayTask>>(
      future: _tasks,
      builder: (context, snapshot) {
        final today = (snapshot.data ?? const <TodayTask>[]).where((t) => t.scheduledToday).toList();
        final todo = today.where((t) => t.canReport).toList();
        final remaining = todo.length;
        return FeatureCard(
          tone: FeatureCardTone.tangerine,
          title: 'Tugas hari ini',
          description: snapshot.connectionState != ConnectionState.done
              ? null
              : (today.isEmpty
                    ? 'Belum ada tugas hari ini.'
                    : (remaining == 0 ? 'Semua tugas beres. Keren!' : 'Tinggal $remaining tugas lagi, semangat!')),
          child: Column(
            children: [
              for (final item in todo.take(3)) ...[
                ListRowPill(
                  title: item.task.title,
                  subtitle: item.statusLabel,
                  leading: CircleBadge(color: AppColors.pastelPeach, icon: AppIcons.task(item.task.icon)),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text('+${formatPoints(item.task.points)}', style: AppText.titleMd),
                  ),
                  onTap: () => context.go('/child/tasks'),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Pengaturan anak. Profil, badge, dan ganti PIN (A-11) menyusul.
Future<void> _showSettings(BuildContext context) {
  final session = SessionScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 24, AppSpace.screenX, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keluar dari HP ini?', style: AppText.titleLg),
          const SizedBox(height: 8),
          Text(
            'Poinmu tetap aman. Untuk masuk lagi, minta kode baru ke orang tua.',
            style: AppText.body.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Keluar',
            variant: AppButtonVariant.destructive,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              session.signOut();
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Batal',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Lingkaran kategori 72px (design.md 7.2) sebagai jalan pintas ke tab lain.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  static const _items = [
    (label: 'Tugas', icon: AppIcons.listChecks, color: AppColors.pastelPeach, path: '/child/tasks'),
    (label: 'Hadiah', icon: AppIcons.gift, color: AppColors.pastelLilac, path: '/child/rewards'),
    (label: 'Goal', icon: AppIcons.flag, color: AppColors.pastelButter, path: '/child/rewards'),
    (label: 'Riwayat', icon: AppIcons.clockCounterClockwise, color: AppColors.pastelSky, path: '/child/history'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Pressable(
                semanticLabel: item.label,
                onTap: () => context.go(item.path),
                builder: (context, pressed) => ExcludeSemantics(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: AppStroke.width),
                          boxShadow: pressed ? null : HardShadow.md,
                        ),
                        child: Icon(item.icon, size: 24, color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(item.label, style: AppText.label),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
