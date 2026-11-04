import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/goal_progress_bar.dart';
import '../../core/widgets/feature_card.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/list_row_pill.dart';
import '../../core/widgets/paper_background.dart';
import '../../core/widgets/points_balance.dart';
import '../../core/widgets/status_stamp.dart';
import '../../core/widgets/streak_row.dart';

/// Galeri komponen desain (hanya mode debug), untuk ditinjau desainer.
class ComponentsPage extends StatelessWidget {
  const ComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Komponen desain')),
      backgroundColor: AppColors.paper,
      body: PaperBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenX, 8, AppSpace.screenX, 48),
          children: [
            _section('Tombol'),
            AppButton(label: 'Tukar sekarang', onPressed: () {}),
            const SizedBox(height: 12),
            AppButton(label: 'Lihat semua', variant: AppButtonVariant.secondary, onPressed: () {}),
            const SizedBox(height: 12),
            AppButton(label: 'Tolak', variant: AppButtonVariant.destructive, onPressed: () {}),
            const SizedBox(height: 12),
            const AppButton(label: 'Butuh 1 foto lagi', onPressed: null),
            const SizedBox(height: 12),
            Row(
              children: [
                IconCircleButton(icon: AppIcons.plus, semanticLabel: 'Tambah', onPressed: () {}),
                IconCircleButton(icon: AppIcons.arrowUpRight, semanticLabel: 'Buka', onPressed: () {}),
              ],
            ),
            _section('Stempel status'),
            Wrap(spacing: 16, runSpacing: 24, children: [for (final s in StampStatus.values) StatusStamp(status: s)]),
            _section('Saldo'),
            const PointsBalance(available: 3250, goalSaved: 1200, onHold: 100),
            const SizedBox(height: 16),
            const PointsBalance(available: -10, debtReason: 'Tugas "Rapikan kasur" dibatalkan'),
            _section('Progress goal'),
            const Column(
              children: [
                GoalProgressBar(saved: 0, target: 5000, goalTitle: 'Contoh'),
                SizedBox(height: 16),
                GoalProgressBar(saved: 3200, target: 5000, goalTitle: 'Contoh'),
                SizedBox(height: 16),
                GoalProgressBar(saved: 5000, target: 5000, goalTitle: 'Contoh'),
              ],
            ),
            _section('Streak'),
            const StreakRow(
              count: 4,
              days: [
                StreakDay.success,
                StreakDay.success,
                StreakDay.success,
                StreakDay.pending,
                StreakDay.today,
                StreakDay.empty,
                StreakDay.empty,
              ],
            ),
            _section('Kartu & baris'),
            FeatureCard(
              tone: FeatureCardTone.tangerine,
              title: 'Tugas hari ini',
              description: 'Tinggal 2 tugas lagi, semangat!',
              action: IconCircleButton(icon: AppIcons.plus, semanticLabel: 'Tambah', onPressed: () {}),
              child: ListRowPill(
                title: 'Bantu cuci piring',
                subtitle: 'Menunggu persetujuan',
                leading: const CircleBadge(color: AppColors.pastelPeach, icon: AppIcons.checkSquare),
                onTap: () {},
              ),
            ),
            const SizedBox(height: AppSpace.cardGap),
            const FeatureCard(tone: FeatureCardTone.sunflower, title: 'Goal saya', description: 'Sepatu baru'),
            const SizedBox(height: AppSpace.cardGap),
            const FeatureCard(tone: FeatureCardTone.grape, title: 'Keluarga', description: '2 anak · 2 admin'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 12),
    child: Text(title, style: AppText.titleLg),
  );
}
