class TranslateModel {
  String? langFrom;
  String? langTo;
  String? oriText;
  String? transText;

  TranslateModel({
    this.langFrom,
    this.langTo,
    this.oriText,
    this.transText,
  });

  factory TranslateModel.fromJson(Map<String, dynamic> json) {
    return TranslateModel(
      langFrom: json['lang_from'],
      langTo: json['lang_to'],
      oriText: json['ori_text'],
      transText: json['trans_text'],
    );
  }
}

class TranscribeModel {
  double? confidence;
  String? mediaPath;
  String? langTo;
  String? transText;

  TranscribeModel({
    this.confidence,
    this.mediaPath,
    this.langTo,
    this.transText,
  });

  factory TranscribeModel.fromJson(Map<String, dynamic> json) {
    return TranscribeModel(
      confidence: json['confidence'].toDouble(),
      mediaPath: json['media_path'],
      langTo: json['lang_to'],
      transText: json['trans_text'],
    );
  }
}

class EventTranscribeModel {
  int? messageId;
  String? text;
  bool? isConverting;

  EventTranscribeModel({
    this.messageId,
    this.text,
    this.isConverting,
  });
}
