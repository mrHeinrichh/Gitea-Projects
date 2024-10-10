import 'dart:convert';

/// id : 1
/// channel_group_id : 1
/// name : "test1"
/// path : "sticker/gif/giphy.gif"
/// resize_paths : ["sticker/gif/giphy_128.gif","sticker/gif/giphy_64.gif"]
/// image_size : ""
/// tags : ["cat"]
/// created_at : 1715761178
/// updated_at : 1715776185
/// deleted_at : 0

Gifs stickerGifEntityFromJson(String str) => Gifs.fromJson(json.decode(str));

String gifsToJson(Gifs data) => json.encode(data.toJson());

class Gifs {
  Gifs({
    num? id,
    num? channelGroupId,
    String? name,
    String? path,
    List<String>? resizePaths,
    String? imageSize,
    num? width,
    num? height,
    List<String>? tags,
    num? createdAt,
    num? updatedAt,
    num? deletedAt,
  })  : _id = id ?? 0,
        _channelGroupId = channelGroupId ?? 0,
        _name = name ?? '',
        _path = path ?? '',
        _resizePaths = resizePaths ?? <String>[],
        _imageSize = imageSize ?? '',
        _width = width ?? 0,
        _height = height ?? 0,
        _tags = tags ?? <String>[],
        _createdAt = createdAt ?? 0,
        _updatedAt = updatedAt ?? 0,
        _deletedAt = deletedAt ?? 0;

  factory Gifs.fromJson(Map<String, dynamic> json) {
    final imageSize = json['image_size'];

    int width = 0;
    int height = 0;

    if (imageSize != null && imageSize is String && imageSize.isNotEmpty) {
      final regex = RegExp(r'^\d+x\d+$');
      if (regex.hasMatch(imageSize) == true) {
        final sizeStrings = imageSize.split("x");
        width = int.parse(sizeStrings.first);
        height = int.parse(sizeStrings.last);
      }
    }

    return Gifs(
      id: json['id'],
      channelGroupId: json['channelgroupid'],
      name: json['name'],
      path: json['path'],
      resizePaths: json['resizepaths'] != null
          ? (json['resizepaths'] as List).map((e) => '$e').toList()
          : <String>[],
      imageSize: imageSize,
      width: width,
      height: height,
      tags: json['tags'] != null
          ? (json['tags'] as List).map((e) => '$e').toList()
          : <String>[],
      createdAt: json['createdat'],
      updatedAt: json['updatedat'],
      deletedAt: json['deletedat'],
    );
  }

  final num _id;
  final num _channelGroupId;
  final String _name;
  final String _path;
  final List<String> _resizePaths;
  final String _imageSize;
  final num _width;
  final num _height;
  final List<String> _tags;
  final num _createdAt;
  final num _updatedAt;
  final num _deletedAt;

  Gifs copyWith({
    num? id,
    num? channelGroupId,
    String? name,
    String? path,
    List<String>? resizePaths,
    String? imageSize,
    num? width,
    num? height,
    List<String>? tags,
    num? createdAt,
    num? updatedAt,
    num? deletedAt,
  }) =>
      Gifs(
        id: id ?? _id,
        channelGroupId: channelGroupId ?? _channelGroupId,
        name: name ?? _name,
        path: path ?? _path,
        resizePaths: resizePaths ?? _resizePaths,
        imageSize: imageSize ?? _imageSize,
        width: width ?? _width,
        height: width ?? _height,
        tags: tags ?? _tags,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        deletedAt: deletedAt ?? _deletedAt,
      );

  num get id => _id;

  num get channelGroupId => _channelGroupId;

  String get name => _name;

  String get path => _path;

  List<String> get resizePaths => _resizePaths;

  String get imageSize => _imageSize;

  num get width => _width;

  num get height => _height;

  List<String> get tags => _tags;

  num get createdAt => _createdAt;

  num get updatedAt => _updatedAt;

  num get deletedAt => _deletedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['channel_group_id'] = _channelGroupId;
    map['name'] = _name;
    map['path'] = _path;
    map['resize_paths'] = _resizePaths;
    map['image_size'] = _imageSize;
    map['width'] = _width;
    map['height'] = _height;
    map['tags'] = _tags;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['deleted_at'] = _deletedAt;
    return map;
  }
}
