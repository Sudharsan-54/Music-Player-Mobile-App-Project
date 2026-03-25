import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/song_model.dart';

/// Extracts ID3 / metadata tags from audio files.
class MetadataService {
  MetadataService._();

  static Future<SongModel> extractMetadata(String path, String id) async {
    try {
      // ignore: avoid_print
      print('[MetadataService] Reading tags for $path');
      
      // Aggressive timeout to prevent FFI / MethodChannel native freezes on corrupted tags
      final tag = await AudioTags.read(path).timeout(const Duration(seconds: 3));
      
      String? coverPath;
      if (tag?.pictures.isNotEmpty == true) {
        final bytes = tag!.pictures.first.bytes;
        final docDir = await getApplicationDocumentsDirectory();
        final artDir = Directory(p.join(docDir.path, 'album_arts'));
        if (!await artDir.exists()) {
          await artDir.create(recursive: true);
        }
        final File file = File(p.join(artDir.path, '$id.jpg'));
        await file.writeAsBytes(bytes);
        coverPath = file.path;
      }

      final song = SongModel(
        id: id,
        path: path,
        title: _orDefault(tag?.title, p.basenameWithoutExtension(path)),
        artist: _orDefault(tag?.trackArtist, 'Unknown Artist'),
        album: _orDefault(tag?.album, 'Unknown Album'),
        genre: _orDefault(tag?.genre, 'Unknown Genre'),
        durationMs: 0, 
        albumArt: coverPath,
        isVideo: false,
      );
      // ignore: avoid_print
      print('[MetadataService] Successfully parsed: ${song.title}');
      return song;
    } catch (e) {
      // ignore: avoid_print
      print('[MetadataService] Failed or timed out reading tags: $e');
      // If tag extraction fails or times out, use file name natively
      return SongModel(
        id: id,
        path: path,
        title: p.basenameWithoutExtension(path),
      );
    }
  }

  static String _orDefault(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }
}
