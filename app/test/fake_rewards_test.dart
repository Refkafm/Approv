import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/reward_models.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _throwsCode(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

/// Hadiah & goal di repository palsu harus sama dengan RPC redeem_reward, review_redemption,
/// cancel_redemption, set_goal, save_to_goal, update_reward_price.
void main() {
  late DateTime now;
  late FakeRepository repo;
  late String parentId;
  late Member raka;
  late Map<String, Reward> rewards;

  setUp(() async {
    now = DateTime.utc(2026, 11, 5, 3);
    repo = FakeRepository(clock: () => now);
    final code = await repo.debugSeedFamily();
    parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    raka = await repo.joinFamily(code: code);
    rewards = {for (final r in await repo.listRewards(raka.familyId)) r.title: r};
    await repo.debugAs(parentId, () => repo.adjustPoints(memberId: raka.id, amount: 300, reason: 'Modal'));
  });

  Future<T> asParent<T>(Future<T> Function() body) => repo.debugAs(parentId, body);
  Future<Redemption> latest() async => (await repo.memberRedemptions(raka.id)).first;

  test('tukar → poin ditahan; ditolak → poin kembali penuh', () async {
    await repo.redeemReward(member: raka, rewardId: rewards['30 menit main game']!.id);
    expect(repo.debugBalance(raka.id), 200);
    expect((await repo.wallet(raka)).balance.onHold, 100);

    final r = await latest();
    await expectLater(
      asParent(() => repo.reviewRedemption(r.id, RedemptionAction.reject)),
      _throwsCode('reason_required'),
    );
    await asParent(() => repo.reviewRedemption(r.id, RedemptionAction.reject, reason: 'Besok saja'));
    expect(repo.debugBalance(raka.id), 300);
    expect((await latest()).status, RedemptionStatus.rejected);
  });

  test('disetujui → sesi screen time berjalan lalu selesai sendiri (H-06)', () async {
    await repo.redeemReward(member: raka, rewardId: rewards['30 menit main game']!.id);
    final r = await latest();
    await asParent(() => repo.reviewRedemption(r.id, RedemptionAction.approve));
    expect((await latest()).sessionActive(now), isTrue);
    expect((await latest()).sessionEndsAt!.difference(now), const Duration(minutes: 30));

    now = now.add(const Duration(minutes: 31));
    expect((await latest()).status, RedemptionStatus.fulfilled);
  });

  test('batal hanya saat masih diajukan; batas harian dihitung', () async {
    final game = rewards['30 menit main game']!.id;
    await repo.redeemReward(member: raka, rewardId: game);
    await repo.cancelRedemption((await latest()).id);
    expect(repo.debugBalance(raka.id), 300);
    await expectLater(repo.cancelRedemption((await latest()).id), _throwsCode('not_cancellable'));

    await repo.redeemReward(member: raka, rewardId: game);
    await repo.redeemReward(member: raka, rewardId: game);
    await expectLater(repo.redeemReward(member: raka, rewardId: game), _throwsCode('reward_limit_reached'));
  });

  test('goal: tabungan dipakai dulu, sisa dari saldo; diberikan → goal tercapai (G-01–G-03)', () async {
    final goalReward = rewards['Makan di restoran favorit']!;
    await repo.setGoal(member: raka, rewardId: goalReward.id);
    await repo.saveToGoal(member: raka, amount: 200);
    var goal = (await repo.activeGoal(raka))!;
    expect(goal.saved, 200);
    expect(goal.progress, 300);
    expect(goal.reached, isFalse);
    await expectLater(repo.redeemReward(member: raka, rewardId: goalReward.id), _throwsCode('insufficient_points'));

    await asParent(() => repo.adjustPoints(memberId: raka.id, amount: 4800, reason: 'Ulang tahun'));
    goal = (await repo.activeGoal(raka))!;
    expect(goal.reached, isTrue);
    await repo.redeemReward(member: raka, rewardId: goalReward.id);
    final wallet = await repo.wallet(raka);
    expect(wallet.balance.goalSaved, 0);
    expect(wallet.balance.available, 100);

    await asParent(() async => repo.reviewRedemption((await latest()).id, RedemptionAction.fulfill));
    expect(await repo.activeGoal(raka), isNull);
  });

  test('ganti goal: tabungan lama kembali ke saldo', () async {
    final created = await asParent(
      () =>
          repo.createReward(raka.familyId, const RewardInput(title: 'Sepatu baru', cost: 8000, type: RewardType.goal)),
    );
    await repo.setGoal(member: raka, rewardId: rewards['Makan di restoran favorit']!.id);
    await repo.saveToGoal(member: raka, amount: 100);
    await repo.setGoal(member: raka, rewardId: created.id);
    expect((await repo.wallet(raka)).balance.goalSaved, 0);
    expect(repo.debugBalance(raka.id), 300);
  });

  test('kenaikan harga goal dijadwalkan 7 hari; penurunan langsung (aturan bisnis 6)', () async {
    final id = rewards['Makan di restoran favorit']!.id;
    expect(await asParent(() => repo.updateRewardPrice(id, 6000)), isFalse, reason: 'belum jadi goal siapa pun');
    await repo.setGoal(member: raka, rewardId: id);
    expect(await asParent(() => repo.updateRewardPrice(id, 7000)), isTrue);
    final reward = (await repo.listRewards(raka.familyId)).firstWhere((r) => r.id == id);
    expect(reward.cost, 6000);
    expect(reward.pendingCost, 7000);
    expect(await asParent(() => repo.updateRewardPrice(id, 5500)), isFalse);
  });

  test('anak tidak bisa membuat hadiah atau menyetujui penukarannya', () async {
    await expectLater(
      repo.createReward(raka.familyId, const RewardInput(title: 'x', cost: 1, type: RewardType.instant)),
      _throwsCode('not_authorized'),
    );
    await repo.redeemReward(member: raka, rewardId: rewards['Pilih menu makan malam']!.id);
    await expectLater(
      repo.reviewRedemption((await latest()).id, RedemptionAction.approve),
      _throwsCode('not_authorized'),
    );
  });
}
