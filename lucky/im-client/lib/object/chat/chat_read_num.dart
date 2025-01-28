class ChatReadNum {
  int id = 0;
  int read_num = 0;
  int chat_id = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('read_num')) read_num = json['read_num'];
    if (json.containsKey('chat_id')) chat_id = json['chat_id'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'read_num': read_num,
      'chat_id': chat_id,
    };
  }
}
