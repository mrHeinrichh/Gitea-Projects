import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

/// 搜索类型
const int FavouriteNote = 0; // note
const int FavouriteType = 1; // source
const int FavouriteTag = 2; // tag
const int FavouriteCustom = 3; // custom

/// source类型
const int FavouriteSourceNote = 0; // 笔记
const int FavouriteSourceChat = 1; // 回话
const int FavouriteSourceFriendStory = 2; // 朋友圈
const int FavouriteSourceReel = 3; // 视屏号
const int FavouriteSourceHistory = 4; // 多条聊天室记录

/// 类型
const int FavouriteTypeText = 1; // 文字
const int FavouriteTypeLink = 2; // 链接
const int FavouriteTypeImage = 3; // 媒体
const int FavouriteTypeVideo = 4; // 视频
const int FavouriteTypeAudio = 5; // 语音
const int FavouriteTypeDocument = 6; // 文件
const int FavouriteTypeLocation = 7; // 位置
const int FavouriteTypeDeleted = 8; // 删除
const int FavouriteTypeAlbum = 9; // 相册
const int FavouriteTypeDelta = 10; // 笔记

/// ================================== Enum ================================== ///
enum FavouriteTypType {
  text(FavouriteType, FavouriteTypeText),
  link(FavouriteType, FavouriteTypeLink),
  image(FavouriteType, FavouriteTypeImage),
  video(FavouriteType, FavouriteTypeVideo),
  audio(FavouriteType, FavouriteTypeAudio),
  document(FavouriteType, FavouriteTypeDocument),
  location(FavouriteType, FavouriteTypeLocation),
  deleted(FavouriteType, FavouriteTypeDeleted);

  final int type;
  final int subType;

  const FavouriteTypType(
    this.type,
    this.subType,
  );
}

extension FavouriteTypName on int {
  String get categoryName {
    switch (this) {
      case FavouriteTypeText:
        return localized(textString);
      case FavouriteTypeLink:
        return localized(linkTab);
      case FavouriteTypeImage:
        return localized(mediaTab);
      case FavouriteTypeVideo:
        return localized(video);
      case FavouriteTypeAudio:
        return localized(voiceTab);
      case FavouriteTypeDocument:
        return localized(files);
      case FavouriteTypeLocation:
        return localized(location);
      case FavouriteTypeDeleted:
        return "deleted";
      default:
        return "";
    }
  }
}

enum FavouriteUiType {
  onlyText, // only for [text]
  onlyMedia, // only for [media]
  singleContent, // single for [audio,file,location]
  multipleContent, //multiple for [audio,file,location]
  combination, // 多过一种组合,example:[text + media + audio]
  history; // 聊天记录
}

/// ================================== Model ================================== ///
/// 搜索keyword model
class FavouriteKeywordModel {
  String title;
  int type;
  int? subType;
  bool? isHighlight;

  FavouriteKeywordModel({
    required this.title,
    required this.type,
    this.subType,
    this.isHighlight = false,
  });
}

/// API model
class FavouriteData {
  int? id;
  String? parentId; // match favouriteDetail related id
  List<FavouriteDetailData> content;
  int? createAt;
  int? updatedAt;
  int? deletedAt;
  int? source;
  int? userId;
  int? authorId;
  int isPin;
  int chatTyp;
  List<int> typ;
  List<String> tag;
  int isUploaded;
  List<String>? urls; // for backend

  FavouriteData({
    this.id,
    this.parentId,
    List<FavouriteDetailData>? content,
    this.createAt = 0,
    this.updatedAt = 0,
    this.deletedAt = 0,
    this.source,
    this.userId = 0,
    this.authorId,
    this.isPin = 0,
    this.chatTyp = 0,
    this.isUploaded = 0,
    List<int>? typ,
    List<String>? tag,
    List<String>? urls,
  })  : content = content ?? [],
        typ = typ ?? [],
        tag = tag ?? [];

  factory FavouriteData.fromJson(Map<String, dynamic> json) {
    List<int> typ = [];
    List<String> tag = [];

    if (json['typ'] != null) {
      typ = (json['typ'] is String
          ? List<int>.from(jsonDecode(json['typ']).map((e) => e as int))
          : List<int>.from(json['typ'].map((e) => e as int)));
    }

    if (json['tag'] != null) {
      tag = (json['tag'] is String
          ? List<String>.from(jsonDecode(json['tag']).map((e) => e as String))
          : List<String>.from(json['tag'].map((e) => e as String)));
    }

    return FavouriteData(
      id: json['id'],
      parentId: json['parent_id'],
      content: json['data'] != null && notBlank(json['data'])
          ? (jsonDecode(json['data']) as List)
              .map((e) =>
                  FavouriteDetailData.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
      deletedAt: json['deleted_at'] ?? 0,
      source: json['source'],
      userId: json['user_id'],
      authorId: json['author_id'],
      typ: typ,
      tag: tag,
      isPin: json['is_pin'],
      chatTyp: json['chat_typ'] ?? 0,
      isUploaded: json['is_uploaded'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'data': jsonEncode(content.map((e) => e.toJson()).toList()),
      'created_at': createAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'source': source,
      'user_id': userId,
      'author_id': authorId,
      'is_pin': isPin,
      'chat_typ': chatTyp,
      'is_uploaded': isUploaded,
      'typ': typ,
      'tag': tag,
      'urls': urls,
    };
  }

  bool get isNote => source == FavouriteSourceNote;

  bool get isGroupChat => chatTyp == 2;
}

class FavouriteDetailData {
  int? id;
  String? relatedId;
  String? content;
  int typ;

  // message related
  int? messageId;
  int? sendId;
  int? chatId;
  int? sendTime;

  FavouriteDetailData({
    this.id,
    this.relatedId,
    this.content = "",
    this.messageId,
    this.sendId,
    this.chatId,
    this.sendTime,
    required this.typ,
  });

  factory FavouriteDetailData.fromJson(Map<String, dynamic> json) {
    return FavouriteDetailData(
      id: json['id'],
      relatedId: json['related_id'],
      content: json['content'] ?? "",
      typ: json['typ'],
      messageId: json['messageId'],
      sendId: json['sendId'],
      chatId: json['chatId'],
      sendTime: json['sendTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'related_id': relatedId,
      'content': content,
      'typ': typ,
      'messageId': messageId,
      'sendId': sendId,
      'chatId': chatId,
      'sendTime': sendTime,
    };
  }
}

class FavouriteText {
  String text;
  String? reply;
  int? forwardUserId;
  String? forwardUsername;
  String? translation;

  FavouriteText({
    required this.text,
    this.reply,
    this.forwardUserId,
    this.forwardUsername,
    this.translation,
  });

  factory FavouriteText.fromJson(Map<String, dynamic> json) {
    return FavouriteText(
      text: json['text'] ?? "",
      reply: json['reply'],
      forwardUserId: json['forwardUserId'],
      forwardUsername: json['forwardUsername'],
      translation: json['translation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'reply': reply,
      'forwardUserId': forwardUserId,
      'forwardUsername': forwardUsername,
      'translation': translation,
    };
  }
}

class FavouriteFile {
  String url;
  int length;
  String fileName;
  String suffix;
  String cover;
  // pdf 是否被压缩
  // 0 : 未压缩
  // 1 : 已压缩
  int isEncrypt;
  // 高斯模糊图片
  String? gausPath;

  // 高斯模糊 base64字符
  Uint8List? gausBytes;

  String? reply;
  String? caption;
  int? forwardUserId;
  String? forwardUsername;
  String? translation;

  FavouriteFile({
    required this.url,
    required this.length,
    required this.fileName,
    required this.suffix,
    required this.cover,
    required this.isEncrypt,
    this.reply,
    this.caption,
    this.forwardUserId,
    this.forwardUsername,
    this.translation,
    this.gausPath,
    this.gausBytes,
  });

  factory FavouriteFile.fromJson(Map<String, dynamic> json) {
    String? gausPath;
    Uint8List? gausBytes;
    if (json.containsKey('gausPath') && json['gausPath'] != null) {
      gausPath = json['gausPath'];
    }

    if (json.containsKey('gausBytes') && json['gausBytes'] != null) {
      if (json['gausBytes'] is String) {
        final String gausBase64 = json['gausBytes'];
        gausBytes = base64Decode(gausBase64);
      } else if (json['gausBytes'] is List<int>) {
        gausBytes = Uint8List.fromList(json['gausBytes'] as List<int>);
      }
    }
    return FavouriteFile(
      url: json['url'] ?? "",
      length: json['length'] ?? 0,
      fileName: json['file_name'] ?? "",
      suffix: json['suffix'] ?? "",
      cover: json['cover'] ?? "",
      isEncrypt: json['isEncrypt'] ?? 0,
      reply: json['reply'],
      caption: json['caption'],
      forwardUserId: json['forwardUserId'],
      forwardUsername: json['forwardUsername'],
      translation: json['translation'],
      gausPath: gausPath,
      gausBytes: gausBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'length': length,
      'file_name': fileName,
      'suffix': suffix,
      'cover': cover,
      'isEncrypt': isEncrypt,
      'reply': reply,
      'caption': caption,
      'forwardUserId': forwardUserId,
      'forwardUsername': forwardUsername,
      'translation': translation,
      'gausPath': gausPath,
      'gausBytes': gausBytes,
    };
  }
}

class FavouriteLocation {
  String latitude;
  String longitude;
  String name;
  String address;
  String city;
  String url;
  String filePath;
  int? forwardUserId;
  String? forwardUsername;
  // 高斯模糊图片
  String? gausPath;

  // 高斯模糊 base64字符
  Uint8List? gausBytes;

  FavouriteLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.address,
    required this.city,
    required this.url,
    required this.filePath,
    this.forwardUserId,
    this.forwardUsername,
    this.gausPath,
    this.gausBytes,
  });

  factory FavouriteLocation.fromJson(Map<String, dynamic> json) {
    String? gausPath;
    Uint8List? gausBytes;
    if (json.containsKey('gausPath') && json['gausPath'] != null) {
      gausPath = json['gausPath'];
    }

    if (json.containsKey('gausBytes') && json['gausBytes'] != null) {
      final String gausBase64 = json['gausBytes'];
      gausBytes = base64Decode(gausBase64);
    }
    return FavouriteLocation(
      latitude: json['latitude'] ?? '0',
      longitude: json['longitude'] ?? '0',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      url: json['url'] ?? '',
      filePath: json['filePath'] ?? '',
      forwardUserId: json['forwardUserId'],
      forwardUsername: json['forwardUsername'],
      gausPath: gausPath,
      gausBytes: gausBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
      'city': city,
      'url': url,
      'filePath': filePath,
      'forwardUserId': forwardUserId,
      'forwardUsername': forwardUsername,
      'gausPath': gausPath,
      'gausBytes': gausBytes,
    };
  }
}

class FavouriteImage {
  String url;
  String filePath;
  int size;
  int width;
  int height;
  String gausPath = '';
  String? reply;
  String? caption;
  int? forwardUserId;
  String? forwardUsername;
  String? translation;

  FavouriteImage({
    required this.url,
    required this.filePath,
    required this.size,
    required this.width,
    required this.height,
    this.gausPath = '',
    this.reply,
    this.caption,
    this.forwardUserId,
    this.forwardUsername,
    this.translation,
  });

  factory FavouriteImage.fromJson(Map<String, dynamic> json) {
    return FavouriteImage(
      url: json['url'] ?? '',
      filePath: json['filePath'] ?? '',
      size: json['size'] ?? 0,
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      gausPath: json['gausPath'] ?? '',
      reply: json['reply'],
      caption: json['caption'],
      forwardUserId: json['forwardUserId'],
      forwardUsername: json['forwardUsername'],
      translation: json['translation'],
    );
  }

  factory FavouriteImage.fromBean(AlbumDetailBean bean) {
    return FavouriteImage(
      url: bean.url,
      filePath: bean.filePath,
      size: bean.size,
      width: bean.aswidth ?? 0,
      height: bean.asheight ?? 0,
      gausPath: bean.gausPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'size': size,
      'width': width,
      'height': height,
      'url': url,
      'gausPath': gausPath,
      'reply': reply,
      'caption': caption,
      'forwardUserId': forwardUserId,
      'forwardUsername': forwardUsername,
      'translation': translation,
    };
  }
}

class FavouriteVoice {
  String url; // 下载地址
  String? localUrl; // 本地地址
  int second; // 语音长度 单位/秒
  List decibels; // 声音分贝列表
  String? reply;
  int? forwardUserId;
  String? forwardUsername;
  String? translation;
  String? transcribe;

  FavouriteVoice({
    required this.url,
    required this.localUrl,
    required this.second,
    required this.decibels,
    this.reply,
    this.forwardUserId,
    this.forwardUsername,
    this.translation,
    this.transcribe,
  });

  factory FavouriteVoice.fromJson(Map<String, dynamic> json) {
    return FavouriteVoice(
      url: json['url'] ?? '',
      localUrl: json['localUrl'],
      second: json['second'] ?? 0,
      decibels: json['decibels'] ?? [],
      reply: json['reply'],
      forwardUserId: json['forwardUserId'],
      forwardUsername: json['forwardUsername'],
      translation: json['translation'],
      transcribe: json['transcribe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localUrl': localUrl,
      'second': second,
      'decibels': decibels,
      'url': url,
      'reply': reply,
      'forwardUserId': forwardUserId,
      'forwardUsername': forwardUsername,
      'translation': translation,
      'transcribe': transcribe,
    };
  }
}

class FavouriteVideo {
  String url = '';

  // 原始地址
  String fileName = '';
  String filePath = '';

  // 图片数据大小，单位：字节
  int size = 0;
  int width = 0;
  int height = 0;
  int second = 0;

  String cover = '';
  String coverPath = '';

  String gausPath = '';
  String? reply;
  String? caption;
  int? forwardUserId;
  String? forwardUsername;
  String? translation;

  FavouriteVideo({
    required this.url,
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.width,
    required this.height,
    required this.second,
    required this.cover,
    required this.coverPath,
    this.gausPath = '',
    this.reply,
    this.caption,
    this.forwardUserId,
    this.forwardUsername,
    this.translation,
  });

  factory FavouriteVideo.fromJson(Map<String, dynamic> json) {
    return FavouriteVideo(
      url: json['url'] ?? "",
      fileName: json['fileName'] ?? "",
      filePath: json['filePath'] ?? "",
      size: json['size'] ?? 0,
      width: json['width'] ?? "",
      height: json['height'] ?? "",
      second: json['second'] ?? 0,
      cover: json['cover'] ?? "",
      coverPath: json['coverPath'] ?? "",
      gausPath: json['gausPath'] ?? "",
      reply: json['reply'],
      caption: json['caption'],
      forwardUserId: json['forwardUserId'],
      forwardUsername: json['forwardUsername'],
      translation: json['translation'],
    );
  }

  factory FavouriteVideo.fromBean(AlbumDetailBean bean) {
    return FavouriteVideo(
      url: bean.url,
      fileName: bean.fileName,
      filePath: bean.filePath,
      size: bean.size,
      width: bean.aswidth ?? 0,
      height: bean.asheight ?? 0,
      second: bean.seconds,
      cover: bean.cover,
      coverPath: bean.coverPath,
      gausPath: bean.gausPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'size': size,
      'width': width,
      'height': height,
      'second': second,
      'fileName': fileName,
      'filePath': filePath,
      'cover': cover,
      'coverPath': coverPath,
      'gausPath': gausPath,
      'reply': reply,
      'caption': caption,
      'forwardUserId': forwardUserId,
      'forwardUsername': forwardUsername,
      'translation': translation,
    };
  }
}

class FavouriteAlbum {
  List<AlbumDetailBean> albumList;
  String? reply;
  String? caption;
  int? forwardUserId;
  String? forwardUsername;
  String? translation;

  FavouriteAlbum({
    required this.albumList,
    this.reply,
    this.caption,
    this.forwardUserId,
    this.forwardUsername,
    this.translation,
  });

  factory FavouriteAlbum.fromJson(Map<String, dynamic> json) {
    List<AlbumDetailBean> list = List.empty(growable: true);
    if (json.containsKey('albumList')) {
      for (Map<String, dynamic> item in json['albumList']) {
        list.add(AlbumDetailBean.fromJson(item));
      }
    }
    return FavouriteAlbum(
      albumList: list,
      reply: json['reply'],
      caption: json['caption'],
      forwardUserId: json['forwardUserId'],
      forwardUsername: json['forwardUsername'],
      translation: json['translation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'albumList': albumList,
      'reply': reply,
      'caption': caption,
      'forwardUserId': forwardUserId,
      'forwardUsername': forwardUsername,
      'translation': translation,
    };
  }
}

class FavouriteDelta {
  Delta delta;

  FavouriteDelta({
    required this.delta,
  });

  factory FavouriteDelta.fromJson(Map<String, dynamic> json) {
    return FavouriteDelta(
      delta: Delta.fromJson(json['delta']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delta': delta,
    };
  }
}
