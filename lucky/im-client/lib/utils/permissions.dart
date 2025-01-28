import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static String appName = '应用';

  // 请求权限
  static Future<bool> request(
    List<Permission> permissions, {
    Function(List<Permission> data)? permissCallBack,
    bool isShowToast = true,
    BuildContext? context = null,
  }) async {
    // 安卓的相册权限对应的是存储权限
    if (Platform.isAndroid && permissions.contains(Permission.photos)) {
      permissions.remove(Permission.photos);
      permissions.add(Permission.storage);
    }
    for (var item in permissions.toList()) {
      var isGranted = await item.isGranted && await item.isLimited;

      if (isGranted) {
        permissions.remove(item);
        if (permissCallBack != null) {
          permissCallBack(permissions);
        }
      }
    }

    if (permissions.isEmpty) {
      return true;
    }
    List<Permission> pDenieds = [];
    for (var item in permissions) {
      if (await item.isPermanentlyDenied) {
        pDenieds.add(item);
      }
    }
    if (!isShowToast && Platform.isIOS) return pDenieds.isEmpty;
    if (pDenieds.isNotEmpty) {
      var name = Permissions().getPermissionsName(pDenieds);
      openSettingPopup(name);
      return false;
    }
    try {
      await permissions.request();
    } catch (e) {
      return false;
    }
    List<Permission> noGranteds = [];
    for (var item in permissions) {
      if (await item.isGranted == false && await item.isLimited == false) {
        noGranteds.add(item);
      } else {
      }
    }
    if (!isShowToast) return noGranteds.isEmpty;
    if (noGranteds.isNotEmpty) {
      var name = Permissions().getPermissionsName(noGranteds);
      openSettingPopup(name);
      return false;
    }
    return true;
  }

  // 获取权限名
  String getPermissionName(Permission p) {
    String name = "";
    if (p.value == Permission.calendar.value) {
      name = localized(permissionCalendar);
    } else if (p.value == Permission.contacts.value) {
      name = localized(permissionContact);
    } else if (p.value == Permission.camera.value) {
      name = localized(permissionCamera);
    } else if (p.value == Permission.photos.value) {
      name = localized(permissionGallery);
    } else if (p.value == Permission.storage.value) {
      name = localized(permissionStorage);
    } else if(p.value == Permission.notification.value){
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
