class TagsNotify
{
  String? channel;
  String? message;

  TagsNotify({this.channel, this.message,});

  factory TagsNotify.fromJson(Map<String, dynamic> json) {
    return TagsNotify(
      channel: json['channel'],
      message: json['message'],
    );
  }
}