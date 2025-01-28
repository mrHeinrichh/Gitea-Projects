class ChatList<T> {
  int server_time;
  T? data;

  ChatList({this.server_time = 0,this.data});


  factory ChatList.fromJson(Map<String, dynamic> json) => ChatList<T>(
        server_time: json["server_time"],
        data: json["list"] as T,
      );
}
