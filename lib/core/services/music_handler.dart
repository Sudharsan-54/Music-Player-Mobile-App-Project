import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/song_model.dart';

/// Repeat mode for the player.
enum AudioRepeatMode { off, all, one }

/// Converts our [SongModel] to an [audio_service] MediaItem.
MediaItem songToMediaItem(SongModel song) {
  return MediaItem(
    id: song.path,
    title: song.title,
    artist: song.artist,
    album: song.album,
    duration: Duration(milliseconds: song.durationMs),
  );
}

/// The background audio handler that integrates just_audio with
/// the OS media notification system via audio_service.
class MusicHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // ── Shuffle / Repeat state ──
  bool _shuffleEnabled = false;
  AudioRepeatMode _repeatMode = AudioRepeatMode.off;

  bool get shuffleEnabled => _shuffleEnabled;
  AudioRepeatMode get repeatMode => _repeatMode;

  MusicHandler() {
    _initStreams();
  }

  void _initStreams() {
    _player.playbackEventStream.listen(_broadcastState);

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });

    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null && duration != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  /// Load a list of songs into the queue and start playing from [initialIndex].
  Future<void> loadPlaylist(List<SongModel> songs, {int initialIndex = 0}) async {
    final items = songs.map(songToMediaItem).toList();
    queue.add(items);

    final audioSources = songs
        .map((s) => AudioSource.uri(Uri.file(s.path)))
        .toList();

    await _player.setAudioSources(
      audioSources,
      initialIndex: initialIndex,
    );

    // Emit the current media item
    if (items.isNotEmpty) {
      mediaItem.add(items[initialIndex]);
    }

    await play();
  }

  /// Play a single song immediately.
  Future<void> playSong(SongModel song) async {
    mediaItem.add(songToMediaItem(song));
    await _player.setFilePath(song.path);
    await play();
  }

  // ──────────────── BaseAudioHandler overrides ────────────────

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      final idx = _player.currentIndex ?? 0;
      final q = queue.value;
      if (idx < q.length) mediaItem.add(q[idx]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // If more than 3 seconds in, restart; otherwise go to previous
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
      final idx = _player.currentIndex ?? 0;
      final q = queue.value;
      if (idx < q.length) mediaItem.add(q[idx]);
    }
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    ));
  }

  // ──────────────── Shuffle / Repeat ────────────────

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await _player.setShuffleModeEnabled(_shuffleEnabled);
    _broadcastState(_player.playbackEvent);
  }

  Future<void> cycleRepeatMode() async {
    _repeatMode = switch (_repeatMode) {
      AudioRepeatMode.off => AudioRepeatMode.all,
      AudioRepeatMode.all => AudioRepeatMode.one,
      AudioRepeatMode.one => AudioRepeatMode.off,
    };
    final loopMode = switch (_repeatMode) {
      AudioRepeatMode.off => LoopMode.off,
      AudioRepeatMode.all => LoopMode.all,
      AudioRepeatMode.one => LoopMode.one,
    };
    await _player.setLoopMode(loopMode);
    _broadcastState(_player.playbackEvent);
  }

  // Expose streams for the UI
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  bool get isPlaying => _player.playing;

  @override
  Future<void> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      await super.stop();
    }
  }
}
