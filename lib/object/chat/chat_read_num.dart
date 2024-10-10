class ChatReadNum {
  int id = 0;
  int readNum = 0;
  int chatId = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('read_num')) readNum = json['read_num'];
    if (json.containsKey('chat_id')) chatId = json['chat_id'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'read_num': readNum,
      'chat_id': chatId,
    };
  }
}
