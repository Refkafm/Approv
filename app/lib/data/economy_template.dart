import 'models.dart';
import 'reward_models.dart';
import 'task_models.dart';

/// Salinan template ekonomi dari RPC apply_economy_template, hanya untuk FakeRepository.
/// Bila template di SQL berubah, ubah juga di sini.
abstract final class EconomyTemplate {
  static const _baseTasks = [
    TaskInput(
      title: 'Rapikan kasur',
      icon: 'bed',
      points: 20,
      frequency: TaskFrequency.daily,
      verification: TaskVerification.auto,
    ),
    TaskInput(
      title: 'Bantu cuci piring',
      icon: 'dish',
      points: 50,
      frequency: TaskFrequency.daily,
      verification: TaskVerification.approve,
    ),
    TaskInput(
      title: 'Baca buku 30 menit',
      icon: 'book',
      points: 60,
      frequency: TaskFrequency.repeat,
      maxPerDay: 2,
      verification: TaskVerification.approve,
    ),
    TaskInput(
      title: 'PR selesai tanpa disuruh',
      icon: 'pencil',
      points: 80,
      frequency: TaskFrequency.daily,
      verification: TaskVerification.photo,
    ),
    TaskInput(
      title: 'Bersihkan kamar',
      icon: 'broom',
      points: 150,
      frequency: TaskFrequency.weekly,
      verification: TaskVerification.photo,
    ),
    TaskInput(
      title: 'Nilai ujian ≥ 85',
      icon: 'trophy',
      points: 300,
      frequency: TaskFrequency.once,
      verification: TaskVerification.photo,
      allowGallery: true,
    ),
  ];

  static double _factor(AgeBand band) => switch (band) {
    AgeBand.young => 0.5,
    AgeBand.middle => 1,
    AgeBand.teen => 1.35,
  };

  static int _round5(num value) => ((value / 5).round() * 5).clamp(5, 1 << 30).toInt();

  static List<TaskInput> tasks(AgeBand band) => [
    for (final t in _baseTasks)
      TaskInput(
        title: t.title,
        icon: t.icon,
        points: _round5(t.points * _factor(band)),
        frequency: t.frequency,
        maxPerDay: t.maxPerDay,
        verification: t.verification,
        allowGallery: t.allowGallery,
      ),
  ];

  static List<RewardInput> rewards(AgeBand band) {
    final screen = band.screenTimePrice;
    final goal = switch (band) {
      AgeBand.young => const RewardInput(title: 'Mainan baru', icon: 'gift', cost: 2000, type: RewardType.goal),
      AgeBand.middle => const RewardInput(
        title: 'Makan di restoran favorit',
        icon: 'food',
        cost: 5000,
        type: RewardType.goal,
      ),
      AgeBand.teen => const RewardInput(title: 'Top-up game', icon: 'game', cost: 10000, type: RewardType.goal),
    };
    return [
      RewardInput(
        title: '30 menit main game',
        icon: 'game',
        cost: screen,
        type: RewardType.instant,
        durationMinutes: 30,
        maxPerDay: 2,
      ),
      RewardInput(
        title: '30 menit TikTok / YouTube',
        icon: 'phone',
        cost: screen,
        type: RewardType.instant,
        durationMinutes: 30,
        maxPerDay: 2,
      ),
      RewardInput(
        title: 'Pilih menu makan malam',
        icon: 'food',
        cost: _round5(screen * 0.5),
        type: RewardType.instant,
        maxPerDay: 1,
      ),
      goal,
    ];
  }
}
