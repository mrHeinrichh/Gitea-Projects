class AppException implements Exception {
  final _message;
  final _prefix;
  final _data;

  AppException([this._prefix, this._message, this._data]);

  String toString() {
    return "$_prefix: $_message $_data";
  }

  getMessage() {
    return this._message;
  }

  getPrefix() {
    return this._prefix;
  }

  getData() {
    return this._data;
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
  CodeException(int code, String message, dynamic data)
      : super(
          code,
          message,
          data,
        );
}
