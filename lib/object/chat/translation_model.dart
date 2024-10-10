class TranslationModel {

  static const int showBoth = 0;
  static const int showTranslationOnly = 1;

  bool showTranslation = false;
  String currentLocale = '';

  /// 0 = 原文 + 译文
  /// 1 = 译文
  int visualType = 0;

  // {'en': 'Hello'}
  Map<String, dynamic> translation = {};

  TranslationModel.fromJson(Map<String, dynamic> json ) {
    if (json['showTranslation'] != null) showTranslation = json['showTranslation'];
    if (json['currentLocale'] != null) currentLocale = json['currentLocale'];
    if (json['visualType'] != null) visualType = json['visualType'];
    if (json['translation'] != null) translation = json['translation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['showTranslation'] = showTranslation;
    data['currentLocale'] = currentLocale;
    data['visualType'] = visualType;
    data['translation'] = translation;
    return data;
  }

  TranslationModel({this.showTranslation = false, this.currentLocale = '', this.visualType = 0, Map<String, dynamic>? translation}) {
    if (translation != null) {
      this.translation = translation;
    }
  }

  String getContent() {
    String content = '';
    if (translation.isNotEmpty) {
      content = translation.values.first;
    }
    return content;
  }
}
