import 'models.dart';
import 'reward_models.dart';

/// Hadiah, penukaran, dan goal (PRD modul 6 & 7). Semua method melempar AppException saat gagal.
abstract interface class RewardRepository {
  Future<List<Reward>> listRewards(String familyId, {bool archived = false});

  Future<Reward> createReward(String familyId, RewardInput input);

  /// Mengubah semua isian kecuali harga. Harga diubah lewat [updateRewardPrice].
  Future<Reward> updateReward(String rewardId, RewardInput input);

  /// Kenaikan harga hadiah yang sedang jadi goal anak berlaku 7 hari lagi; selain itu langsung.
  /// Mengembalikan true bila dijadwalkan (bukan langsung berlaku).
  Future<bool> updateRewardPrice(String rewardId, int cost);

  Future<void> setRewardArchived(String rewardId, {required bool archived});

  /// Anak menukar hadiah (H-03): poin langsung ditahan. Hadiah goal memakai tabungan goal dulu.
  Future<void> redeemReward({required Member member, required String rewardId});

  /// Anak membatalkan penukaran yang belum diproses; poin kembali penuh.
  Future<void> cancelRedemption(String redemptionId);

  /// Penukaran anggota ini, terbaru di atas (riwayat A-9 & sesi aktif A-7).
  Future<List<Redemption>> memberRedemptions(String memberId);

  /// Antrean admin: diajukan, atau disetujui tapi belum diberikan.
  Future<List<Redemption>> openRedemptions(String familyId);

  /// H-04, H-05: setujui (sesi screen time mulai), tolak (alasan wajib, poin kembali), tandai sudah diberikan.
  Future<void> reviewRedemption(String redemptionId, RedemptionAction action, {String? reason});

  /// Goal aktif (G-01, G-02); null bila belum memilih.
  Future<GoalProgress?> activeGoal(Member member);

  Future<void> setGoal({required Member member, required String rewardId});

  /// Sisihkan (+) atau tarik (−) poin tabungan goal (G-03).
  Future<void> saveToGoal({required Member member, required int amount});
}
