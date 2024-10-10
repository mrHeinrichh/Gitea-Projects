class TranslateArrayModel {
  String? langFrom;
  String? langTo;
  List<String>? oriText;
  List<String>? transText;

  TranslateArrayModel({
    this.langFrom,
    this.langTo,
    this.oriText,
    this.transText,
  });

  factory TranslateArrayModel.fromJson(Map<String, dynamic> json) {
    return TranslateArrayModel(
      langFrom: json['lang_from'],
      langTo: json['lang_to'],
      oriText: List<String>.from(json['ori_text'] as List),
      transText: List<String>.from(json['trans_text'] as List),
    );
  }
}
