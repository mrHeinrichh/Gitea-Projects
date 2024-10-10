class AppException implements Exception {
  final String? _message;
  final dynamic _prefix;
  final Object? _data;

  AppException([this._prefix, this._message, this._data]);

  @override
  String toString() {
    return "$_prefix: $_message $_data";
  }

  getMessage() {
    return _message;
  }

  getPrefix() {
    return _prefix;
  }

  getData() {
    return _data;
  }
}

class AuthException extends AppException {
  AuthException(String message) : super("Auth: ", message);
}

class ExistException extends AppException {
  ExistException(String message) : super("NotExist: ", message);
}

class NetworkException extends AppException {
  NetworkException(String message) : super("Network: ", message);
}

class RequestException extends AppException {
  RequestException(String message) : super("Request: ", message);
}

class CodeException extends AppException {
  CodeException(int super.code, String super.message, dynamic super.data);
}
