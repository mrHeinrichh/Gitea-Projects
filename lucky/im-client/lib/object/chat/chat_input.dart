class ChatInput {
  int state = 0;
  int send_id = 0;
  int chat_id = 0;
  String username = '';
  int currentTimestamp = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('state')) state = json['state'];
    if (json.containsKey('send_id')) send_id = json['send_id'];
    if (json.containsKey('chat_id')) chat_id = json['chat_id'];
    if (json.containsKey('username')) username = json['username'];
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'send_id': send_id,
      'chat_id': chat_id,
      'username': username,
    };
  }
}
