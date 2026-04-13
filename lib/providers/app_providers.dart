import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../core/services/music_handler.dart';
import '../database/app_database.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../services/file_picker_service.dart';
import '../services/audio_extractor_service.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────
//  Core Service Providers
// ─────────────────────────────────────────────────

/// Provides the singleton [AppDatabase].
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

/// Provides the initialized [MusicHandler] (audio_service background handler).
final musicHandlerProvider = Provider<MusicHandler>((ref) {
  throw UnimplementedError(
      'musicHandlerProvider must be overridden in ProviderScope.overrides');
});

// ─────────────────────────────────────────────────
//  Library Providers
// ─────────────────────────────────────────────────

/// Async provider that loads all songs from the database.
final songsProvider =
    AsyncNotifierProvider<SongsNotifier, List<SongModel>>(SongsNotifier.new);

class SongsNotifier extends AsyncNotifier<List<SongModel>> {
  @override
  Future<List<SongModel>> build() async {
    final db = ref.read(databaseProvider);
    return db.getAllSongs();
  }

  Future<void> importFiles() async {
    final filePicker = FilePickerService();
    final extractor = AudioExtractorService();
    final db = ref.read(databaseProvider);

    state = const AsyncLoading();

    final picked = await filePicker.pickFiles();
    final processed = <SongModel>[];

    for (final song in picked) {
      if (song.isVideo) {
        final extracted = await extractor.extractAudio(song);
        if (extracted != null) processed.add(extracted);
      } else {
        processed.add(song);
      }
      // Yield to the event loop so the UI (spinner) doesn't freeze and cause an ANR
      await Future.delayed(const Duration(milliseconds: 50));
    }

    for (final song in processed) {
      await db.insertSong(song);
      // Yield during heavy SQLite BLOB inserts
      await Future.delayed(const Duration(milliseconds: 10));
    }

    state = AsyncData(await db.getAllSongs());

  }

  Future<void> toggleFavorite(String songId) async {
    final db = ref.read(databaseProvider);
    final current = state.valueOrNull ?? [];
    final song = current.firstWhere((s) => s.id == songId);
    final newFav = !song.isFavorite;
    await db.toggleFavorite(songId, newFav);

    // Update in-memory state
    state = AsyncData(current.map((s) {
      if (s.id == songId) return s.copyWith(isFavorite: newFav);
      return s;
    }).toList());
  }

  Future<void> deleteSong(String songId) async {
    final db = ref.read(databaseProvider);
    await db.deleteSong(songId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != songId).toList());
  }
}

// ─────────────────────────────────────────────────
//  Favorites Provider  (derived)
// ─────────────────────────────────────────────────

final favoritesProvider = Provider<AsyncValue<List<SongModel>>>((ref) {
  final songs = ref.watch(songsProvider);
  return songs.whenData((list) => list.where((s) => s.isFavorite).toList());
});

// ─────────────────────────────────────────────────
//  Playlist Providers
// ─────────────────────────────────────────────────

final playlistsProvider =
    AsyncNotifierProvider<PlaylistsNotifier, List<PlaylistModel>>(
        PlaylistsNotifier.new);

class PlaylistsNotifier extends AsyncNotifier<List<PlaylistModel>> {
  final _uuid = const Uuid();

  @override
  Future<List<PlaylistModel>> build() async {
    final db = ref.read(databaseProvider);
    return db.getAllPlaylists();
  }

  Future<void> createPlaylist(String name) async {
    final db = ref.read(databaseProvider);
    final playlist = PlaylistModel(id: _uuid.v4(), name: name);
    await db.insertPlaylist(playlist);
    state = AsyncData([...state.valueOrNull ?? [], playlist]);
  }

  Future<void> deletePlaylist(String id) async {
    final db = ref.read(databaseProvider);
    await db.deletePlaylist(id);
    state = AsyncData(
        (state.valueOrNull ?? []).where((p) => p.id != id).toList());
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final db = ref.read(databaseProvider);
    await db.renamePlaylist(id, newName);
    state = AsyncData((state.valueOrNull ?? []).map((p) {
      if (p.id == id) return p.copyWith(name: newName);
      return p;
    }).toList());
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final db = ref.read(databaseProvider);
    final playlists = state.valueOrNull ?? [];
    final playlist = playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.songIds.contains(songId)) {
      await db.addSongToPlaylist(
          playlistId, songId, playlist.songIds.length);
      state = AsyncData(playlists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(songIds: [...p.songIds, songId]);
        }
        return p;
      }).toList());
    }
  }

  Future<void> removeSongFromPlaylist(
      String playlistId, String songId) async {
    final db = ref.read(databaseProvider);
    await db.removeSongFromPlaylist(playlistId, songId);
    state = AsyncData((state.valueOrNull ?? []).map((p) {
      if (p.id == playlistId) {
        return p.copyWith(
            songIds: p.songIds.where((id) => id != songId).toList());
      }
      return p;
    }).toList());
  }
}

// ─────────────────────────────────────────────────
//  Player State Provider
// ─────────────────────────────────────────────────

/// Stores which song is currently loaded / what the user tapped.
final playerSongProvider =
    StateNotifierProvider<PlayerSongNotifier, SongModel?>(
        (ref) => PlayerSongNotifier());

class PlayerSongNotifier extends StateNotifier<SongModel?> {
  PlayerSongNotifier() : super(null);
  void setSong(SongModel song) => state = song;
  void clear() => state = null;
}

/// Whether the mini-player / full-screen player should be visible.
final isPlayerVisibleProvider = StateProvider<bool>((ref) => false);

/// Streams the current playback state from audio_service.
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.read(musicHandlerProvider);
  return handler.playbackState.stream;
});

/// Streams the current media item from audio_service.
final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.read(musicHandlerProvider);
  return handler.mediaItem.stream;
});

/// Streams the current playback position.
final positionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.read(musicHandlerProvider);
  return handler.positionStream;
});

/// Streams the current track duration.
final durationProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.read(musicHandlerProvider);
  return handler.durationStream;
});

// ─────────────────────────────────────────────────
//  Shuffle / Repeat Providers
// ─────────────────────────────────────────────────

/// Tracks whether shuffle is enabled (mirrors [MusicHandler.shuffleEnabled]).
final shuffleProvider = StateProvider<bool>((ref) => false);

/// Tracks the current repeat mode (mirrors [MusicHandler.repeatMode]).
final repeatModeProvider = StateProvider<AudioRepeatMode>((ref) => AudioRepeatMode.off);

// ─────────────────────────────────────────────────
//  Search & Sort Providers
// ─────────────────────────────────────────────────

enum SortMode { titleAsc, artistAsc, durationAsc, dateAdded }

/// Current search query (empty = no filter).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Current sort mode for the library.
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.titleAsc);

/// Derived list: applies search + sort to [songsProvider].
final filteredSongsProvider = Provider<AsyncValue<List<SongModel>>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(sortModeProvider);

  return songsAsync.whenData((songs) {
    // 1. Filter
    var list = query.isEmpty
        ? songs
        : songs.where((s) {
            return s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query) ||
                s.album.toLowerCase().contains(query);
          }).toList();

    // 2. Sort
    list = List.of(list);
    switch (sort) {
      case SortMode.titleAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
      case SortMode.artistAsc:
        list.sort((a, b) => a.artist.compareTo(b.artist));
      case SortMode.durationAsc:
        list.sort((a, b) => a.durationMs.compareTo(b.durationMs));
      case SortMode.dateAdded:
        break; // DB already returns insertion order
    }
    return list;
  });
});

// ─────────────────────────────────────────────────
//  Sleep Timer Provider
// ─────────────────────────────────────────────────

/// Holds the *remaining* duration of the sleep timer, or null when inactive.
class SleepTimerNotifier extends StateNotifier<Duration?> {
  SleepTimerNotifier(this._ref) : super(null);

  final Ref _ref;
  Timer? _ticker;

  /// Start a sleep timer for [duration]. Replaces any existing timer.
  void start(Duration duration) {
    _ticker?.cancel();
    state = duration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state;
      if (remaining == null || remaining.inSeconds <= 1) {
        _ref.read(musicHandlerProvider).pause();
        cancel();
        return;
      }
      state = remaining - const Duration(seconds: 1);
    });
  }

  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    state = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, Duration?>(
        (ref) => SleepTimerNotifier(ref));
