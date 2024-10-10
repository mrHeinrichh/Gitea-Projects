class LanguageTranslateModel {
  int id;
  String language;
  String languageName;
  String languageTranslateName;
  String version;
  String path;
  int createdAt;

  LanguageTranslateModel({
    required this.id,
    required this.language,
    required this.languageName,
    required this.languageTranslateName,
    required this.version,
    required this.path,
    required this.createdAt,
  });

  factory LanguageTranslateModel.fromJson(Map<String, dynamic> json) {
    return LanguageTranslateModel(
      id: json['id'] ?? 0,
      language: json['language'] ?? "",
      languageName: json['language_name'] ?? "",
      languageTranslateName: json['language_translate_name'] ?? "",
      version: json['version'] ?? "",
      path: json['path'] ?? "",
      createdAt: json['created_at'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'language_name': languageName,
      'language_translate_name': languageTranslateName,
      'version': version,
      'path': path,
      'created_at': createdAt,
    };
  }
}
