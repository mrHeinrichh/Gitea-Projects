class TranslationModel {
  int msg_id = 0;
  String text = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('msg_id')) msg_id = json['msg_id'];
    if (json.containsKey('text')) text = json['text'];
  }

  Map<String, dynamic> toJson() {
    return {
      'msg_id': msg_id,
      'text': text,
    };
  }
}
