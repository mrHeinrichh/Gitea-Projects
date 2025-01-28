import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/helper/content_type.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';

class LinkAnalyzer {
  /// Is it an empty string
  static bool isNotEmpty(String? str) {
    return str != null && str.trim().isNotEmpty;
  }

  /// return [Metadata] from cache if available
  static Future<Metadata?> getInfoFromCache(String url) async
  {
    Metadata? info;
    try {
      dynamic infoJson = await objectMgr.localStorageMgr.read(url);
      if (infoJson != null) {
        if (infoJson is String) {
          infoJson = jsonDecode(infoJson);
        }
        info = Metadata.fromJson(infoJson);
        if(info.image!=null) {
          var (result, index)=checkImageProtocol(info.image!);
          if(index != -1){
            info.image = result;
            objectMgr.localStorageMgr.write(url, info.toJson());
          }
        }
        if (!info.timeout.isAfter(DateTime.now())) {
          unawaited(objectMgr.localStorageMgr.delLocalTable(url));
        }
      }
    } catch (e) {
      pdebug('Error while retrieving cache data => $e');
      objectMgr.localStorageMgr.remove(url);
    }

    return info;
  }

  static (String,int) checkImageProtocol(String aImageUrl) {
    List<String> protocols = ["http:http","https:https","https:http","http:https"];
    int index = -1;
    String result = aImageUrl;
    for (var protocol in protocols) {
      if(aImageUrl.contains(protocol))
      {
        index = protocols.indexOf(protocol);
        break;
      }
    }
    if(index != -1){
      result = aImageUrl.replaceAll(protocols[index], protocols[index].split(":")[1]);
    }

    return (result,index);
  }

  // Twitter generates meta tags on client side so it's impossible to read
  // So we use this hack to fetch server side rendered meta tags
  // This helps for URL's who follow client side meta tag generation technique
  static Future<Metadata?> getInfoClientSide(
    String url, {
    Duration? cache = const Duration(hours: 24),
    Map<String, String> headers = const {},
    CancelToken? cancelToken,
  }) =>
      getInfo(
        url,
        cache: cache,
        headers: headers,
        // 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko)',
        userAgent:
            // 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
            // 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            <String>[
          'PostmanRuntime/7.42.0',
          'Mozilla/5.0 (compatible; LinkPreviewBot/1.0)',
          'TelegramBot (like TwitterBot)',
          'WhatsApp/2.23.20.0',
        ],
        // 'PostmanRuntime/7.42.0',
        cancelToken: cancelToken,
      );

  /// Fetches a [url], validates it, and returns [Metadata].
  static Future<Metadata?> getInfo(
    String url, {
    Duration? cache = const Duration(hours: 24),
    Map<String, String> headers = const {},
    // String? userAgent,
    required List<String> userAgent,
    CancelToken? cancelToken,
  }) async {
    final Completer<Metadata?> reqCompleter = Completer();
    cancelToken?.whenCancel.then(
      (value) => reqCompleter.completeError('Cancel by user'),
    );

    if (!url.startsWith('http')) url = 'http://$url';

    Metadata? info;
    if ((cache?.inSeconds ?? 0) > 0) {
      info = await getInfoFromCache(url);
    } else {
      objectMgr.localStorageMgr.remove(url);
    }
    if (info != null) return info;

    /// Default values; Domain name as the [title],
    /// URL as the [description]
    info?.title = Uri.parse(url).host.toString();

    info?.url = url;

    http.Client client = http.Client();
    try {
      Metadata data = Metadata();

      for (final ua in userAgent) {
        // Make our network call
        final response = await client.get(
          Uri.parse(url),
          headers: {
            // 'Accept': '*/*',
            // 'Accept-Language': 'en-US,en;q=0.9',
            // 'Accept-Encoding': 'deflate, gzip, br',
            // 'Referer': 'https://www.google.com/',
            ...headers,
            // if (userAgent != null) 'User-Agent': userAgent,
            'User-Agent': ua,
          },
        ).timeout(const Duration(seconds: 10));

        // todo: Compatible with media content
        final headerContentType = response.headers['content-type'];
        String? encoding;
        if (headerContentType?.contains('charset') ?? false) {
          encoding = headerContentType!.split('charset=')[1];
        }
        final type = ResponseContentType.getType(headerContentType ?? '');

        switch (type) {
          case ResponseContentType.text:
            final document = responseToDocument(
              response,
              encoding: encoding,
            );
            if (document != null) {
              data = _extractMetadata(document, url: url) ?? Metadata();
              // reqCompleter.complete(info);
              // return info;
            }

            // data = _extractMetadata(document, url: url) ?? Metadata();
            break;
          default:
            break;
        }
      }

      if (data.url == null) {
        reqCompleter.complete(null);
        return null;
      } else if (cache != null) {
        data.timeout = DateTime.now().add(cache);
        objectMgr.localStorageMgr.write(url, data.toJson());
      }

      reqCompleter.complete(data);
    } catch (error) {
      pdebug('Error in $url response ($error)');
      // Any sort of exceptions due to wrong URL's, host lookup failure etc.
      return null;
    } finally {
      client.close();
    }

    return reqCompleter.future;
  }

  /// Takes an [http.Response] and returns a [html.Document]
  static Document? responseToDocument(
    http.Response response, {
    String? encoding,
  }) {
    if (response.statusCode != 200) return null;

    Document? document;
    try {
      if (encoding == null ||
          encoding.toLowerCase() == "utf-8" ||
          encoding.toLowerCase() == "utf8") {
        document = parse(utf8.decode(response.bodyBytes));
      } else {
        document = parse(
          String.fromCharCodes(response.bodyBytes),
          encoding: encoding,
        );
      }
    } catch (err) {
      return document;
    }

    return document;
  }

  /// Returns instance of [Metadata] with data extracted from the [html.Document]
  /// Provide a given url as a fallback when there are no Document url extracted
  /// by the parsers.
  ///
  /// Future: Can pass in a strategy i.e: to retrieve only OpenGraph, or OpenGraph and Json+LD only
  static Metadata? _extractMetadata(Document document, {String? url}) {
    return _parse(document, url: url);
  }

  /// This is the default strategy for building our [Metadata]
  ///
  /// It tries [OpenGraphParser], then [TwitterParser],
  /// then [JsonLdParser], and falls back to [HTMLMetaParser] tags for missing data.
  /// You may optionally provide a URL to the function,
  /// used to resolve relative images or to compensate for the
  /// lack of URI identifiers from the metadata parsers.
  static Metadata _parse(Document? document, {String? url}) {
    final output = Metadata();

    final parsers = [
      _openGraph(document),
      _twitterCard(document),
      _jsonLdSchema(document),
      _htmlMeta(document),
      _otherParser(document),
    ];

    for (final p in parsers) {
      if (p == null) break;

      if (notBlank(p.title) && p.desc != "null") output.title ??= p.title;
      if (output.title != null && output.title!.length > 65) {
        output.title = output.title!.substring(0, 65);
      }
      if (notBlank(p.desc) && p.desc != "null") output.desc ??= p.desc;
      if (output.desc != null && output.desc!.length > 129) {
        output.desc = output.desc!.substring(0, 129);
      }

      if(p.image!=null){
        var (result, index)=checkImageProtocol(p.image!);
        if(index != -1){
          p.image = result;
        }
      }

      output.image ??= p.image;

      int? w = int.tryParse(p.imageWidth ?? "");
      w ??= double.tryParse(p.imageWidth ?? "")?.toInt();
      if (w != null) {
        output.imageWidth ??= w.toString();
      }
      int? h = int.tryParse(p.imageHeight ?? "");
      h ??= double.tryParse(p.imageHeight ?? "")?.toInt();

      if (h != null) {
        output.imageHeight ??= h.toString();
      }
      output.video ??= p.video;
      output.videoWidth ??= p.videoWidth;
      output.videoHeight ??= p.videoHeight;
      output.url ??= p.url ?? url;

      if (output.hasAllMetadata) break;
    }
    return output;
  }

  static Metadata? _openGraph(Document? document) {
    try {
      return OpenGraphParser(document).parse();
    } catch (e) {
      return null;
    }
  }

  static Metadata? _htmlMeta(Document? document) {
    try {
      return HtmlMetaParser(document).parse();
    } catch (e) {
      return null;
    }
  }

  static Metadata? _jsonLdSchema(Document? document) {
    try {
      return JsonLdParser(document).parse();
    } catch (e) {
      return null;
    }
  }

  static Metadata? _twitterCard(Document? document) {
    try {
      return TwitterParser(document).parse();
    } catch (e) {
      return null;
    }
  }

  static Metadata? _otherParser(Document? document) {
    try {
      return OtherParser(document).parse();
    } catch (e) {
      return null;
    }
  }
}
