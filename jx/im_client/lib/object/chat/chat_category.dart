import 'dart:convert';

import 'package:jxim_client/data/row_object.dart';

class ChatCategory extends RowObject {
  set id(dynamic v) => setValue('id', v);

  // 聊天室文件夹名字
  String get name => getValue('name', '');

  set name(String v) => setValue('name', v);

  // 添加的聊天室
  List get includedChatIds => getValue('included_chat_ids', []);

  set includedChatIds(List v) => setValue('included_chat_ids', v);

  // 被剔除的聊天室
  List get excludedChatIds => getValue('excluded_chat_ids', []);

  set excludedChatIds(List v) => setValue('excluded_chat_ids', v);

  // 在文件夹里的排序顺序
  int get seq => getValue('seq', -1);

  set seq(int v) => setValue('seq', v);

  // 创建时间
  int get createTime => getValue('create_time', 0);

  set createTime(int v) => setValue('create_time', v);

  @override
  init(Map<String, dynamic> json) {
    for (int i = 0; i < json.length; i++) {
      final key = json.keys.toList()[i];
      final value = json[key];

      if (key == 'included_chat_ids' || key == 'excluded_chat_ids') {
        if (value is String) {
          setValue(
            key,
            jsonDecode(value).cast<int>(),
          );
          continue;
        }
      }

      setValue(key, value);
    }
  }

  ChatCategory copyWith({
    int? id,
    String? name,
    List? includedChatIds,
    List? excludedChatIds,
    int? seq,
    int? createTime,
  }) {
    return ChatCategory()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..includedChatIds = includedChatIds ?? this.includedChatIds
      ..excludedChatIds = excludedChatIds ?? this.excludedChatIds
      ..seq = seq ?? this.seq
      ..createTime = createTime ?? this.createTime;
  }

  static ChatCategory creator() {
    return ChatCategory();
  }

  /// check is all chat room
  bool get isAllChatRoom => seq == 1;
}
