/// Represents a user-created playlist.
class PlaylistModel {
  final String id;
  String name;
  final List<String> songIds; // Ordered list of Song IDs
  final DateTime createdAt;

  PlaylistModel({
    required this.id,
    required this.name,
    List<String>? songIds,
    DateTime? createdAt,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  PlaylistModel copyWith({String? id, String? name, List<String>? songIds}) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? List.from(this.songIds),
      createdAt: createdAt,
    );
  }
}
