import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/song_model.dart';
import 'metadata_service.dart';
import 'package:uuid/uuid.dart';

class FilePickerService {
  final _uuid = const Uuid();

  static const _audioExtensions = ['mp3', 'flac', 'm4a', 'aac', 'wav', 'ogg'];
  static const _videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'webm'];

  Future<List<SongModel>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [..._audioExtensions, ..._videoExtensions],
        allowMultiple: true,
        withData: kIsWeb, // On web we need the bytes directly
      );

      if (result == null) return [];

      final songs = <SongModel>[];
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;

        final ext = p.extension(path).replaceAll('.', '').toLowerCase();
        final isVideo = _videoExtensions.contains(ext);

        // For audio files, extract metadata immediately
        SongModel song;
        if (!isVideo) {
          song = await MetadataService.extractMetadata(path, _uuid.v4());
        } else {
          song = SongModel(
            id: _uuid.v4(),
            path: path,
            title: p.basenameWithoutExtension(path),
            isVideo: true,
          );
        }
        songs.add(song);
      }
      return songs;
    } catch (e) {
      return [];
    }
  }
}
