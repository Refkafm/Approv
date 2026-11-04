import 'models.dart';
import 'reward_models.dart';
import 'task_models.dart';

/// Salinan template ekonomi dari RPC apply_economy_template, hanya untuk FakeRepository.
/// Bila template di SQL berubah, ubah juga di sini. Judul mengikuti bahasa keluarga ([_en]).
abstract final class EconomyTemplate {
  static const _en = {
    'Rapikan kasur': 'Make the bed',
    'Bantu cuci piring': 'Help wash the dishes',
    'Baca buku 30 menit': 'Read a book for 30 minutes',
    'PR selesai tanpa disuruh': 'Homework done without being asked',
    'Bersihkan kamar': 'Clean the bedroom',
    'Nilai ujian ≥ 85': 'Test score ≥ 85',
    'Mainan baru': 'New toy',
    'Makan di restoran favorit': 'Dinner at a favorite restaurant',
    'Top-up game': 'Game top-up',
    '30 menit main game': '30 minutes of gaming',
    '30 menit TikTok / YouTube': '30 minutes of TikTok / YouTube',
    'Pilih menu makan malam': "Pick what's for dinner",
  };

  static String _title(String id, String locale) => locale == 'en' ? _en[id]! : id;

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

  static List<TaskInput> tasks(AgeBand band, {String locale = 'id'}) => [
    for (final t in _baseTasks)
      TaskInput(
        title: _title(t.title, locale),
        icon: t.icon,
        points: _round5(t.points * _factor(band)),
        frequency: t.frequency,
        maxPerDay: t.maxPerDay,
        verification: t.verification,
        allowGallery: t.allowGallery,
      ),
  ];

  static List<RewardInput> rewards(AgeBand band, {String locale = 'id'}) {
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
        title: _title('30 menit main game', locale),
        icon: 'game',
        cost: screen,
        type: RewardType.instant,
        durationMinutes: 30,
        maxPerDay: 2,
      ),
      RewardInput(
        title: _title('30 menit TikTok / YouTube', locale),
        icon: 'phone',
        cost: screen,
        type: RewardType.instant,
        durationMinutes: 30,
        maxPerDay: 2,
      ),
      RewardInput(
        title: _title('Pilih menu makan malam', locale),
        icon: 'food',
        cost: _round5(screen * 0.5),
        type: RewardType.instant,
        maxPerDay: 1,
      ),
      RewardInput(title: _title(goal.title, locale), icon: goal.icon, cost: goal.cost, type: goal.type),
    ];
  }
}
