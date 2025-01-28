class RegexTextModel {
  RegexTextModel({
    required this.type,
    required this.text,
    required this.start,
    required this.end,
  });

  final String type;
  final String text;
  int start;
  int end;
}
