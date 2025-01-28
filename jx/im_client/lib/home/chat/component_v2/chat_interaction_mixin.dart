import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';

mixin ChatInteractionMixin {
  final double maxChatCellHeight = 76;

  /// 是否允许 操作 delete, hide 聊天室
  bool enableEdit = true;

  /// 清楚聊天数据 (不删除聊天室)
  void onClearChat(BuildContext context, Chat chat) async {
    Widget imageWidget = const SecretaryMessageIcon(size: 60);
    if (chat.isSaveMsg) {
      imageWidget = const SavedMessageIcon(size: 60);
    } else if (chat.isSystem) {
      imageWidget = const SystemMessageIcon(size: 60);
    }

    showCustomBottomAlertDialog(
      context,
      imgWidget: imageWidget,
      content: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: localized(secondaryMenuClearMessageTipStart),
            ),
            TextSpan(
              text: getSpecialChatName(chat.typ),
              style: jxTextStyle.textStyleBold13(
                color: Colors.black,
                fontWeight: MFontWeight.bold6.value,
              ),
            ),
            TextSpan(
              text: localized(secondaryMenuClearMessageTipEnd),
            ),
          ],
        ),
        style: jxTextStyle.textStyleBold13(
          color: Colors.black,
          fontWeight: MFontWeight.bold4.value,
        ),
      ),
      confirmText: localized(secondaryMenuClearRecordOnlyForMe),
      onConfirmListener: () async {
        await objectMgr.chatMgr.clearMessage(chat);
        await objectMgr.localDB.clearMessages(chat.chat_id);

        imBottomToast(
          Get.context!,
          title: localized(deleteMyChatRecord),
          icon: ImBottomNotifType.delete,
        );
      },
    );
  }

  // 删除聊天室
  Future<void> onDeleteChat(BuildContext context, Chat? chat) async {
    showCustomBottomAlertDialog(
      context,
      imgWidget: CustomAvatar.chat(chat!, size: 60),
      content: Text(
        chat.isGroup ? localized(chatDeleteGroup) : localized(chatDeleteSingle),
        style: jxTextStyle.textStyle15(
          color: Colors.black,
        ),
      ),
      confirmText: (chat.isGroup
          ? localized(deleteGroupChat)
          : localized(deleteChatHistory)),
      onConfirmListener: () {
        objectMgr.chatMgr.onChatDelete(chat);
        bool isInChat = objectMgr.chatMgr.isInCurrentChat(chat.chat_id);
        if (isInChat) {
          Get.back();
        }

        imBottomToast(
          Get.context!,
          title: chat.isGroup
              ? localized(alrdDeleteGroup)
              : localized(alrdDeleteChat),
          icon: ImBottomNotifType.delete,
        );
      },
    );
  }

  // 隐藏聊天室
  Future<void> showHideChatDialog(BuildContext context, Chat? chat) async {
    showCustomBottomAlertDialog(
      context,
      imgWidget: CustomAvatar.chat(chat!, size: 60),
      content: Text(
        (chat.isGroup ? localized(chatHideGroup) : localized(chatHideSingle)),
        style: jxTextStyle.textStyle15(
          color: Colors.black,
        ),
      ),
      confirmText: (chat.isGroup
          ? localized(chatHideGroupConfirm)
          : localized(chatHideChat)),
      onConfirmListener: () {
        objectMgr.chatMgr.setChatHide(chat);
        Get.back();

        imBottomToast(
          Get.context!,
          title: chat.isGroup
              ? localized(chatHideGroupConfirm)
              : localized(chatHideChat),
          icon: ImBottomNotifType.INFORMATION,
        );
      },
    );
  }
}
