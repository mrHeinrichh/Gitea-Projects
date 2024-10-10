import 'package:jxim_client/utils/emoji/emoji_utils.dart';

class EmojiModel {
  List<int> uidList = [];
  String emoji = "";

  EmojiModel({
    required this.uidList,
    required this.emoji,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uidList;
    data['emoji'] = emoji;
    return data;
  }

  EmojiModel.fromJson(Map<String, dynamic> json) {
    var list = json['uid'];
    if (list is List) {
      uidList = list.map((item) => item as int).toList();
    } else {
      uidList = [];
    }
    emoji = json['emoji'] ?? "";
    if (!EmojiUtils.getEmojiList().contains(emoji)) {
      emoji = '👍';
    }
  }

  @override
  String toString() {
    return 'EmojiModel{uidList: $uidList, emoji: $emoji}';
  }
}
