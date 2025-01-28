import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';

class LinkAnalyzer {
  /// Is it an empty string
  static bool isNotEmpty(String? str) {
    return str != null && str.trim().isNotEmpty;
  }

  /// return [Metadata] from cache if available
  static Future<Metadata?> getInfoFromCache(String url) async {
    Metadata? info_;
    // pdebug(url);
    try {
      final infoJson = await objectMgr.localStorageMgr.read(url);
      if (infoJson != null) {
        info_ = Metadata.fromJson(infoJson);
        var isEmpty_ = info_.title == null || info_.title == 'null';
        if (isEmpty_ || !info_.timeout.isAfter(DateTime.now())) {
          unawaited(objectMgr.localStorageMgr.delLocalTable(url));
        }
        if (isEmpty_) info_ = null;
      }
    } catch (e) {
      pdebug('Error while retrieving cache data => $e');
    }

    return info_;
  }

  // Twitter generates meta tags on client side so it's impossible to read
  // So we use this hack to fetch server side rendered meta tags
  // This helps for URL's who follow client side meta tag generation technique
  static Future<Metadata?> getInfoClientSide(
    String url, {
    Duration? cache = const Duration(hours: 24),
    Map<String, String> headers = const {},
  }) =>
      getInfo(
        url,
        cache: cache,
        headers: headers,
        // 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko)',
        userAgent:
            'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
      );

  /// Fetches a [url], validates it, and returns [Metadata].
  static Future<Metadata?> getInfo(
    String url, {
    Duration? cache = const Duration(hours: 24),
    Map<String, String> headers = const {},
    String? userAgent,
  }) async {
    Metadata? info;
    if ((cache?.inSeconds ?? 0) > 0) {
      info = await getInfoFromCache(url);
    } else {
      objectMgr.localStorageMgr.remove(url);
    }
    if (info != null) return info;

    /// Default values; Domain name as the [title],
    /// URL as the [description]
    info?.title = getDomain(url);
    info?.desc = url;
    info?.url = url;

    try {
      // Make our network call
      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...headers,
          ...userAgent != null ? {'User-Agent': userAgent} : {}
        },
      );
      final headerContentType = response.headers['content-type'];

      if (headerContentType != null && headerContentType.startsWith('image/')) {
        info?.title = '';
        info?.desc = '';
        info?.image = url;
        return info;
      }

      final document = responseToDocument(response);
      if (document == null) return info;

      final data_ = _extractMetadata(document, url: url);

      if (data_ == null) {
        return info;
      } else if (cache != null) {
        data_.timeout = DateTime.now().add(cache);
      }

      return data_;
    } catch (error) {
      pdebug('Error in $url response ($error)');
      // Any sort of exceptions due to wrong URL's, host lookup failure etc.
      return null;
    }
  }

  /// Takes an [http.Response] and returns a [html.Document]
  static Document? responseToDocument(http.Response response) {
    if (response.statusCode != 200) return null;

    Document? document;
    try {
      document = parse(utf8.decode(response.bodyBytes));
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

      output.title ??= p.title;
      output.desc ??= p.desc;
      output.image ??= p.image;
      output.url ??= p.url ?? url;

      if (output.hasAllMetadata) break;
    }
    // If the parsers did not extract a URL from the metadata, use the given
    // url, if available. This is used to attempt to resolve relative images.
    final url_ = output.url ?? url;
    final image = output.image;
    if (url_ != null && image != null) {
      output.image = Uri.parse(url_).resolve(image).toString();
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
