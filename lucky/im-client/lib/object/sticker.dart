class Sticker {
  final int id;
  final int collectionId;
  final String name;
  final String url;
  final int ranking;
  final int totalFav;
  final int creatorId;
  final int timeCreated;
  final int timeUpdated;
  final int timeDeleted;

  Sticker({
    required this.id,
    required this.collectionId,
    required this.name,
    required this.url,
    required this.ranking,
    required this.totalFav,
    required this.creatorId,
    required this.timeCreated,
    required this.timeUpdated,
    required this.timeDeleted,
  });

  factory Sticker.fromJson(Map<String, dynamic> json) => Sticker(
        id: json["id"] ?? 0,
        collectionId: json["collection_id"] ?? 0,
        name: json["name"] ?? '',
        url: json["path"] ?? '',
        ranking: json["ranking"] ?? 0,
        totalFav: json["total_favourite"] ?? 0,
        creatorId: json["creator_id"] ?? 0,
        timeCreated: json["created_at"] ?? 0,
        timeUpdated: json["updated_at"] ?? 0,
        timeDeleted: json["deleted_at"] ?? 0,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection_id': collectionId,
      'name': name,
      'path': url,
      'ranking': ranking,
      'total_favourite': totalFav,
      'creator_id': creatorId,
      'created_at': timeCreated,
      'updated_at': timeUpdated,
      'deleted_at': timeDeleted,
    };
  }
}
