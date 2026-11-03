import 'dart:convert';

import 'package:family_points/app.dart';
import 'package:family_points/core/analytics.dart';
import 'package:family_points/core/widgets/app_button.dart';
import 'package:family_points/data/fake/fake_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Recorder implements Analytics {
  String? userId;
  final events = <(String, Map<String, Object>)>[];

  @override
  void identify(String? userId) => this.userId = userId;

  @override
  void track(String event, [Map<String, Object> properties = const {}]) => events.add((event, properties));
}

Finder _button(String label) => find.widgetWithText(AppButton, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Event metrik sukses (Rencana-Implementasi, "Instrumentasi metrik sukses").
void main() {
  testWidgets('lapor tugas & meninjau mengirim task_submitted dan submission_reviewed', (tester) async {
    final repo = FakeRepository();
    final code = await repo.debugSeedFamily();
    final parentId = repo.debugSeedOwnerId!;
    await repo.signInAnonymously();
    final childId = (await repo.currentUser())!.id;
    await repo.joinFamily(code: code);
    final analytics = _Recorder();

    await tester.pumpWidget(FamilyPointsApp(repository: repo, analytics: analytics));
    await tester.pumpAndSettle();
    expect(analytics.userId, childId);
    await tester.tap(find.bySemanticsLabel('Tugas').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Bantu cuci piring'));
    await _tap(tester, _button('Kirim laporan'));
    await _tap(tester, _button('Oke'));

    final (submitted, submittedProps) = analytics.events.single;
    expect(submitted, AnalyticsEvent.taskSubmitted);
    expect(submittedProps, {'verification': 'approve', 'photos': 0, 'offline': false, 'role': 'member'});

    repo.debugSetUser(parentId);
    await tester.pumpAndSettle();
    expect(analytics.userId, parentId);
    await tester.tap(find.bySemanticsLabel('Persetujuan').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Bantu cuci piring'));
    await _tap(tester, _button('Setujui'));

    final (event, props) = analytics.events.last;
    expect(event, AnalyticsEvent.submissionReviewed);
    expect(props['action'], 'approve');
    expect(props['role'], 'owner');
    expect(props['minutes_to_review'], isA<int>());
  });

  test('PostHog: hanya mengirim setelah ada user, tanpa profil orang', () async {
    final requests = <http.Request>[];
    final posthog = PostHogAnalytics(
      apiKey: 'phc_test',
      host: 'https://eu.i.posthog.com',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      }),
    );

    posthog.track(AnalyticsEvent.familyCreated);
    posthog.identify('user-1');
    posthog.track(AnalyticsEvent.rewardRedeemed, {'type': 'goal'});
    await Future<void>.delayed(Duration.zero);

    final request = requests.single;
    expect(request.url.toString(), 'https://eu.i.posthog.com/capture/');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['api_key'], 'phc_test');
    expect(body['event'], 'reward_redeemed');
    expect(body['distinct_id'], 'user-1');
    expect(body['properties'], {'type': 'goal', r'$process_person_profile': false});
  });
}
