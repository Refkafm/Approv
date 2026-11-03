import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/paper_background.dart';
import 'data/models.dart';
import 'data/reward_models.dart';
import 'data/submission_repository.dart';
import 'data/task_models.dart';
import 'features/approvals/approvals_page.dart';
import 'features/approvals/review_page.dart';
import 'features/family/family_page.dart';
import 'features/family/settings_page.dart';
import 'features/home/child_home_page.dart';
import 'features/home/parent_home_page.dart';
import 'features/onboarding/join_page.dart';
import 'features/onboarding/login_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/onboarding/welcome_page.dart';
import 'features/rewards/reward_form_page.dart';
import 'features/rewards/reward_list_page.dart';
import 'features/rewards/shop_page.dart';
import 'features/shell/components_page.dart';
import 'features/shell/mode_shells.dart';
import 'features/shell/session.dart';
import 'features/tasks/child_tasks_page.dart';
import 'features/tasks/task_form_page.dart';
import 'features/tasks/task_list_page.dart';
import 'features/wallet/child_detail_page.dart';
import 'features/wallet/child_history_page.dart';

/// Layar yang boleh dibuka sebelum punya keluarga.
const _guestRoutes = {'/', '/login', '/join'};

GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location.startsWith('/dev')) return null;
      if (!session.ready) return location == '/splash' ? null : '/splash';
      if (session.inFlow) return null;

      final user = session.user;
      if (session.activeMember == null) {
        // Belum login / sesi anak tanpa keluarga: layar awal, login, atau gabung
        if (user == null || user.isAnonymous) return _guestRoutes.contains(location) ? null : '/';
        // Orang tua baru: buat keluarga, atau gabung dengan kode dari pasangan
        return location == '/onboarding' || location == '/join' ? null : '/onboarding';
      }

      final prefix = session.mode == AppMode.parent ? '/parent' : '/child';
      return location.startsWith(prefix) ? null : '$prefix/home';
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const PaperBackground(child: SizedBox.expand()),
      ),
      GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/join', builder: (context, state) => const JoinPage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/dev/components', builder: (context, state) => const ComponentsPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ParentShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/home',
                builder: (context, state) => const ParentHomePage(),
                routes: [
                  GoRoute(
                    path: 'child',
                    builder: (context, state) => ChildDetailPage(member: state.extra as Member?),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/approvals',
                builder: (context, state) => const ApprovalsPage(),
                routes: [
                  GoRoute(
                    path: 'review',
                    builder: (context, state) => ReviewPage(item: state.extra as ReviewItem?),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/tasks',
                builder: (context, state) => const TaskListPage(),
                routes: [
                  GoRoute(path: 'new', builder: (context, state) => const TaskFormPage()),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => TaskFormPage(task: state.extra as Task?, isEdit: true),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/rewards',
                builder: (context, state) => const RewardListPage(),
                routes: [
                  GoRoute(path: 'new', builder: (context, state) => const RewardFormPage()),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => RewardFormPage(reward: state.extra as Reward?, isEdit: true),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/family',
                builder: (context, state) => const FamilyPage(),
                routes: [GoRoute(path: 'settings', builder: (context, state) => const SettingsPage())],
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ChildShell(navigationShell: shell),
        branches: [
          _branch('/child/home', (_) => const ChildHomePage()),
          _branch('/child/tasks', (_) => const ChildTasksPage()),
          _branch('/child/rewards', (_) => const ShopPage()),
          _branch('/child/history', (_) => const ChildHistoryPage()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget Function(GoRouterState state) page) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => page(state))],
  );
}
