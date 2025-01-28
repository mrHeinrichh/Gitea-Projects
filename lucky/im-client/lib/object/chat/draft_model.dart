class DraftModel {
  int chat_id = 0;
  String input = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('chat_id')) chat_id = json['chat_id'];
    if (json.containsKey('input')) input = json['input'];
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chat_id,
      'input': input,
    };
  }
}
