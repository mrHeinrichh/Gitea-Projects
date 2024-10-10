import 'dart:convert';

import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';

/// emoji : []
/// stickers : []
/// gifs : []

StickersRecentlyData stickersRecentlyDataFromJson(String str) =>
    StickersRecentlyData.fromJson(json.decode(str));

String stickersRecentlyDataToJson(StickersRecentlyData data) =>
    json.encode(data.toJson());

class StickersRecentlyData {
  StickersRecentlyData({
    List<String>? recentEmojiList,
    List<Sticker>? recentStickersList,
    List<Gifs>? recentGifList,
  })  : _recentEmojiList = recentEmojiList ?? <String>[],
        _recentStickersList = recentStickersList ?? <Sticker>[],
        _recentGifList = recentGifList ?? <Gifs>[];

  factory StickersRecentlyData.fromJson(Map<String, dynamic> json) {
    final emojis = <String>[];
    if (json['emojis'] != null) {
      final emojisList =
          (json['emojis'] as List).map((e) => e as String).toList();
      emojis.addAll(emojisList);
    }

    final stickers = <Sticker>[];
    if (json['stickers'] != null) {
      final stickerList =
          (json['stickers'] as List).map((e) => Sticker.fromJson(e)).toList();
      stickers.addAll(stickerList);
    }
    final gifs = <Gifs>[];
    if (json['gifs'] != null) {
      final gifList =
          (json['gifs'] as List).map((e) => Gifs.fromJson(e)).toList();
      gifs.addAll(gifList);
    }

    return StickersRecentlyData(
      recentEmojiList: emojis,
      recentStickersList: stickers,
      recentGifList: gifs,
    );
  }

  final List<String> _recentEmojiList;
  final List<Sticker> _recentStickersList;
  final List<Gifs> _recentGifList;

  StickersRecentlyData copyWith({
    List<String>? emoji,
    List<Sticker>? stickers,
    List<Gifs>? gifs,
  }) =>
      StickersRecentlyData(
        recentEmojiList: emoji ?? _recentEmojiList,
        recentStickersList: stickers ?? _recentStickersList,
        recentGifList: gifs ?? _recentGifList,
      );

  List<String> get recentEmojiList => _recentEmojiList;

  List<Sticker> get recentStickersList => _recentStickersList;

  List<Gifs> get recentGifList => _recentGifList;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['emojis'] = _recentEmojiList;
    map['stickers'] = _recentStickersList.map((e) => e.toJson()).toList();
    map['gifs'] = _recentGifList;
    return map;
  }
}
