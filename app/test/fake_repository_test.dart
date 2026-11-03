import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/reward_models.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _throwsCode(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

/// Repository palsu harus meniru aturan RPC di supabase/migrations, karena dipakai oleh tes UI.
void main() {
  test('akun anonim tidak bisa membuat keluarga', () async {
    final repo = FakeRepository();
    await repo.signInAnonymously();
    await expectLater(repo.createFamily(familyName: 'x', ownerName: 'y'), _throwsCode('account_required'));
  });

  test('kode undangan anak hanya bisa dipakai sekali', () async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    await repo.signInAnonymously();
    final raka = await repo.joinFamily(code: code);
    expect(raka.name, 'Raka');
    expect((await repo.myMemberships()).single.id, raka.id);

    await repo.signInAnonymously();
    await expectLater(repo.joinFamily(code: code), _throwsCode('invalid_invite'));
  });

  test('kode undangan kedaluwarsa setelah 24 jam', () async {
    var now = DateTime(2026, 11, 2, 8);
    final repo = FakeRepository(clock: () => now);
    final code = await repo.debugSeedFamily();
    now = now.add(const Duration(hours: 24, minutes: 1));
    await repo.signInAnonymously();
    await expectLater(repo.joinFamily(code: code), _throwsCode('invalid_invite'));
  });

  test('kode baru untuk anak yang sama membatalkan kode lama', () async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    final familyId = await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
    final raka = await repo.addChild(familyId: familyId, name: 'Raka');
    final oldCode = await repo.createInvite(familyId: familyId, role: MemberRole.member, memberId: raka.id);
    final newCode = await repo.createInvite(familyId: familyId, role: MemberRole.member, memberId: raka.id);

    await repo.signInAnonymously();
    await expectLater(repo.joinFamily(code: oldCode), _throwsCode('invalid_invite'));
    expect((await repo.joinFamily(code: newCode)).id, raka.id);
  });

  test('undangan admin: hanya owner yang membuat, dan wajib akun penuh untuk bergabung', () async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    final familyId = await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
    final code = await repo.createInvite(familyId: familyId, role: MemberRole.admin);

    await repo.signInAnonymously();
    await expectLater(repo.joinFamily(code: code), _throwsCode('account_required'));

    await repo.signInWithApple();
    final ayah = await repo.joinFamily(code: code, name: 'Ayah');
    expect(ayah.role, MemberRole.admin);
    expect(ayah.name, 'Ayah');
    await expectLater(repo.createInvite(familyId: familyId, role: MemberRole.admin), _throwsCode('owner_only'));
  });

  test('orang luar tidak bisa melihat atau mengubah keluarga lain', () async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    final familyId = await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');

    await repo.signInWithGoogle();
    await expectLater(repo.familyMembers(familyId), _throwsCode('not_authorized'));
    await expectLater(repo.addChild(familyId: familyId, name: 'X'), _throwsCode('not_authorized'));
  });

  test('anak terhubung terlihat oleh admin', () async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    final familyId = await repo.createFamily(familyName: 'Keluarga Rina', ownerName: 'Ibu Rina');
    final raka = await repo.addChild(familyId: familyId, name: 'Raka');
    expect((await repo.familyMembers(familyId)).firstWhere((m) => m.id == raka.id).isConnected, isFalse);
  });

  test('PIN harus 4 angka', () async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    await repo.signInAnonymously();
    final raka = await repo.joinFamily(code: code);
    await expectLater(repo.setPin(memberId: raka.id, pin: '12a4'), _throwsCode('invalid_pin'));
    await repo.setPin(memberId: raka.id, pin: '4321');
    expect(repo.debugPinOf(raka.id), '4321');
  });

  test('template mengikuti angka di SQL apply_economy_template', () async {
    final repo = FakeRepository();
    await repo.signInWithGoogle();
    final ids = <AgeBand, String>{};
    for (final band in AgeBand.values) {
      ids[band] = await repo.createFamily(familyName: 'K', ownerName: 'O');
      await repo.applyTemplate(familyId: ids[band]!, band: band);
    }
    final young = await repo.listTasks(ids[AgeBand.young]!);
    final middle = await repo.listTasks(ids[AgeBand.middle]!);
    final teen = await repo.listTasks(ids[AgeBand.teen]!);
    expect([young.first.points, middle.first.points, teen.first.points], [10, 20, 25]);
    expect(middle, hasLength(6));

    final teenRewards = await repo.listRewards(ids[AgeBand.teen]!);
    expect(teenRewards.first.cost, 150);
    expect(teenRewards.first.durationMinutes, 30);
    expect(teenRewards.last.type, RewardType.goal);
  });

  test('OTP demo', () async {
    final repo = FakeRepository();
    await expectLater(repo.sendPhoneOtp('0812'), _throwsCode('invalid_phone'));
    await repo.sendPhoneOtp('+6281234567890');
    await expectLater(repo.verifyPhoneOtp('+6281234567890', '000000'), _throwsCode('invalid_otp'));
    await repo.verifyPhoneOtp('+6281234567890', FakeRepository.demoOtp);
    expect((await repo.currentUser())!.isAnonymous, isFalse);
  });
}
