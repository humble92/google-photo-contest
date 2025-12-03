import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humble_photo_contest/data/models/contest.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';
import 'package:humble_photo_contest/presentation/screens/auth/login_screen.dart';
import 'package:humble_photo_contest/presentation/screens/contest_detail/contest_detail_screen.dart';
import 'package:humble_photo_contest/presentation/screens/create_contest/create_contest_screen.dart';
import 'package:humble_photo_contest/presentation/screens/home/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'create-contest',
            builder: (context, state) => const CreateContestScreen(),
          ),
          GoRoute(
            path: 'contest/:id',
            builder: (context, state) {
              final contest = state.extra as Contest;
              return ContestDetailScreen(contest: contest);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.value?.session != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
  );
});
