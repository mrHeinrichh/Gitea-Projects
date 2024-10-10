import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/api/account.dart' as account_api;
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/api/group_invite_link.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/join_invitation_bottom_sheet.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/login_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/contact/qr_code_dialog.dart';
import 'package:jxim_client/views/contact/qr_code_wallet.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zxing2/qrcode.dart';

class QRCodeScannerController extends GetxController {
  MobileScannerController? mobileScannerController = MobileScannerController();

  String uuid = "";
  RxBool isScannable = true.obs;
  RxBool torchOn = false.obs;
  bool isBackToScanner = true;
  bool isModalBottomSheet = false;
  ScanQrCodeType? scanQrCodeType;
  RxBool showBottomButton = true.obs;
  final RxBool verificationSuccess = false.obs;
  Function()? successCallback;
  Chat? chat;

  @override
  void onInit() {
    super.onInit();
    FocusManager.instance.primaryFocus?.unfocus();
    if (Get.arguments != null) {
      if (Get.arguments['isModalBottomSheet'] != null) {
        isModalBottomSheet = Get.arguments['isModalBottomSheet'];
      }
      if (Get.arguments['type'] != null) {
        scanQrCodeType = Get.arguments['type'];
        if (scanQrCodeType == ScanQrCodeType.verifyPrivateKey) {
          showBottomButton.value = false;
        }
      }

      if (Get.arguments['chat'] != null) {
        chat = Get.arguments['chat'];
      }

      successCallback = Get.arguments["successCallback"];
    }

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

  void joinGroupAction(String inviteLink, Map<String, dynamic> params) async {
    final uid = params['uid'];
    final gid = params['gid'];
    final String? chatKey = params['chatKey'];
    bool isJoined = await objectMgr.myGroupMgr
        .isGroupMember(gid!, objectMgr.userMgr.mainUser.id);
    if (!isJoined) {
      final user = await objectMgr.userMgr.loadUserById2(uid);
      assert(user != null, 'handleGroupAction: User cannot be null');
      final relationship = user?.relationship;
      bool isFriend = relationship == Relationship.friend;
      if (chatKey != null) {
        inviteLink = ShareLinkUtil.localGenerateGroupShareLinkWithoutEncryption(inviteLink);
        params.remove('chatKey');
      }
      final groupInfo = await getGroupInfoByLink(inviteLink);
      if (groupInfo == null) {
        Toast.showToast(localized(invitaitonLinkHasExpired));
        return;
      }
      final group = Group();
      group.uid = gid;
      group.name = groupInfo.groupName ?? '';
      group.icon = groupInfo.groupIcon ?? '';
      final isConfirmed = await showModalBottomSheet<bool>(
        context: Get.context!,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return JoinInvitationBottomSheet(
            group: group,
            userName: user!.nickname,
            isFriend: isFriend,
          );
        },
      );
      if (isConfirmed == true) {
        await joinGroupByLink(gid, inviteLink);
      } else {
        mobileScannerController?.start();
        return;
      }
    }

    final chat = await objectMgr.chatMgr.getChatByGroupId(gid);

    if (chat == null) {
      Toast.showToast(localized(chatRoomNotReadyTryLater));
      return;
    }
    if (chatKey != null) {
      await objectMgr.encryptionMgr.createChatEncryption([objectMgr.userMgr.mainUser.uid], chat.id, chatKey: chatKey);
      objectMgr.chatMgr.updateEncryptionSettings(chat, chat.flag, chatKey: chatKey, sendApi: false);
    }
    Routes.toChat(chat: chat);
  }

  void getDataFromQR(String? result, BuildContext context) async {
    if (ShareLinkUtil.isMatchLink(result ?? '')) {
      final dataMap = ShareLinkUtil.collectDataFromUrl(result ?? '');
      if (dataMap['action'] == 0) {
        // 加好友
        result = jsonEncode(dataMap);
      } else if (dataMap['action'] == 1) {
        // 加群组
        joinGroupAction(result ?? '', dataMap);
        await mobileScannerController?.stop();
        if (torchOn.value) {
          toggleTorch();
        }
        return;
      }
    }

    if (scanQrCodeType != ScanQrCodeType.verifyPrivateKey) {
      await mobileScannerController?.stop();
    }

    if (torchOn.value) {
      toggleTorch();
    }
    if (result == null) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(scanInvalidQRCode),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    if (scanQrCodeType == ScanQrCodeType.verifyPrivateKey) {
      verifyPrivateKeyFromQRFlow(result, context);
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
          Get.toNamed(RouteName.withdrawView, arguments: {'data': 'USDT'});
        } else {
          Get.toNamed(
            RouteName.transferView,
            arguments: {
              'isFromQRCode': true,
              'accountId': qrMap["profile"] ?? '',
            },
          );
        }
        return;
      }
      if (qrMap.containsKey("profile")) {
        userId = qrMap["profile"];
        try {
          if (userId == null || userId.isEmpty == true) {
            throw AppException('', localized(scanInvalidQRCode), '');
          }
          user = await account_api.getUser(userId: userId);
          await objectMgr.sharedRemoteDB.applyUpdateBlock(
            UpdateBlockBean.created(
              blockOptReplace,
              DBUser.tableName,
              [user.toJson()],
            ),
            save: true,
            notify: false,
          );
        } catch (e) {
          String errorMessage = localized(unexpectedError);
          if (e is AppException) {
            errorMessage = e.getMessage();
          }
          imBottomToast(
            navigatorKey.currentContext!,
            title: errorMessage,
            icon: ImBottomNotifType.warning,
          );

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

      if (qrMap.containsKey("uid") && qrMap.containsKey("privateKey")) {
        saveEncryptionPrivateKey(qrMap['uid'],qrMap['privateKey']);
        return;
      }

      if (userId != null && secretUrl != null) {
        if (user != null) {
          if (objectMgr.userMgr.mainUser.uid == user.uid) {
            imBottomToast(
              navigatorKey.currentContext!,
              title: localized(cannotAddYourselfAsAFriend),
              icon: ImBottomNotifType.warning,
            );
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
              imBottomToast(
                navigatorKey.currentContext!,
                title: localized(
                  areFriendNow,
                  params: [(objectMgr.userMgr.getUserTitle(user))],
                ),
                icon: ImBottomNotifType.success,
              );
              Chat? chat = await objectMgr.chatMgr.getChatByFriendId(user.uid);
              if (chat != null) {
                Routes.toChat(chat: chat);
              }
            }
          } catch (e) {
            if (e is AppException) {
              if (e.getPrefix() == ErrorCodeConstant.STATUS_IN_FRIEND) {
                imBottomToast(
                  navigatorKey.currentContext!,
                  title: localized(
                    youAndAlreadyFriend,
                    params: [
                      (objectMgr.userMgr.getUserTitle(
                        objectMgr.userMgr.getUserById(user.uid),
                      )),
                    ],
                  ),
                  icon: ImBottomNotifType.success,
                );
                Chat? chat =
                    await objectMgr.chatMgr.getChatByFriendId(user.uid);
                if (chat != null) {
                  Routes.toChat(chat: chat);
                }
              } else {
                String errorMessage = localized(scanInvalidQRCode);
                if (e.getPrefix() ==
                    ErrorCodeConstant.STATUS_FRIEND_QUOTA_EXCEED) {
                  errorMessage =
                      localized(failedToAddYouHaveReachedTheFriendLimit);
                } else if (e.getPrefix() ==
                    ErrorCodeConstant.STATUS_TARGET_USER_FRIEND_QUOTA_EXCEED) {
                  errorMessage =
                      localized(failedToAddTheUserHaveReachedTheFriendLimit);
                }
                imBottomToast(
                  navigatorKey.currentContext!,
                  title: errorMessage,
                  icon: ImBottomNotifType.warning,
                );

                await Future.delayed(const Duration(seconds: 3), () {
                  mobileScannerController?.start();
                });
              }
            }
          }
        }
      } else if (userId != null) {
        if (user != null) {
          if (isModalBottomSheet) {
            if (Get.isRegistered<SearchContactController>() &&
                (user.relationship == Relationship.stranger ||
                    user.relationship == Relationship.sentRequest ||
                    user.relationship == Relationship.receivedRequest)) {
              Get.back();
              SearchContactController searchContactController =
                  Get.find<SearchContactController>();
              searchContactController.showChatInfoInSheet(user.uid, context);
            } else {
              Get.close(2);
              Get.toNamed(RouteName.chatInfo, arguments: {"uid": user.uid});
            }
          } else {
            Get.offNamed(RouteName.chatInfo, arguments: {"uid": user.uid});
          }
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
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(scanInvalidQRCode),
        icon: ImBottomNotifType.warning,
      );
      mobileScannerController?.start();
    }
  }

  bool isInVerification = false;
  void verifyPrivateKeyFromQRFlow (String result, BuildContext context) async {
    if (isInVerification) return;
    isInVerification = true;
    // var verified = await objectMgr.encryptionMgr.verifySignature(chat!, result);
    var verified = await objectMgr.encryptionMgr.verifySignedKey(chat!, result);
    verificationSuccess.value = verified;
    update();
    if (verified) {

      Future.delayed(const Duration(milliseconds: 4000), () async{
        await mobileScannerController?.stop();
        Get.back();
      });
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(chatVerificationSuccess),
        icon: ImBottomNotifType.success,
      );
    } else {
      await mobileScannerController?.stop();
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(chatVerificationFailure),
        icon: ImBottomNotifType.warning,
      );
      Get.back();
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
    if (!Platform.isAndroid) {
      var photosPermission = await Permissions.request([Permission.photos]);
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
          getDataFromQR(result, context);
        } else {
          imBottomToast(
            navigatorKey.currentContext!,
            title: localized(scanInvalidQRCode),
            icon: ImBottomNotifType.warning,
          );
        }
      } catch (e) {
        if (e is ReaderException) {
          imBottomToast(
            navigatorKey.currentContext!,
            title: localized(scanInvalidQRCode),
            icon: ImBottomNotifType.warning,
          );
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
    showQRCodeDialog(
      context,
      onCloseClick: () {
        if (isBackToScanner) {
          mobileScannerController?.start();
        }
      },
    );
  }

  void qrMoneyCodePopUp(BuildContext context) {
    mobileScannerController?.stop();
    qrCodeDialogMyMoneyCode(
      context,
      onCloseClick: () {
        if (isBackToScanner) {
          mobileScannerController?.start();
        }
      },
    );
  }

  Future<void> saveEncryptionPrivateKey(int uid, String privateKey) async {
    bool status = objectMgr.userMgr.mainUser.uid == uid;

    if (status) {
      String publicKey = objectMgr.localStorageMgr.read(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY) ?? '';
      if (publicKey == '') {
        CipherKey data = await getCipherMyKey();
        if (data.public != '') {
          publicKey = data.public!;
        }
      }

      objectMgr.encryptionMgr.saveEncryptionKey(publicKey, privateKey);
      objectMgr.encryptionMgr.decryptChat();
      if (scanQrCodeType == ScanQrCodeType.encryption) {
        Get.close(2);
      } else {
        Get.back();
      }

      if (successCallback != null) {
        successCallback?.call();
      }

      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(encryptionRecoverSuccess),
        icon: ImBottomNotifType.success,
      );
    } else {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(scanInvalidQRCode),
        icon: ImBottomNotifType.warning,
      );

      await Future.delayed(const Duration(seconds: 3), () {
        mobileScannerController?.start();
      });
    }
  }
}
