import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/song_model.dart';
import 'metadata_service.dart';

class AudioExtractorService {
  final _uuid = const Uuid();

  Future<SongModel?> extractAudio(SongModel videoAsset) async {
    try {
      if (!videoAsset.isVideo) return videoAsset;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String uniqueId = _uuid.v4();
      final String baseName =
          p.basenameWithoutExtension(videoAsset.title);
      final String outputPath =
          p.join(appDocDir.path, 'extracted', '$baseName-$uniqueId.mp3');

      // Ensure the directory exists
      await Directory(p.dirname(outputPath)).create(recursive: true);

      // -vn: no video, -q:a 0: highest VBR quality
      final String command =
          '-i "${videoAsset.path}" -vn -q:a 0 -map a "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final newId = _uuid.v4();
        // Try to read metadata from the resulting MP3
        return MetadataService.extractMetadata(outputPath, newId);
      } else {
        final logs = await session.getAllLogsAsString();
        // ignore: avoid_print
        print('[AudioExtractor] FFmpeg failed – $logs');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AudioExtractor] Error: $e');
      return null;
    }
  }
}
