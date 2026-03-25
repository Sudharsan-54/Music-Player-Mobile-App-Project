import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

/// Singleton wrapper around the SQLite database for the music library.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initialize();
    return _db!;
  }

  Future<Database> _initialize() async {
    // On Windows/Linux use sqflite_common_ffi
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'jazz_music.db');

    return openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop and recreate explicitly to avoid complicated structural blob migrations during alpha
        await db.execute('DROP TABLE IF EXISTS playlist_songs');
        await db.execute('DROP TABLE IF EXISTS playlists');
        await db.execute('DROP TABLE IF EXISTS songs');
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        genre TEXT,
        duration_ms INTEGER DEFAULT 0,
        album_art TEXT,
        is_video INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
  }

  // ──────────────── Song Operations ────────────────

  Future<void> insertSong(SongModel song) async {
    final db = await database;
    await db.insert('songs', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SongModel>> getAllSongs() async {
    final db = await database;
    final maps = await db.query('songs', orderBy: 'title ASC');
    return maps.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getFavoriteSongs() async {
    final db = await database;
    final maps = await db.query('songs',
        where: 'is_favorite = ?', whereArgs: [1], orderBy: 'title ASC');
    return maps.map(SongModel.fromMap).toList();
  }

  Future<void> updateSong(SongModel song) async {
    final db = await database;
    await db.update('songs', song.toMap(),
        where: 'id = ?', whereArgs: [song.id]);
  }

  Future<void> deleteSong(String id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update('songs', {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────── Playlist Operations ────────────────

  Future<void> insertPlaylist(PlaylistModel playlist) async {
    final db = await database;
    await db.insert('playlists', playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PlaylistModel>> getAllPlaylists() async {
    final db = await database;
    final maps = await db.query('playlists', orderBy: 'created_at DESC');
    final playlists = <PlaylistModel>[];
    for (final map in maps) {
      final playlist = PlaylistModel.fromMap(map);
      final songIds = await getPlaylistSongIds(playlist.id);
      playlist.songIds.addAll(songIds);
      playlists.add(playlist);
    }
    return playlists;
  }

  Future<List<String>> getPlaylistSongIds(String playlistId) async {
    final db = await database;
    final maps = await db.query('playlist_songs',
        columns: ['song_id'],
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
        orderBy: 'position ASC');
    return maps.map((m) => m['song_id'] as String).toList();
  }

  Future<void> addSongToPlaylist(
      String playlistId, String songId, int position) async {
    final db = await database;
    await db.insert(
      'playlist_songs',
      {'playlist_id': playlistId, 'song_id': songId, 'position': position},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeSongFromPlaylist(
      String playlistId, String songId) async {
    final db = await database;
    await db.delete('playlist_songs',
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId]);
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
    await db.delete('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [id]);
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final db = await database;
    await db.update('playlists', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
