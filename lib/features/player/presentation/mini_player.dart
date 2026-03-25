import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_providers.dart';
import '../../../routing/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// A persistent mini-player that appears above the bottom nav bar.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final currentSong = ref.watch(playerSongProvider);

    if (currentSong == null) return const SizedBox.shrink();

    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final mediaItem = mediaItemAsync.valueOrNull;

    return GestureDetector(
      onTap: () => context.go(AppRoutes.player),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Album art placeholder
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: currentSong.albumArt != null
                    ? Image.file(File(currentSong.albumArt!),
                        fit: BoxFit.cover)
                    : const Icon(Icons.music_note_rounded,
                        color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            // Title + artist
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaItem?.title ?? currentSong.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    mediaItem?.artist ?? currentSong.artist,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Controls
            _MiniControl(
              icon: Icons.skip_previous_rounded,
              onTap: () => ref.read(musicHandlerProvider).skipToPrevious(),
            ),
            _MiniControl(
              icon: isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 36,
              color: AppTheme.primaryColor,
              onTap: () {
                final handler = ref.read(musicHandlerProvider);
                isPlaying ? handler.pause() : handler.play();
              },
            ),
            _MiniControl(
              icon: Icons.skip_next_rounded,
              onTap: () => ref.read(musicHandlerProvider).skipToNext(),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _MiniControl({
    required this.icon,
    required this.onTap,
    this.size = 28,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size, color: color),
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}
