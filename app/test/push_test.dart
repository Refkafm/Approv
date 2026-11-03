import 'dart:async';

import 'package:family_points/app.dart';
import 'package:family_points/core/push.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:family_points/features/approvals/approvals_page.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePush implements PushService {
  final calls = <String>[];
  final routes = StreamController<String>();

  @override
  Future<void> identify(String userId) async => calls.add('identify:$userId');

  @override
  Future<void> clear() async => calls.add('clear');

  @override
  Stream<String> get openedRoutes => routes.stream;
}

/// HP dikaitkan ke OneSignal (external_id = auth user id) hanya selama punya keluarga.
void main() {
  testWidgets('identify setelah masuk keluarga, clear setelah keluar', (tester) async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    final push = _FakePush();
    await tester.pumpWidget(FamilyPointsApp(repository: repo, push: push));
    await tester.pumpAndSettle();
    expect(push.calls, isEmpty, reason: 'belum masuk: tidak ada yang dikaitkan');

    await repo.signInAnonymously();
    final childId = (await repo.currentUser())!.id;
    await repo.joinFamily(code: code);
    repo.debugSetUser(childId, anonymous: true);
    await tester.pumpAndSettle();
    expect(push.calls, ['identify:$childId']);

    await repo.signOut();
    await tester.pumpAndSettle();
    expect(push.calls, ['identify:$childId', 'clear']);
  });

  testWidgets('notifikasi diketuk membuka rute tujuannya', (tester) async {
    final repo = FakeRepository();
    await repo.debugSeedFamily();
    repo.debugSetUser(repo.debugSeedOwnerId!);
    final push = _FakePush();
    await tester.pumpWidget(FamilyPointsApp(repository: repo, push: push));
    await tester.pumpAndSettle();
    expect(find.byType(ApprovalsPage), findsNothing);

    push.routes.add('/parent/approvals');
    await tester.pumpAndSettle();
    expect(find.byType(ApprovalsPage), findsOneWidget);
  });
}
