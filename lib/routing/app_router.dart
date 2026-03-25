import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/player/presentation/player_screen.dart';
import '../features/playlists/presentation/playlists_screen.dart';
import '../features/import/presentation/import_screen.dart';
import '../views/shell_view.dart';

/// All named routes in the app.
class AppRoutes {
  static const library = '/library';
  static const playlists = '/playlists';
  static const player = '/player';
  static const import = '/import';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.library,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellView(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.library,
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: AppRoutes.playlists,
            builder: (context, state) => const PlaylistsScreen(),
          ),
        ],
      ),
      // Full-screen routes (outside of shell / bottom-nav)
      GoRoute(
        path: AppRoutes.player,
        builder: (context, state) => const PlayerScreen(),
      ),
      GoRoute(
        path: AppRoutes.import,
        builder: (context, state) => const ImportScreen(),
      ),
    ],
  );
});
