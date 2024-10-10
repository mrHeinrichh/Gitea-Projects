class ChatShare {
  final int uid;
  final int chatId;
  final String name;
  final String shortName;
  final int typ;
  final String icon;

  ChatShare(this.uid, this.chatId, this.name, this.shortName, this.typ, this.icon);

  Map<String, dynamic> toJson() {
    return {
      'uid':uid,
      'chatId': chatId,
      'name': name,
      'shortName': shortName,
      'typ': typ,
      'icon': icon,
    };
  }
}
