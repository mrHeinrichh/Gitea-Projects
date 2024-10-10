import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/api/group_invite_link.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/group_invite_link.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/utils/config.dart';

final cachedLinks = <int, String>{};

class GroupInviteLinkController extends GetxController {
  final validLinks = <GroupInviteLink>[].obs;
  final invalidLinks = <GroupInviteLink>[].obs;
  final downloadLink = '${Config().officialUrl}downloads/';

  // 永久有效的链接
  String permalink = '';
  final _permalinkInfo = GroupInviteLink().obs;

  set permalinkInfo(GroupInviteLink value) => _permalinkInfo.value = value;

  GroupInviteLink get permalinkInfo => _permalinkInfo.value;

  final TextEditingController linkAliasInputController =
      TextEditingController();
  final List<String> effectiveTimeLimitHeaderList =
      GroupLinkEffectiveTime.getLocales(localized);
  final List<String> usageLimitHeaderList =
      GroupLinkUsageLimit.getLocales(localized);
  int selectedEffectiveTime = 1;
  int selectedUsageLimit = 1;
  bool isEdit = false;
  final effectiveTimeSliderSubValue = ''.obs;
  final usageLimitSliderSubValue = 0.obs;
  final isJoined = false.obs;
  final _selectedGroupInviteLink = GroupInviteLink().obs;

  set selectedGroupInviteLink(GroupInviteLink value) =>
      _selectedGroupInviteLink.value = value;

  GroupInviteLink get selectedGroupInviteLink => _selectedGroupInviteLink.value;

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  int? get groupId => groupInfoController?.groupId;

  int get userId => objectMgr.userMgr.mainUser.uid;

  String get copyLink {
    final item = selectedGroupInviteLink;
    final copyLink = (item.name == null || item.name?.isEmpty == true)
        ? item.link
        : '${item.name} ${item.link}';
    return copyLink ?? '';
  }

  Group? get group => groupInfoController?.group.value;
  String shareQRFilePath = '';

  final _isSaveButtonEnabled = false.obs;

  bool get isSaveButtonEnabled => _isSaveButtonEnabled.value;

  set setIsSaveButtonEnabled(bool isEnabled) {
    _isSaveButtonEnabled.value = isEnabled;
  }

  @override
  void onInit() {
    initCachedLinks();
    objectMgr.myGroupMgr
        .isGroupMember(groupId!, objectMgr.userMgr.mainUser.id)
        .then((bool value) {
      isJoined.value = value;
    });
    getGroupInviteLinks().then((links) {
      if (links.isEmpty) {
        generatePermanentGroupLink();
      }
    });
    super.onInit();
  }

  @override
  onClose() {
    linkAliasInputController.dispose();
    super.onClose();
  }

  void initCachedLinks() {
    if (cachedLinks[groupId] == null) {
      permalink = ShareLinkUtil.generateGroupShareLink(userId, groupId);
      cachedLinks[groupId!] = permalink;
    } else {
      permalink = cachedLinks[groupId]!;
    }
    permalinkInfo = GroupInviteLink(
      id: 0,
      groupId: groupId,
      uid: userId,
      link: permalink,
      used: 0,
      status: STATUS.valid,
      limited: 0,
      duration: 0,
      expireTime: 0,
    );
  }

  Message createGroupLinkMessage() {
    final msg = MessageGroupLink();
    final user = objectMgr.userMgr.mainUser;
    msg.user_id = user.uid;
    msg.nick_name = user.nickname;
    msg.group_id = group?.id ?? 0;
    msg.group_name = group?.name ?? '';
    msg.group_profile = group?.profile ?? '';
    msg.short_link = permalinkInfo.link ?? '';

    Message message = Message();
    message.content = jsonEncode(msg);
    message.typ = messageTypeGroupLink;

    return message;
  }

  Widget forwardContainer() {
    Message message = createGroupLinkMessage();
    return ForwardContainer(
      forwardMsg: [message],
      onSaveAction: onCopyLink,
      onShareAction: shareLinkToAnotherApp,
    );
  }

  // 生成永久有效的链接
  void generatePermanentGroupLink() async {
    assert(groupId != null,
        'generatePermanentGroupLink: groupId id cannot be null!');
    if (cachedLinks[groupId] == null) {
      permalink = ShareLinkUtil.generateGroupShareLink(userId, groupId);
      cachedLinks[groupId!] = permalink;
    } else {
      permalink = cachedLinks[groupId]!;
    }
    permalinkInfo = await createGroupLink(
      groupId!,
      '',
      permalink,
      0,
      0,
    );

    selectedGroupInviteLink = permalinkInfo;
  }

  void filterPermanentGroupLink(List<GroupInviteLink> links) {
    final permanentLink = links.reduce(
        (GroupInviteLink a, GroupInviteLink b) => a.id! < b.id! ? a : b);

    permalink = permanentLink.link ?? '';
    permalinkInfo = permanentLink;
  }

  void updatePermalink() {
    permalinkInfo.name = linkAliasInputController.text;
    updateGroupLink(
      linkAliasInputController.text,
      permalink,
      0,
      0,
    ).then((res) async {
      await imBottomToast(
        navigatorKey.currentContext!,
        title: localized(invitationLinkUpdateSuccess),
        icon: ImBottomNotifType.success,
      );
      Get.back();
      permalinkInfo = res;
      selectedGroupInviteLink = res;
    });
  }

  Future<List<GroupInviteLink>> getGroupInviteLinks(
      {bool isUpdate = false}) async {
    assert(groupId != null, 'getGroupInviteLinks: groupId id cannot be null!');
    List<GroupInviteLink> allLinks = [];
    allLinks = await getGroupLinks(groupId!);
    if (allLinks.isEmpty) return <GroupInviteLink>[];
    filterPermanentGroupLink(allLinks);

    if (!isUpdate) {
      selectedGroupInviteLink = permalinkInfo;
    }

    validLinks.clear();
    invalidLinks.clear();

    for (var element in allLinks) {
      if (element.link == permalink) continue;
      final time = DateTime.now().millisecondsSinceEpoch;
      bool isValidUsed =
          (element.used! < element.limited! && element.limited != 0) ||
              element.limited == 0;
      bool isValidTime =
          (time < (element.expireTime! * 1000)) || element.expireTime == 0;
      bool isValidStatus = element.status == STATUS.valid;
      bool isValid = isValidUsed && isValidTime && isValidStatus;
      if (isValid) {
        validLinks.add(element);
      } else {
        invalidLinks.add(element);
      }
    }
    return allLinks;
  }

  void createGroupShareLink() {
    assert(groupId != null, 'createGroupShareLink: groupId id cannot be null!');
    final link = ShareLinkUtil.generateGroupShareLink(userId, groupId);
    createGroupLink(
      groupId!,
      linkAliasInputController.text,
      link,
      selectedUsageLimit,
      selectedEffectiveTime,
    ).then((_) async {
      await imBottomToast(
        navigatorKey.currentContext!,
        title: localized(invitationLinkCreateSuccess),
        icon: ImBottomNotifType.success,
      );
      Get.back();
      getGroupInviteLinks(isUpdate: true);
    });
  }

  void updateGroupShareLink() {
    assert(groupId != null, 'updateGroupShareLink: groupId id cannot be null!');
    assert(selectedGroupInviteLink.duration != null,
        'updateGroupShareLink: selectedGroupInviteLink.duration cannot be null!');
    assert(selectedGroupInviteLink.limited != null,
        'updateGroupShareLink: selectedGroupInviteLink.limited cannot be null!');
    updateGroupLink(
      linkAliasInputController.text,
      selectedGroupInviteLink.link ?? '',
      selectedUsageLimit,
      selectedEffectiveTime,
    ).then((res) async {
      await imBottomToast(
        navigatorKey.currentContext!,
        title: localized(invitationLinkUpdateSuccess),
        icon: ImBottomNotifType.success,
      );
      Get.back();
      getGroupInviteLinks(isUpdate: true);
      selectedGroupInviteLink = res;
    });
  }

  void onEffectiveTimeSliderChanged(double value) {
    selectedEffectiveTime =
        GroupLinkEffectiveTime.getValueByType(value.toInt());
    calcEffectiveTimeSliderSubValue();
  }

  void onUsageLimitSliderChanged(double value) {
    selectedUsageLimit = GroupLinkUsageLimit.getValueByType(value.toInt());
    calcUsageLimitSliderSubValue();
  }

  void calcEffectiveTimeSliderSubValue() {
    if (selectedEffectiveTime == 0) {
      effectiveTimeSliderSubValue.value = localized(none);
      return;
    }
    final timestamp =
        DateTime.now().millisecondsSinceEpoch + (selectedEffectiveTime) * 1000;
    final newDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
    String formattedDate = formatter.format(newDate);
    effectiveTimeSliderSubValue.value = formattedDate;
  }

  void calcUsageLimitSliderSubValue() {
    if (isEdit) {
      if (selectedUsageLimit == 0) {
        usageLimitSliderSubValue.value = selectedUsageLimit;
        return;
      }
      if (selectedGroupInviteLink.used! == 0) {
        usageLimitSliderSubValue.value = selectedUsageLimit;
        return;
      }
      final remainCount =
          selectedGroupInviteLink.limited! - selectedGroupInviteLink.used!;
      if (selectedUsageLimit == selectedGroupInviteLink.limited!) {
        usageLimitSliderSubValue.value = remainCount;
      } else if (selectedUsageLimit > selectedGroupInviteLink.limited!) {
        usageLimitSliderSubValue.value = selectedUsageLimit + remainCount;
      } else {
        usageLimitSliderSubValue.value = remainCount - selectedUsageLimit;
        usageLimitSliderSubValue.value = usageLimitSliderSubValue.value < 0
            ? 0
            : usageLimitSliderSubValue.value;
      }
    } else {
      usageLimitSliderSubValue.value = selectedUsageLimit;
    }
  }

  void deleteAllInvalidLinks() {
    assert(groupId != null, 'updateGroupShareLink: groupId id cannot be null!');
    deleteInvalidGroupLink(groupId!).then((int code) {
      String title = '';
      if (code == 0) {
        title = localized(invitationLinkDeleateSuccess);
      } else if (code == 1) {
        title = localized(invitationLinkDeleateFailed);
      }
      imBottomToast(
        navigatorKey.currentContext!,
        title: title,
        icon: code == 0 ? ImBottomNotifType.success : ImBottomNotifType.warning,
      );
      getGroupInviteLinks(isUpdate: true);
    });
  }

  void revokeGroupLink() {
    assert(selectedGroupInviteLink.id != null,
        'updateGroupShareLink: selectedGroupInviteLink.id cannot be null!');
    cancelGroupLink(selectedGroupInviteLink.id!).then((int code) async {
      String title = '';
      if (code == 0) {
        title = localized(invitationLinkRevokeSuccess);
      } else if (code == 1) {
        title = localized(invitationLinkRevokeFailed);
      }
      await imBottomToast(
        navigatorKey.currentContext!,
        title: title,
        icon: code == 0 ? ImBottomNotifType.success : ImBottomNotifType.warning,
      );
      Get.back();
      Get.back();
      getGroupInviteLinks(isUpdate: true);
    });
  }

  Future<void> downloadQR(Widget widget, int uid) async {
    if (objectMgr.loginMgr.isDesktop) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageDownloading),
        icon: ImBottomNotifType.loading,
      );
      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      desktopDownloadMgr.desktopSaveTo(
        'MY-HeyTalk-QR.jpg',
        bytes,
        navigatorKey.currentContext!,
      );
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageSaved),
        icon: ImBottomNotifType.qrSaved,
      );
    } else {
      getGroupCardFile(widget, uid);
    }
  }

  Future<String?> getGroupCardFile(Widget widget, int uid,
      {bool isShare = false}) async {
    final Permission permission = defaultTargetPlatform == TargetPlatform.iOS
        ? Permission.photos
        : Permission.storage;
    final PermissionStatus status = await permission.status;
    final bool rationale = await permission.shouldShowRequestRationale;
    if (status.isGranted) {
      if (!isShare) { // don't show bottom sheet on sharing mode
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(imageDownloading),
          icon: ImBottomNotifType.loading,
        );
      }

      String cachePath = await downloadMgr.getTmpCachePath(
        "${uid}_groupcard.jpg",
        sub: "groupcard",
        create: false,
      );
      final file = File(cachePath);

      if (!file.existsSync() || !isShare) {
        final controller = ScreenshotController();
        final bytes =
        await controller.captureFromWidget(Material(child: widget));

        file.createSync(recursive: true);
        file.writeAsBytesSync(bytes);

        ImageGallerySaver.saveImage(
          bytes,
          quality: 100,
          name: 'image_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(imageSaved),
          icon: ImBottomNotifType.qrSaved,
        );
      }

      if (isShare) { // on sharing mode, send to other platform
        await Share.shareXFiles(
          [XFile(cachePath)],
          text: localized(
            invitationWithLink,
            params: [Config().appName, downloadLink],
          ),
        );
      }

      return cachePath;
    } else {
      if (rationale || status.isPermanentlyDenied) {
        openAppSettings();
      } else {
        await permission.request();
      }
    }
    return null;
  }

  Future<String> forwardGroupViaQR(Widget widget, int uid) async {
    String cachePath = await downloadMgr.getTmpCachePath(
      "${uid}_groupcard.jpg",
      sub: "groupcard",
      create: false,
    );
    final file = File(cachePath);

    if (!file.existsSync()) {
      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      File(cachePath).createSync(recursive: true);
      File(cachePath).writeAsBytesSync(bytes);
    }

    shareQRFilePath = cachePath;
    return cachePath;
  }

  void onCopyLink() {
    copyToClipboard(copyLink);
    imBottomToast(
      Get.context!,
      title: localized(copyInvitationLinkSuccess),
      icon: ImBottomNotifType.copy,
    );
  }

  void shareLinkToAnotherApp(Message message) {
    MessageGroupLink groupLink =
        message.decodeContent(cl: MessageGroupLink.creator);
    Share.share(groupLink.short_link);
  }
}
