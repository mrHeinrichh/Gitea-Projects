import 'package:get/get.dart';

extension GetExtension on GetInterface {
  S findOrPut<S>(S create, {String? tag, bool permanent = false}) {
    return isRegistered<S>(tag: tag)
        ? find<S>(tag: tag)
        : put<S>(create, tag: tag, permanent: permanent);
  }

  Future<bool> findAndDelete<S>({String? tag, bool force = false}) async {
    return isRegistered<S>(tag: tag) && await delete<S>(tag: tag, force: force);
  }
}
