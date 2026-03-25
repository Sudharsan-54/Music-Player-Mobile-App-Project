import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/file_picker_service.dart';
import '../services/audio_extractor_service.dart';

class AudioProvider extends ChangeNotifier {
  final FilePickerService _filePickerService = FilePickerService();
  final AudioExtractorService _audioExtractorService = AudioExtractorService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<SongModel> _songs = [];
  List<SongModel> get songs => _songs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SongModel? _currentSong;
  SongModel? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  AudioProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  Future<void> pickAndProcessFiles() async {
    _setLoading(true);

    List<SongModel> pickedFiles = await _filePickerService.pickFiles();
    
    for (var file in pickedFiles) {
      if (file.isVideo) {
        // Extract audio from video
        SongModel? extractedAudio = await _audioExtractorService.extractAudio(file);
        if (extractedAudio != null) {
          _addSong(extractedAudio);
        }
      } else {
        // Add direct audio files
        _addSong(file);
      }
    }

    _setLoading(false);
  }

  void _addSong(SongModel song) {
    if (!_songs.contains(song)) {
      _songs.add(song);
      notifyListeners();
    }
  }

  Future<void> playSong(SongModel song) async {
    try {
      if (_currentSong == song && _isPlaying) {
        await pauseSong();
        return;
      }
      
      if (_currentSong != song) {
         await _audioPlayer.setFilePath(song.path);
         _currentSong = song;
      }
      
      await _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> pauseSong() async {
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> stopSong() async {
    await _audioPlayer.stop();
    _currentSong = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
