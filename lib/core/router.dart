import 'package:go_router/go_router.dart';
import '../screens/landing_screen.dart';
import '../screens/home_screen.dart';
import '../screens/anime_detail_screen.dart';
import '../screens/watch_screen.dart';
import '../screens/list_screen.dart';
import '../screens/search_screen.dart';
import '../screens/auth_screens.dart';
import '../screens/watchlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/continue_watching_screen.dart';
import '../screens/splash_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/watchlist',
      builder: (context, state) => const WatchlistScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/notification',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/continue-watching',
      builder: (context, state) => const ContinueWatchingScreen(),
    ),
    GoRoute(
      path: '/watch/:id/:episodeNumber',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final ep = state.pathParameters['episodeNumber'] ?? '1';
        final extra = state.extra as Map<String, dynamic>?;
        final initialDub = extra?['dub']?.toString();
        final initialServer = extra?['server']?.toString();
        return WatchScreen(
          id: id,
          episodeNumber: ep,
          initialDub: initialDub,
          initialServer: initialServer,
        );
      },
    ),
    // Lists & Categories Routing
    GoRoute(
      path: '/most-popular',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'most-popular'),
    ),
    GoRoute(
      path: '/top-airing',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'top-airing'),
    ),
    GoRoute(
      path: '/most-favorite',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'most-favorite'),
    ),
    GoRoute(
      path: '/completed',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'completed'),
    ),
    GoRoute(
      path: '/movie',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'movie'),
    ),
    GoRoute(
      path: '/tv',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'tv'),
    ),
    GoRoute(
      path: '/ova',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'ova'),
    ),
    GoRoute(
      path: '/ona',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'ona'),
    ),
    GoRoute(
      path: '/special',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'special'),
    ),
    GoRoute(
      path: '/top-upcoming',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'top-upcoming'),
    ),
    GoRoute(
      path: '/recently-updated',
      builder: (context, state) => const ListScreen(mode: 'category', arg: 'recently-updated'),
    ),
    GoRoute(
      path: '/genre/:name',
      builder: (context, state) {
        final name = state.pathParameters['name'] ?? '';
        return ListScreen(mode: 'genre', arg: name);
      },
    ),
    GoRoute(
      path: '/producer/:name',
      builder: (context, state) {
        final name = state.pathParameters['name'] ?? '';
        return ListScreen(mode: 'producer', arg: name);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final queryParams = state.uri.queryParameters;
        return SearchScreen(
          keyword: queryParams['keyword'] ?? '',
          page: int.tryParse(queryParams['page'] ?? '') ?? 1,
          type: queryParams['type'] ?? 'all',
          status: queryParams['status'] ?? 'all',
          rated: queryParams['rated'] ?? 'all',
          score: queryParams['score'] ?? 'all',
          season: queryParams['season'] ?? 'all',
          language: queryParams['language'] ?? 'all',
          sort: queryParams['sort'] ?? 'default',
          startDate: queryParams['startDate'] ?? '',
          endDate: queryParams['endDate'] ?? '',
          genres: queryParams['genres']?.split(',').where((g) => g.isNotEmpty).toList() ?? [],
        );
      },
    ),
    // Detailed Anime Route (/:slug/:id)
    GoRoute(
      path: '/:slug/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AnimeDetailScreen(id: id);
      },
    ),
  ],
);
