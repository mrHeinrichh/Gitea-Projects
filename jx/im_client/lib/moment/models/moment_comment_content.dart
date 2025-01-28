class MomentCommentContent {
  String? text;
  List<String>? images;
  String? video;

  MomentCommentContent({this.text, this.images, this.video});

  factory MomentCommentContent.fromJson(Map<String, dynamic> json) =>
      MomentCommentContent(
        text: json["text"] ?? "",
        images:
            json["images"] != null ? List<String>.from(json["images"]) : null,
        video: json["video"],
      );
}
