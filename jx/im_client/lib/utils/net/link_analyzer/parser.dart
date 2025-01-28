import 'dart:convert';
import 'dart:math';

import 'package:html/dom.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/file_type_util.dart';

/// The base class for implementing a parser
mixin MetadataKeys {
  static const kTitle = 'title';
  static const kDescription = 'description';
  static const kImage = 'image';
  static const kImageHeight = 'imageHeight';
  static const kImageWidth = 'imageWidth';
  static const kVideo = 'video';
  static const kVideoHeight = 'videoHeight';
  static const kVideoWidth = 'videoWidth';
  static const kUrl = 'url';
  static const kTimeout = 'timeout';
}

mixin BaseMetaInfo {
  String? title;
  String? desc;
  String? url;
  String? image;
  String? imageWidth;
  String? imageHeight;

  String? video;
  String? videoWidth;
  String? videoHeight;

  /// Returns `true` if any parameter other than [url] is filled
  bool get hasData =>
      ((title?.isNotEmpty ?? false) && title != 'null') ||
      ((desc?.isNotEmpty ?? false) && desc != 'null');

  String get hostDomain => !notBlank(url)
      ? ''
      : Uri.parse(url!).host.isEmpty
          ? url!
          : Uri.parse(url!).host;

  bool get titleExceedMaximum => (title?.length ?? 0) > 64;

  bool get descExceedMaximum => (desc?.length ?? 0) > 128;

  Metadata parse() {
    final m = Metadata();
    m.title = title;
    m.desc = desc;
    m.url = url;
    m.image = image;
    m.imageHeight = imageHeight;
    m.imageWidth = imageWidth;
    m.video = video;
    m.videoWidth = videoWidth;
    m.videoHeight = videoHeight;
    return m;
  }

  Metadata copyWith(Metadata? data) {
    return Metadata()
      ..title = data?.title ?? title
      ..desc = data?.desc ?? desc
      ..url = data?.url ?? url
      ..image = data?.image ?? image
      ..imageHeight = data?.imageHeight ?? imageHeight
      ..imageWidth = data?.imageWidth ?? imageWidth
      ..video = data?.video ?? video
      ..videoWidth = data?.videoWidth ?? videoWidth
      ..videoHeight = data?.videoHeight ?? videoHeight;
  }
}

abstract class InfoBase {
  late DateTime timeout;
}

/// Container class for Metadata
class Metadata extends InfoBase with BaseMetaInfo, MetadataKeys {
  bool get hasAllMetadata {
    return title != null && desc != null && hasMedia && url != null;
  }

  bool get hasMedia => image != null || video != null;

  ///Change parse from int to num to avoid formatException.
  bool get isBigMedia =>
      notBlank(video) ||
      (notBlank(imageWidth) || notBlank(imageHeight)
          ? min(num.tryParse(imageWidth ?? '1')!.toInt(),
                  num.tryParse(imageHeight ?? '1')!.toInt()) >
              Config().messageMin
          : false);

  @override
  String toString() {
    return toMap().toString();
  }

  Map<String, dynamic> toMap() {
    return {
      MetadataKeys.kTitle: title,
      MetadataKeys.kDescription: desc,
      MetadataKeys.kImage: image,
      MetadataKeys.kImageWidth: imageWidth,
      MetadataKeys.kImageHeight: imageHeight,
      MetadataKeys.kVideo: video,
      MetadataKeys.kVideoWidth: videoWidth,
      MetadataKeys.kVideoHeight: videoHeight,
      MetadataKeys.kUrl: url,
      MetadataKeys.kTimeout: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  static Metadata fromJson(Map<String, dynamic> json) {
    final m = Metadata();
    m.title = json[MetadataKeys.kTitle];
    m.desc = json[MetadataKeys.kDescription];
    m.image = json[MetadataKeys.kImage];
    m.imageWidth = json[MetadataKeys.kImageWidth];
    m.imageHeight = json[MetadataKeys.kImageHeight];
    m.video = json[MetadataKeys.kVideo];
    m.videoWidth = json[MetadataKeys.kVideoWidth];
    m.videoHeight = json[MetadataKeys.kVideoHeight];
    m.url = json[MetadataKeys.kUrl];
    m.timeout = DateTime.fromMillisecondsSinceEpoch(
      json[MetadataKeys.kTimeout]! * 1000,
    );
    return m;
  }
}

/// Parses [Metadata] from [<meta attribute: 'name' property='*'>] tags
class OtherParser with BaseMetaInfo {
  /// The [document] to be parse
  final Document? _document;

  OtherParser(this._document);

  /// Get [Metadata.fileType] from 'title'
  @override
  String? get title =>
      getProperty(_document, attribute: 'name', property: 'title');

  /// Get [Metadata.desc] from 'description'
  @override
  String? get desc =>
      getProperty(_document, attribute: 'name', property: 'description');

  /// Get [Metadata.image] from 'image'
  @override
  String? get image =>
      getProperty(_document, attribute: 'name', property: 'image');

  /// Get [Metadata.url] from 'url'
  @override
  String? get url => getProperty(_document, attribute: 'name', property: 'url');

  @override
  String toString() => parse().toString();
}

/// Parses [Metadata] from [<meta property='og:*'>] tags
class OpenGraphParser with BaseMetaInfo {
  /// The [document] to be parse
  final Document? _document;

  OpenGraphParser(this._document);

  /// Get [Metadata.fileType] from 'og:title'
  @override
  String? get title =>
      getProperty(_document, attribute: 'name', property: 'title') ??
      getProperty(_document, attribute: 'name', property: 'og:title') ??
      getProperty(_document, property: 'title') ??
      getProperty(_document, property: 'og:title');

  /// Get [Metadata.desc] from 'og:description'
  @override
  String? get desc =>
      getProperty(_document, attribute: 'name', property: 'description') ??
      getProperty(_document, attribute: 'name', property: 'og:description') ??
      getProperty(_document, property: 'description') ??
      getProperty(_document, property: 'og:description');

  /// Get [Metadata.image] from 'og:image'
  @override
  String? get image =>
      getProperty(_document, attribute: 'name', property: 'og:image') ??
      getProperty(_document, property: 'og:image');

  @override
  String? get imageWidth =>
      getProperty(_document, attribute: 'name', property: 'og:image:width') ??
      getProperty(_document, attribute: 'name', property: 'og:width') ??
      getProperty(_document, property: 'og:image:width') ??
      getProperty(_document, property: 'og:width');

  @override
  String? get imageHeight =>
      getProperty(_document, attribute: 'name', property: 'og:image:height') ??
      getProperty(_document, attribute: 'name', property: 'og:height') ??
      getProperty(_document, property: 'og:image:height') ??
      getProperty(_document, property: 'og:height');

  /// Get [Metadata.video] from 'og:image'
  @override
  String? get video =>
      getProperty(_document, attribute: 'name', property: 'og:video') ??
      getProperty(_document, property: 'og:video') ??
      getProperty(_document, attribute: 'name', property: 'og:video:url') ??
      getProperty(_document, property: 'og:video:url');

  @override
  String? get videoWidth => getProperty(_document, property: 'og:video:width');

  @override
  String? get videoHeight =>
      getProperty(_document, property: 'og:video:height');

  @override
  String toString() => parse().toString();
}

/// Parses [Metadata] from `json-ld` data in `<script>`
class JsonLdParser with BaseMetaInfo {
  /// The [document] to be parse
  Document? document;
  dynamic _jsonData;

  JsonLdParser(this.document) {
    _jsonData = _parseToJson(document);
  }

  dynamic _parseToJson(Document? document) {
    final data = document?.head
        ?.querySelector("script[type='application/ld+json']")
        ?.innerHtml;
    if (data == null) return null;
    /* For multiline json file */
    // Replacing all new line characters with empty space
    // before performing json decode on data
    var d = jsonDecode(data.replaceAll('\n', ' '));
    return d;
  }

  /// Get the [Metadata.fileType] from the [<title>] tag
  @override
  String? get title {
    final data = _jsonData;
    if (data is List) {
      return data.first['name'];
    } else if (data is Map) {
      return data.get('name') ?? data.get('headline');
    }
    return null;
  }

  /// Get the [Metadata.desc] from the <meta name="description" content=""> tag
  @override
  String? get desc {
    final data = _jsonData;
    if (data is List) {
      return data.first['description'] ?? data.first['headline'];
    } else if (data is Map) {
      return data.get('description') ?? data.get('headline');
    }
    return null;
  }

  /// Get the [Metadata.image] from the first <img> tag in the body
  @override
  String? get image {
    final data = _jsonData;
    if (data is List && data.isNotEmpty) {
      return _imgResultToStr(data.first['logo'] ?? data.first['image']);
    } else if (data is Map) {
      return _imgResultToStr(
        data.getDynamic('logo') ?? data.getDynamic('image'),
      );
    }
    return null;
  }

  String? _imgResultToStr(dynamic result) {
    if (result is List && result.isNotEmpty) result = result.first;
    if (result is String) return result;
    return null;
  }

  @override
  String toString() => parse().toString();
}

/// Parses [Metadata] from [<meta>, <title>, <img>] tags
class HtmlMetaParser with BaseMetaInfo {
  /// The [document] to be parse
  final Document? _document;

  HtmlMetaParser(this._document);

  /// Get the [Metadata.fileType] from the <title> tag
  @override
  String? get title => _document?.head?.querySelector('title')?.text;

  /// Get the [Metadata.desc] from the <meta name="description" content=""> tag
  @override
  String? get desc => _document?.head
      ?.querySelector("meta[name='description']")
      ?.attributes
      .get('content');

  /// Get the [Metadata.image] from the first <img> tag in the body
  @override
  String? get image {
    final attrs = _document?.body?.querySelector('img')?.attributes;

    attrs?.removeWhere(
      (_, v) => !imageExtension.contains(v.split('.').last),
    );
    return attrs?.get('src');
  }

  @override
  String toString() => parse().toString();
}

/// Parses [Metadata] from [<meta property='twitter:*'>] tags
class TwitterParser with BaseMetaInfo {
  /// The [document] to be parse
  final Document? _document;

  TwitterParser(this._document);

  /// Get [Metadata.fileType] from 'twitter:title'
  @override
  String? get title =>
      getProperty(_document, attribute: 'name', property: 'twitter:title') ??
      getProperty(_document, property: 'twitter:title');

  /// Get [Metadata.desc] from 'twitter:description'
  @override
  String? get desc =>
      getProperty(
        _document,
        attribute: 'name',
        property: 'twitter:description',
      ) ??
      getProperty(_document, property: 'twitter:description');

  /// Get [Metadata.image] from 'twitter:image'
  @override
  String? get image =>
      getProperty(_document, attribute: 'name', property: 'twitter:image') ??
      getProperty(_document, property: 'twitter:image');

  /// Get [Metadata.video] from 'og:image'
  @override
  String? get video => getProperty(_document, property: 'twitter:player');

  @override
  String? get videoWidth =>
      getProperty(_document, property: 'twitter:player:width');

  @override
  String? get videoHeight =>
      getProperty(_document, property: 'twitter:player:height');

  /// Twitter Cards do not have a url property so get the url from [og:url], if available.
  @override
  String? get url => OpenGraphParser(_document).url;

  @override
  String toString() => parse().toString();
}

extension GetMethod on Map {
  String? get(dynamic key) {
    var value = this[key];
    if (value is List) return value.first;
    return value.toString();
  }

  dynamic getDynamic(dynamic key) {
    return this[key];
  }
}

String? getDomain(String url) {
  return Uri.parse(url).host.toString().split('.')[0];
}

String? getProperty(
  Document? document, {
  String tag = 'meta',
  String attribute = 'property',
  String? property,
  String key = 'content',
}) {
  var value = document
      ?.getElementsByTagName(tag)
      .cast<Element?>()
      .firstWhere(
        (element) => element?.attributes[attribute] == property,
        orElse: () => null,
      )
      ?.attributes
      .get(key);

  return value;
}
