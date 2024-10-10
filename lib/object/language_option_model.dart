import 'dart:ui';

class LanguageOptionModel {
  final String title;
  final String content;
  final String languageKey;
  final Locale locale;
  bool isSelected;

  LanguageOptionModel({
    required this.title,
    required this.content,
    required this.languageKey,
    required this.locale,
    this.isSelected = false,
  });
}
