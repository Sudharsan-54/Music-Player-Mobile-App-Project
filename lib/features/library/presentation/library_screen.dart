import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../../../routing/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../../models/song_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/player/presentation/song_tile.dart';

/// Main library screen showing all imported songs with search & sort.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredSongsProvider);
    final sortMode = ref.watch(sortModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums…',
                  hintStyle:
                      const TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear,
                        color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                      setState(() => _showSearch = false);
                    },
                  ),
                ),
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
              )
            : const Text('🎵 Jazz Music'),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(
                _showSearch ? Icons.search_off : Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
          // Sort menu
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            initialValue: sortMode,
            onSelected: (mode) =>
                ref.read(sortModeProvider.notifier).state = mode,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: SortMode.titleAsc,
                child: Text('Title (A → Z)'),
              ),
              PopupMenuItem(
                value: SortMode.artistAsc,
                child: Text('Artist (A → Z)'),
              ),
              PopupMenuItem(
                value: SortMode.durationAsc,
                child: Text('Duration (shortest first)'),
              ),
              PopupMenuItem(
                value: SortMode.dateAdded,
                child: Text('Date added'),
              ),
            ],
          ),
          // Import button
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Import Files',
            onPressed: () => context.go(AppRoutes.import),
          ),
        ],
      ),
      body: filteredAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (songs) => songs.isEmpty
            ? _showSearch
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('No songs match your search',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : _EmptyState(onImport: () => context.go(AppRoutes.import))
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
              size: 80,
              color: AppTheme.textSecondary.withValues(alpha: 0.5)),
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
    final currentSong = ref.watch(playerSongProvider);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongTile(
          song: song,
          isPlaying: currentSong?.id == song.id,
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
