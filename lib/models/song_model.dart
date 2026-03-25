

/// Represents a single audio track in the library.
class SongModel {
  final String id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int durationMs;
  final String? albumArt;
  final bool isVideo;
  bool isFavorite;

  SongModel({
    required this.id,
    required this.path,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.genre = 'Unknown Genre',
    this.durationMs = 0,
    this.albumArt,
    this.isVideo = false,
    this.isFavorite = false,
  });

  // Convert to/from a Map for DB storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration_ms': durationMs,
      'album_art': albumArt,
      'is_video': isVideo ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as String,
      path: map['path'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      genre: map['genre'] as String? ?? 'Unknown Genre',
      durationMs: map['duration_ms'] as int? ?? 0,
      albumArt: map['album_art'] as String?,
      isVideo: (map['is_video'] as int? ?? 0) == 1,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }

  SongModel copyWith({
    String? id,
    String? path,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? durationMs,
    String? albumArt,
    bool? isVideo,
    bool? isFavorite,
  }) {
    return SongModel(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      albumArt: albumArt ?? this.albumArt,
      isVideo: isVideo ?? this.isVideo,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
