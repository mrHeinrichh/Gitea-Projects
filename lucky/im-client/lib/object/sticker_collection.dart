import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/object/sticker_creator.dart';

class StickerCollection {
  CollectionDescription collection;
  StickerCreator creator;
  List<Sticker> stickerList;

  StickerCollection({
    required this.collection,
    required this.creator,
    required this.stickerList,
  });

  factory StickerCollection.fromJson(Map<String, dynamic> json) =>
      StickerCollection(
        collection: CollectionDescription.fromJson(json["collection"]),
        creator: StickerCreator.fromJson(json["creator"]),
        stickerList: json['stickers']
            .map<Sticker>((item) => Sticker.fromJson(item))
            .toList(),
      );
}

///贴纸合集的详情
class CollectionDescription {
  int collectionId;
  String name;
  String thumbnail;
  String description;
  int ranking;
  int totalDownload;
  int creatorID;
  int dateCreated;
  int dateUpdated;
  int dateDeleted;

  CollectionDescription({
    this.collectionId = 0,
    required this.name,
    required this.thumbnail,
    this.description = '',
    this.ranking = 0,
    this.totalDownload = 0,
    this.creatorID = 0,
    this.dateCreated = 0,
    this.dateUpdated = 0,
    this.dateDeleted = 0,
  });

  factory CollectionDescription.fromJson(Map<String, dynamic> json) =>
      CollectionDescription(
        collectionId: json["id"] ?? '',
        name: json["name"] ?? '',
        thumbnail: json["icon_path"] ?? '',
        description: json["description"] ?? '',
        ranking: json["ranking"] ?? '',
        totalDownload: json["total_download"] ?? '',
        creatorID: json["creator_id"] ?? '',
        dateCreated: json["created_at"] ?? '',
        dateUpdated: json["updated_at"] ?? '',
        dateDeleted: json["deleted_at"] ?? '',
      );
}
