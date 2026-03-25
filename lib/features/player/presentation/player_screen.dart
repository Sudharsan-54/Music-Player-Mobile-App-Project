import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_providers.dart';
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

    if (song == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(AppRoutes.library));
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
                  child: _AlbumArt(albumArt: song.albumArt, isPlaying: isPlaying),
                ),
                const SizedBox(height: 24),
                // ── Song Info ──
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
                                      color: AppTheme.textPrimary),
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
                const SizedBox(height: 12),
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
                      onTap: () => isPlaying ? handler.pause() : handler.play(),
                    ),
                    _ControlButton(
                      icon: Icons.skip_next_rounded,
                      size: 36,
                      onTap: () => handler.skipToNext(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
}

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
          isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.primaryColor, fontSize: 11)),
    );
  }
}
