import 'package:family_points/data/app_exception.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/data/models.dart';
import 'package:family_points/data/task_models.dart';
import 'package:family_points/data/wallet_models.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _throwsCode(String code) => throwsA(isA<AppException>().having((e) => e.code, 'code', code));

/// Dompet di repository palsu harus sama dengan RPC adjust_points & reverse_auto_task.
void main() {
  late DateTime now;
  late FakeRepository repo;
  late String parentId;
  late Member raka;
  late Map<String, Task> tasks;

  setUp(() async {
    now = DateTime.utc(2026, 11, 5, 3); // Kamis 10:00 WIB
    repo = FakeRepository(clock: () => now);
    final code = await repo.debugSeedFamily();
    parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    raka = await repo.joinFamily(code: code);
    tasks = {for (final t in await repo.listTasks(raka.familyId)) t.title: t};
    await repo.submitTask(member: raka, taskId: tasks['Rapikan kasur']!.id); // otomatis, +20
  });

  Future<T> asParent<T>(Future<T> Function() body) => repo.debugAs(parentId, body);

  test('saldo & streak dari ledger', () async {
    final wallet = await repo.wallet(raka);
    expect(wallet.balance.available, 20);
    expect(wallet.streak, 1);
    expect(wallet.week[3], DayActivity.success, reason: 'Kamis');
    expect((await repo.history(raka.id)).single.title, 'Rapikan kasur');
  });

  test('bonus & penalti: alasan wajib, penalti tidak boleh melebihi saldo', () async {
    await asParent(() => repo.adjustPoints(memberId: raka.id, amount: 30, reason: 'Nilai bagus'));
    expect(repo.debugBalance(raka.id), 50);

    await expectLater(
      asParent(() => repo.adjustPoints(memberId: raka.id, amount: 10, reason: ' ')),
      _throwsCode('reason_required'),
    );
    await expectLater(
      asParent(() => repo.adjustPoints(memberId: raka.id, amount: 0, reason: 'x')),
      _throwsCode('invalid_amount'),
    );
    await expectLater(
      asParent(() => repo.adjustPoints(memberId: raka.id, amount: -51, reason: 'Main melebihi waktu')),
      _throwsCode('insufficient_points'),
    );
    await asParent(() => repo.adjustPoints(memberId: raka.id, amount: -50, reason: 'Main melebihi waktu'));
    expect(repo.debugBalance(raka.id), 0);

    final history = await repo.history(raka.id);
    expect(history.first.title, 'Penalti: Main melebihi waktu', reason: 'terbaru di atas');
  });

  test('anak tidak bisa memberi bonus ke dirinya', () async {
    await expectLater(repo.adjustPoints(memberId: raka.id, amount: 100, reason: 'x'), _throwsCode('not_authorized'));
  });

  test('batalkan tugas otomatis ≤ 24 jam; saldo boleh minus (utang poin)', () async {
    final subId = (await asParent(() => repo.reversibleSubmissions(raka.id))).single;
    await asParent(() => repo.adjustPoints(memberId: raka.id, amount: -20, reason: 'Tes'));

    await expectLater(
      asParent(() => repo.reverseAutoTask(submissionId: subId, reason: '')),
      _throwsCode('reason_required'),
    );
    await asParent(() => repo.reverseAutoTask(submissionId: subId, reason: 'Kasur belum rapi'));

    final wallet = await repo.wallet(raka);
    expect(wallet.balance.available, -20);
    expect(wallet.debtReason, 'Kasur belum rapi');
    expect(wallet.streak, 0, reason: 'laporan yang dibatalkan tidak dihitung');
    expect(await asParent(() => repo.reversibleSubmissions(raka.id)), isEmpty);
    await expectLater(
      asParent(() => repo.reverseAutoTask(submissionId: subId, reason: 'lagi')),
      _throwsCode('not_reversible'),
    );
  });

  test('lewat 24 jam tidak bisa dibatalkan', () async {
    final subId = (await asParent(() => repo.reversibleSubmissions(raka.id))).single;
    now = now.add(const Duration(hours: 25));
    expect(await asParent(() => repo.reversibleSubmissions(raka.id)), isEmpty);
    await expectLater(
      asParent(() => repo.reverseAutoTask(submissionId: subId, reason: 'x')),
      _throwsCode('reversal_window_passed'),
    );
  });
}
