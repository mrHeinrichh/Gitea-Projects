class DraftModel {
  int chatId = 0;
  String input = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('chat_id')) chatId = json['chat_id'];
    if (json.containsKey('input')) input = json['input'];
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'input': input,
    };
  }
}
