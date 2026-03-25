import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../../../routing/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../../models/song_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/player/presentation/song_tile.dart';

/// Main library screen showing all imported songs.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Jazz Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Import Files',
            onPressed: () => context.go(AppRoutes.import),
          ),
        ],
      ),
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (songs) => songs.isEmpty
            ? _EmptyState(onImport: () => context.go(AppRoutes.import))
            : _SongsList(songs: songs),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  const _EmptyState({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_off_rounded,
              size: 80, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Your library is empty',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Tap + to import audio or video files',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.add),
            label: const Text('Import Files'),
          ),
        ],
      ),
    );
  }
}

class _SongsList extends ConsumerWidget {
  final List<SongModel> songs;
  const _SongsList({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongTile(
          song: song,
          onTap: () async {
            final handler = ref.read(musicHandlerProvider);
            ref.read(playerSongProvider.notifier).setSong(song);
            ref.read(isPlayerVisibleProvider.notifier).state = true;
            await handler.loadPlaylist(songs, initialIndex: index);
            if (context.mounted) context.go(AppRoutes.player);
          },
          onFavoriteTap: () =>
              ref.read(songsProvider.notifier).toggleFavorite(song.id),
        );
      },
    );
  }
}
