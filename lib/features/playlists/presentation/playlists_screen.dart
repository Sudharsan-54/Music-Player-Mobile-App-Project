import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/playlist_model.dart';

/// Playlists screen – create, rename, delete, and view playlists.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: playlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (playlists) => playlists.isEmpty
            ? _emptyState(context, ref)
            : _PlaylistList(playlists: playlists),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.queue_music_outlined,
              size: 80,
              color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No playlists yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Tap + to create one',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New Playlist'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist name',
            hintText: 'My awesome playlist',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(playlistsProvider.notifier).createPlaylist(name);
    }
  }
}

class _PlaylistList extends ConsumerWidget {
  final List<PlaylistModel> playlists;
  const _PlaylistList({required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return ListTile(
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.queue_music_rounded,
                color: AppTheme.primaryColor),
          ),
          title: Text(playlist.name,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600)),
          subtitle: Text('${playlist.songIds.length} songs',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          trailing: PopupMenuButton<String>(
            onSelected: (action) =>
                _handleAction(context, ref, action, playlist),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref,
      String action, PlaylistModel playlist) async {
    if (action == 'delete') {
      ref.read(playlistsProvider.notifier).deletePlaylist(playlist.id);
    } else if (action == 'rename') {
      final controller =
          TextEditingController(text: playlist.name);
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration:
                const InputDecoration(labelText: 'New name'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Save')),
          ],
        ),
      );
      if (newName != null && newName.isNotEmpty) {
        ref
            .read(playlistsProvider.notifier)
            .renamePlaylist(playlist.id, newName);
      }
    }
  }
}
