import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/song_model.dart';
import '../../../core/theme/app_theme.dart';

/// A reusable list tile for a single song.
class SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onFavoriteTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _AlbumArtWidget(albumArt: song.albumArt, size: 50),
      title: Text(
        song.title,
        style: TextStyle(
          color: isPlaying ? AppTheme.primaryColor : AppTheme.textPrimary,
          fontWeight:
              isPlaying ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${song.artist} • ${song.album}',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: song.isFavorite ? AppTheme.accentColor : AppTheme.textSecondary,
              size: 20,
            ),
            onPressed: onFavoriteTap,
          ),
          if (isPlaying)
            const Icon(Icons.equalizer_rounded,
                color: AppTheme.primaryColor, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _AlbumArtWidget extends StatelessWidget {
  final String? albumArt;
  final double size;
  const _AlbumArtWidget({required this.albumArt, required this.size});

  @override
  Widget build(BuildContext context) {
    if (albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(albumArt!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note_rounded,
          color: AppTheme.textSecondary),
    );
  }
}
