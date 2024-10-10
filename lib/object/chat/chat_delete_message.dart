class ChatDeleteMessage {
  int chatId = 0;
  List<int> id = [];

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('chat_id')) chatId = json['chat_id'];
    if (json.containsKey('id')) {
      id = (json['id'] as List).map((e) => e as int).toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
    };
  }
}
