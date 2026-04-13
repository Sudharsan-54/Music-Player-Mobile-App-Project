import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_providers.dart';
import '../../../core/services/music_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routing/app_router.dart';

/// Full-screen Now Playing view.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerSongProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);
    final handler = ref.read(musicHandlerProvider);
    final shuffle = ref.watch(shuffleProvider);
    final repeat = ref.watch(repeatModeProvider);
    final sleepRemaining = ref.watch(sleepTimerProvider);

    if (song == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go(AppRoutes.library));
      return const SizedBox.shrink();
    }

    final isPlaying = playbackAsync.valueOrNull?.playing ?? false;
    final position = positionAsync.valueOrNull ?? Duration.zero;
    final duration = durationAsync.valueOrNull ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => context.go(AppRoutes.library),
        ),
        title: const Text('Now Playing',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        actions: [
          // Sleep timer action
          _SleepTimerAction(remaining: sleepRemaining),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.surfaceElevated, AppTheme.surfaceDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // ── Album Art ──
                Expanded(
                  flex: 5,
                  child: _AlbumArt(
                      albumArt: song.albumArt, isPlaying: isPlaying),
                ),
                const SizedBox(height: 24),
                // ── Song Info + Favorite ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(song.artist,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        song.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: song.isFavorite
                            ? AppTheme.accentColor
                            : AppTheme.textSecondary,
                      ),
                      onPressed: () => ref
                          .read(songsProvider.notifier)
                          .toggleFavorite(song.id),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Progress Slider ──
                Column(
                  children: [
                    Slider(
                      value: progress,
                      onChanged: (v) {
                        final targetMs =
                            (v * duration.inMilliseconds).round();
                        handler.seek(Duration(milliseconds: targetMs));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                          Text(_formatDuration(duration),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Shuffle / Repeat row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: shuffle
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        size: 24,
                      ),
                      tooltip: shuffle ? 'Shuffle on' : 'Shuffle off',
                      onPressed: () async {
                        await handler.toggleShuffle();
                        ref.read(shuffleProvider.notifier).state =
                            handler.shuffleEnabled;
                      },
                    ),
                    // Repeat
                    IconButton(
                      icon: Icon(
                        repeat == AudioRepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: repeat != AudioRepeatMode.off
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        size: 24,
                      ),
                      tooltip: repeat == AudioRepeatMode.off
                          ? 'Repeat off'
                          : repeat == AudioRepeatMode.all
                              ? 'Repeat all'
                              : 'Repeat one',
                      onPressed: () async {
                        await handler.cycleRepeatMode();
                        ref.read(repeatModeProvider.notifier).state =
                            handler.repeatMode;
                      },
                    ),
                    // Queue
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded,
                          color: AppTheme.textSecondary, size: 24),
                      tooltip: 'Up next',
                      onPressed: () => _showQueueSheet(context, ref, handler),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // ── Playback Controls ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: Icons.skip_previous_rounded,
                      size: 36,
                      onTap: () => handler.skipToPrevious(),
                    ),
                    _PlayPauseButton(
                      isPlaying: isPlaying,
                      onTap: () =>
                          isPlaying ? handler.pause() : handler.play(),
                    ),
                    _ControlButton(
                      icon: Icons.skip_next_rounded,
                      size: 36,
                      onTap: () => handler.skipToNext(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Genre / Album Tag ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Tag(label: song.genre),
                    const SizedBox(width: 8),
                    _Tag(label: song.album),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Sleep Timer Bottom Sheet ──────────────────────────────────────────────

  // ── Now Playing Queue Bottom Sheet ────────────────────────────────────────

  void _showQueueSheet(
      BuildContext context, WidgetRef ref, MusicHandler handler) {
    final queue = handler.queue.value;
    final currentIdx =
        handler.playbackState.value.queueIndex ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Up Next',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${queue.length} songs',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: queue.isEmpty
                  ? const Center(
                      child: Text('Queue is empty',
                          style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: queue.length,
                      itemBuilder: (_, i) {
                        final item = queue[i];
                        final isCurrent = i == currentIdx;
                        return ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isCurrent
                                ? const Icon(Icons.equalizer_rounded,
                                    color: AppTheme.primaryColor, size: 18)
                                : Text('${i + 1}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.artist ?? '',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            handler.skipToQueueItem(i);
                            // Update playerSongProvider
                            final songs = ref
                                .read(songsProvider)
                                .valueOrNull;
                            if (songs != null) {
                              final match = songs.where(
                                  (s) => s.path == item.id);
                              if (match.isNotEmpty) {
                                ref
                                    .read(playerSongProvider.notifier)
                                    .setSong(match.first);
                              }
                            }
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sleep Timer AppBar action widget ─────────────────────────────────────────

class _SleepTimerAction extends ConsumerWidget {
  final Duration? remaining;
  const _SleepTimerAction({required this.remaining});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = remaining != null
        ? '${remaining!.inMinutes.toString().padLeft(2, '0')}:'
            '${(remaining!.inSeconds % 60).toString().padLeft(2, '0')}'
        : null;

    return GestureDetector(
      onTap: () => _PlayerScreenHelper.showSleepTimer(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              remaining != null
                  ? Icons.timer_rounded
                  : Icons.timer_outlined,
              color: remaining != null
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
              size: 22,
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper to call bottom-sheet logic from a ConsumerWidget action
class _PlayerScreenHelper {
  static void showSleepTimer(BuildContext context, WidgetRef ref) {
    final timerNotifier = ref.read(sleepTimerProvider.notifier);
    final presets = {
      '15 min': const Duration(minutes: 15),
      '30 min': const Duration(minutes: 30),
      '45 min': const Duration(minutes: 45),
      '1 hour': const Duration(hours: 1),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sleep Timer',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...presets.entries.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.key,
                      style:
                          const TextStyle(color: AppTheme.textPrimary)),
                  trailing: const Icon(Icons.timer_outlined,
                      color: AppTheme.primaryColor),
                  onTap: () {
                    timerNotifier.start(e.value);
                    Navigator.pop(ctx);
                  },
                )),
            const Divider(color: AppTheme.textSecondary),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cancel timer',
                  style: TextStyle(color: Colors.redAccent)),
              trailing: const Icon(Icons.timer_off_outlined,
                  color: Colors.redAccent),
              onTap: () {
                timerNotifier.cancel();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AlbumArt extends StatefulWidget {
  final String? albumArt;
  final bool isPlaying;
  const _AlbumArt({required this.albumArt, required this.isPlaying});

  @override
  State<_AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<_AlbumArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    if (!widget.isPlaying) _ctrl.stop();
  }

  @override
  void didUpdateWidget(_AlbumArt old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) _ctrl.repeat();
    if (!widget.isPlaying && _ctrl.isAnimating) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipOval(
          child: widget.albumArt != null
              ? Image.file(File(widget.albumArt!),
                  width: 260, height: 260, fit: BoxFit.cover)
              : Container(
                  width: 260,
                  height: 260,
                  color: AppTheme.surfaceElevated,
                  child: const Icon(Icons.music_note_rounded,
                      size: 80, color: AppTheme.textSecondary),
                ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _ControlButton(
      {required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppTheme.textPrimary, size: size),
      onPressed: onTap,
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style:
              const TextStyle(color: AppTheme.primaryColor, fontSize: 11)),
    );
  }
}
