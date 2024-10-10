class ChatList<T> {
  int serverTime;
  T? data;

  ChatList({this.serverTime = 0, this.data});

  factory ChatList.fromJson(Map<String, dynamic> json) => ChatList<T>(
        serverTime: json["server_time"],
        data: json["list"] as T,
      );
}
