class RequestData {
  String apiPath;
  dynamic data;
  int attempts;
  int refreshAttempts;
  int maxTry;
  bool printBody;
  bool needToken;
  String methodType;

  RequestData(
    this.apiPath, {
    required this.data,
    required this.attempts,
    required this.refreshAttempts,
    required this.maxTry,
    required this.printBody,
    required this.needToken,
    required this.methodType,
  });

  Map<String, dynamic> toJson() {
    return {
      'apiPath': apiPath,
      'data': data,
      'attempts': attempts,
      'refreshAttempts': refreshAttempts,
      'maxTry': maxTry,
      'printBody': printBody,
      'needToken': needToken,
    };
  }

  factory RequestData.fromJson(Map<String, dynamic> json) {
    return RequestData(
      json['apiPath'] ?? '',
      data: json['data'] ?? {},
      attempts: json['attempts'] ?? 0,
      refreshAttempts: json['refreshAttempts'] ?? 0,
      maxTry:json['maxTry'] ?? 0,
      printBody: json['printBody'] ?? false,
      needToken: json['needToken'] ?? false,
      methodType: json['methodType'] ?? 'POST',
    );
  }
}
