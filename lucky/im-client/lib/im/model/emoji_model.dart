class EmojiModel {
  List<int> uidList = [];
  String emoji = "";

  EmojiModel({
    required this.uidList,
    required this.emoji,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uid'] = this.uidList;
    data['emoji'] = this.emoji;
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
  }
}
