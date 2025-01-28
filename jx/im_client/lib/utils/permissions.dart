import 'dart:io';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class Permissions {
  static String appName = '应用';

  // 请求权限
  static Future<bool> request(
    List<Permission> permissions, {
    bool isShowToast = true,
    bool showPopUp = true,
    String? subTitle,
  }) async {
    if (permissions.isEmpty) return true;
    int flag = 0; // flag = 1; 是安卓13+ 需要PhotoManager permission
    // 安卓的相册权限对应的是存储权限
    if (Platform.isAndroid && permissions.contains(Permission.photos)) {
      permissions.remove(Permission.photos);
      /* Apps that run on Android 11 but target Android 10 (API level 29)
       can still request the requestLegacyExternalStorage attribute. 
      ...After you update your app to target Android 11,
       the system ignores the requestLegacyExternalStorage flag. */
      if (await objectMgr.callMgr.getAndroidTargetVersionApi() >= 33) {
        flag = 1;
      } else {
        permissions.add(Permission.storage);
      }
    }

    try {
      List<Permission> noGranteds = [];
      // 安卓13+ 的Photo权限
      if (flag == 1) {
        PermissionState pp = await PhotoManager.requestPermissionExtend();
        if (pp == PermissionState.denied) {
          noGranteds.add(Permission.photos);
        }
      }

      if (permissions.isNotEmpty) {
        Map<Permission, PermissionStatus> statuses =
            await permissions.request();
        for (var item in permissions) {
          if (statuses[item]?.isGranted == false &&
              statuses[item]?.isLimited == false) {
            noGranteds.add(item);
          }
        }
      }

      if (noGranteds.isNotEmpty && isShowToast) {
        if (showPopUp) {
          var name = Permissions().getPermissionsName(noGranteds);
          openSettingPopup(name, subTitle: subTitle);
        } else {
          openAppSettings();
        }
        return false;
      }
      return noGranteds.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // 获取权限名
  String getPermissionName(Permission p) {
    String name = "";
    if (p.value == Permission.calendarFullAccess.value) {
      name = localized(permissionCalendar);
    } else if (p.value == Permission.contacts.value) {
      name = localized(permissionContact);
    } else if (p.value == Permission.camera.value) {
      name = localized(permissionCamera);
    } else if (p.value == Permission.photos.value) {
      name = localized(permissionGallery);
    } else if (p.value == Permission.storage.value) {
      name = localized(permissionStorage);
    } else if (p.value == Permission.notification.value) {
      name = localized(permissionNotification);
    } else if (p.value == Permission.location.value) {
      name = localized(permissionLocation);
    } else if (p.value == Permission.microphone.value) {
      name = localized(permissionMicrophone);
    }
    return name;
  }

  // 获取权限名
  String getPermissionsName(List<Permission> permissions) {
    List<String> names = [];
    for (var item in permissions) {
      names.add(getPermissionName(item));
    }
    return names.join("、");
  }
}
