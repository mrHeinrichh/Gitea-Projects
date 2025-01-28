class RequestData {
  String apiPath;
  dynamic data;
  int attempts;
  int refreshAttempts;
  int maxTry;
  bool cipher;
  bool printBody;
  bool needToken;
  String methodType;

  RequestData(
    this.apiPath,
    this.data,
    this.attempts,
    this.refreshAttempts,
    this.maxTry,
    this.cipher,
    this.printBody,
    this.needToken,
    this.methodType,
  );

  Map<String, dynamic> toJson() {
    return {
      'apiPath': apiPath,
      'data': data,
      'attempts': attempts,
      'refreshAttempts': refreshAttempts,
      'maxTry': maxTry,
      'cipher': cipher,
      'printBody': printBody,
      'needToken': needToken,
    };
  }
}
