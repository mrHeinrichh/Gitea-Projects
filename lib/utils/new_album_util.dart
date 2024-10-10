import 'package:jxim_client/managers/object_mgr.dart';

class NewAlbumUtil {
  static getMaxWidth(int length, double maxWidthRatio) {
    switch (length) {
      case 1:
        return ((ObjectMgr.screenMQ!.size.width *
                    (objectMgr.loginMgr.isDesktop ? 0.5 : 1)) *
                (294 / ObjectMgr.screenMQ!.size.width) *
                maxWidthRatio)
            .toDouble();
      case 2:
      case 3:
        return ((ObjectMgr.screenMQ!.size.width *
                    (objectMgr.loginMgr.isDesktop ? 0.5 : 1)) *
                (294 / ObjectMgr.screenMQ!.size.width) *
                maxWidthRatio)
            .toDouble();
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
        return ((ObjectMgr.screenMQ!.size.width *
                    (objectMgr.loginMgr.isDesktop ? 0.5 : 1)) *
                (294 / ObjectMgr.screenMQ!.size.width) *
                maxWidthRatio)
            .toDouble();
    }
    return (ObjectMgr.screenMQ!.size.width *
            (294 / ObjectMgr.screenMQ!.size.width) *
            maxWidthRatio)
        .toDouble();
  }
}
