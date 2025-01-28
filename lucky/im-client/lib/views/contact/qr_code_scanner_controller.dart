import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/api/account.dart' as account_api;
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/login_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/views/contact/qr_code_dialog.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zxing2/qrcode.dart';

import '../../routes.dart';
import '../../utils/loading/ball.dart';
import '../../utils/loading/ball_circle_loading.dart';
import '../../utils/loading/ball_style.dart';
import '../../utils/toast.dart';
import '../../utils/utility.dart';

class QRCodeScannerController extends GetxController {
  MobileScannerController? mobileScannerController = MobileScannerController();

  String uuid = "";
  RxBool isScannable = true.obs;
  RxBool torchOn = false.obs;
  bool isBackToScanner = true;

  @override
  void onInit() {
    super.onInit();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void onClose() {
    mobileScannerController?.dispose();
    mobileScannerController = null;
    super.onClose();
  }

  @override
  void dispose() {
    mobileScannerController?.dispose();
    mobileScannerController = null;
    super.dispose();
  }

  void getDataFromQR(String? result) async {
    await mobileScannerController?.stop();

    if (torchOn.value) {
      toggleTorch();
    }
    if (result == null) {
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(scanInvalidQRCode), icon: ImBottomNotifType.warning);
      return;
    }

    /// 解析qrData
    String? userId;
    String? secretUrl;
    String? secretKey;
    User? user;
    try {
      final Map<String, dynamic> qrMap = jsonDecode(result);
      if (qrMap.containsKey(QrCodeWalletTask.taskName)) {
        QrCodeWalletTask task = QrCodeWalletTask.fromJson(qrMap);
        QrCodeWalletTask.currentTask = task;
        if (qrMap.containsKey('address')) {
          String address = qrMap["address"];
          Get.toNamed(RouteName.withdrawView, arguments: {'data': 'USDT'});
        } else {
          Get.toNamed(RouteName.transferView, arguments: {
            'isFromQRCode': true,
            'accountId': qrMap["profile"] ?? '',
          });
        }
        return;
      }
      if (qrMap.containsKey("profile")) {
        userId = qrMap["profile"];
        try {
          user = await account_api.getUser(userId: userId);
        } catch (e) {
          String errorMessage = localized(unexpectedError);
          if (e is AppException) {
            errorMessage = e.getMessage();
          }
          ImBottomToast(Routes.navigatorKey.currentContext!,
              title: errorMessage, icon: ImBottomNotifType.warning);

          await Future.delayed(const Duration(seconds: 3), () {
            mobileScannerController?.start();
          });
        }
      }
      if (qrMap.containsKey("secretUrl")) {
        secretUrl = qrMap["secretUrl"];
      }
      if (qrMap.containsKey("login")) {
        secretKey = qrMap["login"];
      }

      if (userId != null && secretUrl != null) {
        if (user != null) {
          if (objectMgr.userMgr.mainUser.uid == user.uid) {
            ImBottomToast(Routes.navigatorKey.currentContext!,
                title: localized(cannotAddYourselfAsAFriend),
                icon: ImBottomNotifType.warning);
            await Future.delayed(const Duration(seconds: 3), () {
              mobileScannerController?.start();
            });
            return;
          }
          try {
            final res =
                await acceptFriendRequest(uuid: userId, secretUrl: secretUrl);
            if (res) {
              user.relationship = Relationship.friend;
              ImBottomToast(Routes.navigatorKey.currentContext!,
                  title: localized(areFriendNow,
                      params: ['${objectMgr.userMgr.getUserTitle(user)}']),
                  icon: ImBottomNotifType.success);
              Chat? chat = await objectMgr.chatMgr.getChatByFriendId(user.uid);
              if (chat != null) {
                Routes.toChat(chat: chat);
              }
            }
          } catch (_) {
            if (_ is AppException) {
              if (_.getPrefix() == ErrorCodeConstant.STATUS_IN_FRIEND) {
                ImBottomToast(Routes.navigatorKey.currentContext!,
                    title: localized(youAndAlreadyFriend, params: [
                      '${objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(user.uid))}'
                    ]),
                    icon: ImBottomNotifType.success);
                Chat? chat =
                    await objectMgr.chatMgr.getChatByFriendId(user.uid);
                if (chat != null) {
                  Routes.toChat(chat: chat);
                }
              } else {
                String errorMessage = localized(scanInvalidQRCode);
                if (_.getPrefix() ==
                    ErrorCodeConstant.STATUS_FRIEND_QUOTA_EXCEED) {
                  errorMessage =
                      localized(failedToAddYouHaveReachedTheFriendLimit);
                } else if (_.getPrefix() ==
                    ErrorCodeConstant.STATUS_TARGET_USER_FRIEND_QUOTA_EXCEED) {
                  errorMessage =
                      localized(failedToAddTheUserHaveReachedTheFriendLimit);
                }
                ImBottomToast(Routes.navigatorKey.currentContext!,
                    title: errorMessage, icon: ImBottomNotifType.warning);

                await Future.delayed(const Duration(seconds: 3), () {
                  mobileScannerController?.start();
                });
              }
            }
          }
        }
      } else if (userId != null) {
        if (user != null) {
          Get.offNamed(RouteName.chatInfo, arguments: {"uid": user.uid});
        }
      } else if (secretKey != null) {
        final res = await account_api.authoriseDesktopLogin(secretKey);
        if (res) {
          objectMgr.loginMgr.event(
            objectMgr.loginMgr,
            LoginMgr.eventLinkDevice,
            data: res,
          );
          Toast.showToast(
            localized(deviceLinkedSuccess),
            duration: const Duration(milliseconds: 2000),
          );
          Get.back();
        }
      }
    } catch (e) {
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(scanInvalidQRCode), icon: ImBottomNotifType.warning);
      mobileScannerController?.start();
    }
  }

  void toggleTorch() {
    mobileScannerController?.toggleTorch();
    torchOn.value = !torchOn.value;
  }

  getImage(BuildContext context) async {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
          color: Colors.black.withOpacity(0.5),
          height: MediaQuery.of(context).size.height,
          child: const BallCircleLoading(
            radius: 20,
            ballStyle: BallStyle(
              size: 10,
              color: Colors.white,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: Colors.white,
            ),
          ),
        );
      },
    );
    if (torchOn.value) {
      toggleTorch();
    }
    if (Platform.isAndroid) {
      var storagePermission =
          await Permissions.request([Permission.storage], context: context);
      if (!storagePermission) {
        return;
      }
      var mediaPermission = await Permissions.request(
          [Permission.accessMediaLocation],
          context: context);
      if (!mediaPermission) {
        return;
      }
    } else {
      var photosPermission =
          await Permissions.request([Permission.photos], context: context);
      if (!photosPermission) {
        return;
      }
    }

    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    overlayState.insert(overlayEntry);

    if (pickedFile != null) {
      try {
        final result = await decodeQRCode(pickedFile.path);
        overlayEntry.remove();

        if (result != null) {
          getDataFromQR(result);
        } else {
          ImBottomToast(Routes.navigatorKey.currentContext!,
              title: localized(scanInvalidQRCode),
              icon: ImBottomNotifType.warning);
        }
      } catch (e) {
        if (e is ReaderException) {
          ImBottomToast(Routes.navigatorKey.currentContext!,
              title: localized(scanInvalidQRCode),
              icon: ImBottomNotifType.warning);
        } else {
          pdebug(e.toString());
        }
        overlayEntry.remove();
      }
    } else {
      overlayEntry.remove();
    }
  }

  void restartScanner() {
    mobileScannerController?.dispose();
    mobileScannerController = null;
    Future.delayed(const Duration(milliseconds: 300), () {
      mobileScannerController = MobileScannerController();
      mobileScannerController?.start();
    });
  }

  void qrCodePopUp(BuildContext context) {
    mobileScannerController?.stop();
    qrCodeDialog(context, onCloseClick: (){
      if (isBackToScanner) {
        mobileScannerController?.start();
      }
    });
  }

  void qrMoneyCodePopUp(BuildContext context) {
    mobileScannerController?.stop();
    qrCodeDialogMyMoneyCode(context, onCloseClick: (){
      if (isBackToScanner) {
        mobileScannerController?.start();
      }
    });
  }
}
