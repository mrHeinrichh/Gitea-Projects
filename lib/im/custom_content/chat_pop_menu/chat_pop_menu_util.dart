import 'dart:convert';

import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';

enum ChatPopMenuSheetType {
  // 聊天气泡
  chatPopMenuSheetChatBubble,
  // 群组详情
  chatPopMenuSheetGroupInfo,
  // 单聊详情
  chatPopMenuSheetChatInfo,
  none,
}

enum ChatPopMenuSheetSubType {
  // 群组详情--RedPacket
  subTypeRedPacket,
  none,
}

enum MenuMediaSubType {
  subMediaImageTxt,
  subMediaVideoTxt,
  subMediaNewAlbumTxt,
  none,
}

class ChatPopMenuConfig {
  /// 1.文字
  /// 2.链接
  /// 3.emoji
  static List<List<String>> get menuConfigText {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.copy.optionType,
        MessagePopupOption.collect.optionType,
        MessagePopupOption.forward.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [
        MessagePopupOption.editMessage.optionType,
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.textToVoice.optionType,
        MessagePopupOption.translate.optionType,
        MessagePopupOption.showOriginal.optionType,
        MessagePopupOption.report.optionType,
      ],
    ];
  }

  /// 语音
  static List<List<String>> get menuConfigVoice {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.playbackDevice.optionType,
        MessagePopupOption.collect.optionType,
        MessagePopupOption.forward.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.showInText.optionType,
        MessagePopupOption.hideText.optionType,
        MessagePopupOption.translate.optionType,
        MessagePopupOption.showOriginal.optionType,
        MessagePopupOption.report.optionType,
      ],
    ];
  }

  /// 图片
  static List<List<String>> get menuConfigImage {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.saveImage.optionType,
        MessagePopupOption.collect.optionType,
        MessagePopupOption.forward.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.report.optionType,
      ],
    ];
  }

  /// 视频
  static List<List<String>> get menuConfigVideo {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.saveVideo.optionType,
        MessagePopupOption.collect.optionType,
        MessagePopupOption.forward.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.report.optionType,
      ],
    ];
  }

  /// 多媒体带文字图片
  static List<List<String>> get menuConfigImageTxt {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.saveImage.optionType,
        MessagePopupOption.collect.optionType,
        MessagePopupOption.forward.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [
        MessagePopupOption.copy.optionType,
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.translate.optionType,
        MessagePopupOption.showOriginal.optionType,
        MessagePopupOption.report.optionType,
      ],
    ];
  }

  /// 多媒体带文字视频
  static List<List<String>> get menuConfigVideoTxt {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.saveVideo.optionType,
        MessagePopupOption.collect.optionType,
        MessagePopupOption.forward.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [
        MessagePopupOption.copy.optionType,
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.translate.optionType,
        MessagePopupOption.showOriginal.optionType,
        MessagePopupOption.report.optionType,
      ],
    ];
  }

  /// 1.相册集合
  /// 2.相册集合（带文字）
  /// 3.文件
  /// 4.sticker
  /// 5.位置
  static List<List<String>> get menuConfigNewAlbum {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.collect.optionType,
        MessagePopupOption.forward.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [
        MessagePopupOption.report.optionType,
      ],
    ];
  }

  /// 红包
  /// 转账
  static List<List<String>> get menuConfigRed {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.report.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [],
    ];
  }

  /// 通话
  static List<List<String>> get menuConfigCall {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [],
    ];
  }

  /// 收藏
  static List<List<String>> get menuConfigFavourite {
    return [
      [
        MessagePopupOption.reply.optionType,
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
        MessagePopupOption.report.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [],
    ];
  }

  /// 1.失败
  /// 2.拉黑
  static List<List<String>> get menuConfigFail {
    return [
      [
        MessagePopupOption.retry.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [],
    ];
  }

  /// 发送中
  static List<List<String>> get menuConfigOnSending {
    return [
      [
        MessagePopupOption.cancelSending.optionType,
      ],
      [],
    ];
  }

  /// 不是对方好友
  static List<List<String>> get menuConfigNotFriend {
    return [
      [
        MessagePopupOption.friendRequest.optionType,
        MessagePopupOption.delete.optionType,
      ],
      [],
    ];
  }

  /// default
  static List<List<String>> get menuConfigDefault {
    return [
      [
        MessagePopupOption.delete.optionType,
      ],
      [],
    ];
  }

  /// pin
  static List<List<String>> get menuConfigPin {
    return [
      [
        MessagePopupOption.pin.optionType,
        MessagePopupOption.unPin.optionType,
      ],
      [],
    ];
  }

  /// Markdown / system message
  static List<List<String>> get menuOnlyDelete {
    return [
      [
        MessagePopupOption.delete.optionType,
      ],
      [],
    ];
  }
}

class ChatPopMenuUtil {
  static List<ToolOptionModel> getFilteredOptionListByPage(
    bool isFirstPage,
    Message message,
    Chat chat, {
    MenuMediaSubType mediaSubType = MenuMediaSubType.none,
    ChatPopMenuSheetType chatPopMenuSheetType =
        ChatPopMenuSheetType.chatPopMenuSheetChatBubble,
    ChatPopMenuSheetSubType chatPopMenuSheetSubType =
        ChatPopMenuSheetSubType.none,
  }) {
    List<ToolOptionModel> originalOptionList =
        ChatPopMenuUtil.getFilteredOptionList(
      message,
      chat,
      mediaSubType: mediaSubType,
      chatPopMenuSheetType: chatPopMenuSheetType,
      chatPopMenuSheetSubType: chatPopMenuSheetSubType,
    );

    bool isFailedMsg = message.message_id == 0 && message.isSendFail;
    bool isSendingMsg = message.message_id == 0 && message.isSendSlow;
    // bool chatIsInvalid = !chat.isValid;
    bool isStranger = false;
    ChatContentController contentController =
        Get.find<ChatContentController>(tag: chat.id.toString());

    List<ToolOptionModel> optionList = [];
    List<List<String>> menuConfigList = [];
    final List<String> keyList;

    if (contentController.chat!.typ > chatTypeSaved) {
      // 系统和AI助手只能删除
      menuConfigList = ChatPopMenuConfig.menuOnlyDelete;
    } else {
      switch (message.typ) {
        case messageTypeText:
        case messageTypeReply:
        case messageTypeReplyWithdraw:
        case messageTypeLink:
          menuConfigList = ChatPopMenuConfig.menuConfigText;
        case messageTypeVoice:
          menuConfigList = ChatPopMenuConfig.menuConfigVoice;
        case messageTypeImage:
          if (mediaSubType == MenuMediaSubType.subMediaImageTxt) {
            menuConfigList = ChatPopMenuConfig.menuConfigImageTxt;
          } else {
            menuConfigList = ChatPopMenuConfig.menuConfigImage;
          }
        case messageTypeVideo:
          if (mediaSubType == MenuMediaSubType.subMediaVideoTxt) {
            menuConfigList = ChatPopMenuConfig.menuConfigVideoTxt;
          } else {
            menuConfigList = ChatPopMenuConfig.menuConfigVideo;
          }
        case messageTypeNewAlbum:
        case messageTypeFile:
        case messageTypeFace:
        case messageTypeGif:
        case messageTypeLocation:
          menuConfigList = ChatPopMenuConfig.menuConfigNewAlbum;
        case messageTypeSendRed:
        case messageTypeTransferMoneySuccess:
          menuConfigList = ChatPopMenuConfig.menuConfigRed;
        case messageEndCall:
        case messageRejectCall:
        case messageCancelCall:
        case messageMissedCall:
        case messageBusyCall:
          menuConfigList = ChatPopMenuConfig.menuConfigCall;
        case messageTypeInBlock:
          menuConfigList = ChatPopMenuConfig.menuConfigFail;
        case messageTypeMarkdown:
          menuConfigList = ChatPopMenuConfig.menuOnlyDelete;
        case messageTypeNote:
        case messageTypeChatHistory:
          menuConfigList = ChatPopMenuConfig.menuConfigFavourite;
        // case messageTypeNotFriend:
        //   menuConfigList = ChatPopMenuConfig.menuConfigNotFriend;
        default:
          menuConfigList = ChatPopMenuConfig.menuConfigDefault;
      }
    }

    if (isFailedMsg) {
      if (!chat.isGroup) {
        User? user = objectMgr.userMgr.getUserById(chat.friend_id);
        if (user != null) {
          isStranger = !chat.isSpecialChat &&
              (user.relationship == Relationship.stranger ||
                  user.relationship == Relationship.sentRequest ||
                  user.relationship == Relationship.receivedRequest);
        }
      }
      if (isStranger) {
        menuConfigList = ChatPopMenuConfig.menuConfigNotFriend;
      } else {
        menuConfigList = ChatPopMenuConfig.menuConfigFail;
      }
    } else if (isSendingMsg) {
      menuConfigList = ChatPopMenuConfig.menuConfigOnSending;
    }

    if (contentController.chatController.isPinnedOpened) {
      menuConfigList = ChatPopMenuConfig.menuConfigPin;
    }

    int keyListNum = isFirstPage ? 0 : 1;
    keyList = menuConfigList[keyListNum];

    int index = originalOptionList.indexWhere((element) {
      if (element.optionType == MessagePopupOption.editMessage.optionType &&
          element.isShow) {
        return true;
      } else {
        return false;
      }
    });
    if (index != -1) {
      if (isFirstPage) {
        int index = keyList.indexOf(MessagePopupOption.collect.optionType);
        if (index != -1) {
          keyList[index] = MessagePopupOption.editMessage.optionType;
        }
      } else {
        int index = keyList.indexOf(MessagePopupOption.editMessage.optionType);
        if (index != -1) {
          keyList[index] = MessagePopupOption.collect.optionType;
        }
      }
    }

    for (String key in keyList) {
      for (ToolOptionModel model in originalOptionList) {
        if (model.optionType == key && model.isShow) {
          optionList.add(model);
        }
      }
    }

    if (index != -1 &&
        !isFirstPage &&
        optionList.isEmpty &&
        contentController.chat!.typ < chatTypeSaved) {
      for (ToolOptionModel model in originalOptionList) {
        if (model.optionType == MessagePopupOption.collect.optionType &&
            model.isShow) {
          optionList.add(model);
          break;
        }
      }
    }

    return optionList;
  }

  static List<ToolOptionModel> getFilteredOptionList(
    Message message,
    Chat chat, {
    MenuMediaSubType mediaSubType = MenuMediaSubType.none,
    ChatPopMenuSheetType chatPopMenuSheetType =
        ChatPopMenuSheetType.chatPopMenuSheetChatBubble,
    ChatPopMenuSheetSubType chatPopMenuSheetSubType =
        ChatPopMenuSheetSubType.none,
  }) {
    List<ToolOptionModel> originalOptionList = [
      ToolOptionModel(
        title: localized(chatOptionsReply),
        optionType: MessagePopupOption.reply.optionType,
        imageUrl: 'assets/svgs/menu_reply.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsCopy),
        optionType: MessagePopupOption.copy.optionType,
        imageUrl: 'assets/svgs/menu_copy.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsCancelSend),
        optionType: MessagePopupOption.cancelSending.optionType,
        imageUrl: 'assets/svgs/menu_cancel_send.svg',
        color: colorRed,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsSaveImage),
        optionType: MessagePopupOption.saveImage.optionType,
        imageUrl: 'assets/svgs/menu_save.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsSaveVideo),
        optionType: MessagePopupOption.saveVideo.optionType,
        imageUrl: 'assets/svgs/menu_save.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsSaveAll),
        optionType: MessagePopupOption.saveAll.optionType,
        imageUrl: 'assets/svgs/menu_save.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
          title: localized(textToVoice),
          optionType: MessagePopupOption.textToVoice.optionType,
          imageUrl: 'assets/svgs/menu_speaker.svg',
          color: colorTextPrimary,
          largeDivider: false,
          isShow: false,
          tabBelonging: 1,
          subOptions: [
            ToolOptionModel(
              title: localized(textToVoiceOriginal),
              optionType: MessagePopupOption.textToVoiceOriginal.optionType,
              largeDivider: false,
              color: colorTextPrimary,
              isShow: true,
              tabBelonging: 1,
            ),
            ToolOptionModel(
              title: localized(textToVoiceTranslation),
              optionType: MessagePopupOption.textToVoiceTranslation.optionType,
              largeDivider: false,
              color: colorTextPrimary,
              isShow: true,
              tabBelonging: 1,
            ),
          ]),
      ToolOptionModel(
        title: localized(friendRequestOption),
        optionType: MessagePopupOption.friendRequest.optionType,
        imageUrl: 'assets/svgs/friend_request.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(resendButton),
        optionType: MessagePopupOption.retry.optionType,
        imageUrl: 'assets/svgs/menu_resend.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(VolumePlayerService.sharedInstance.playbackDevice ==
                AudioDevice.speaker
            ? chatOptionsPlayInEarPiece
            : chatOptionsPlayInSpeaker),
        optionType: MessagePopupOption.playbackDevice.optionType,
        imageUrl: VolumePlayerService.sharedInstance.playbackDevice ==
                AudioDevice.speaker
            ? 'assets/svgs/menu_ear.svg'
            : 'assets/svgs/menu_speaker.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsVoiceToTxt),
        optionType: MessagePopupOption.showInText.optionType,
        imageUrl: 'assets/svgs/menu_text.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsUnVoiceToTxt),
        optionType: MessagePopupOption.hideText.optionType,
        imageUrl: 'assets/svgs/menu_untext.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsTranslate),
        optionType: MessagePopupOption.translate.optionType,
        imageUrl: 'assets/svgs/menu_translate.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsUnTranslate),
        optionType: MessagePopupOption.showOriginal.optionType,
        imageUrl: 'assets/svgs/menu_untranslate.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(buttonEdit),
        optionType: MessagePopupOption.editMessage.optionType,
        imageUrl: 'assets/svgs/menu_edit.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatPin),
        optionType: MessagePopupOption.pin.optionType,
        imageUrl: 'assets/svgs/menu_pin.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(findInChat),
        optionType: MessagePopupOption.findInChat.optionType,
        imageUrl: 'assets/svgs/menu_findInChat.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsCollect),
        optionType: MessagePopupOption.collect.optionType,
        imageUrl: 'assets/svgs/menu_collect.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(forward),
        optionType: MessagePopupOption.forward.optionType,
        imageUrl: 'assets/svgs/menu_forward.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      // ToolOptionModel(
      //   title: localized(chatOptionsShare),
      //   optionType: MessagePopupOption.share.optionType,
      //   imageUrl: 'assets/svgs/menu_share.svg',
      //   color: colorTextPrimary,
      //   largeDivider: false,
      //   isShow: true,
      //   tabBelonging: 1,
      // ),
      ToolOptionModel(
        title: localized(saveToDownload),
        optionType: MessagePopupOption.saveToDownload.optionType,
        imageUrl: 'assets/svgs/download.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(report),
        optionType: MessagePopupOption.report.optionType,
        imageUrl: 'assets/svgs/menu_report.svg',
        color: colorTextPrimary,
        largeDivider: false,
        isShow: !objectMgr.userMgr.isMe(message.send_id),
        tabBelonging: 1,
        // subOptions: [
        //   ToolOptionModel(
        //     title: localized(violence),
        //     optionType: ReportPopupOption.violence.optionType,
        //     imageUrl: 'assets/svgs/reportIcon1.svg',
        //     largeDivider: false,
        //     color: colorTextPrimary,
        //     isShow: true,
        //     tabBelonging: 1,
        //   ),
        //   ToolOptionModel(
        //     title: localized(drugs),
        //     optionType: ReportPopupOption.drugs.optionType,
        //     imageUrl: 'assets/svgs/reportIcon2.svg',
        //     largeDivider: false,
        //     color: colorTextPrimary,
        //     isShow: true,
        //     tabBelonging: 1,
        //   ),
        //   ToolOptionModel(
        //     title: localized(gambling),
        //     optionType: ReportPopupOption.gambling.optionType,
        //     imageUrl: 'assets/svgs/reportIcon3.svg',
        //     largeDivider: false,
        //     color: colorTextPrimary,
        //     isShow: true,
        //     tabBelonging: 1,
        //   ),
        //   ToolOptionModel(
        //     title: localized(pornography),
        //     optionType: ReportPopupOption.pornography.optionType,
        //     imageUrl: 'assets/svgs/reportIcon4.svg',
        //     largeDivider: false,
        //     color: colorTextPrimary,
        //     isShow: true,
        //     tabBelonging: 1,
        //   ),
        //   ToolOptionModel(
        //     title: localized(scams),
        //     optionType: ReportPopupOption.scams.optionType,
        //     imageUrl: 'assets/svgs/reportIcon5.svg',
        //     largeDivider: false,
        //     color: colorTextPrimary,
        //     isShow: true,
        //     tabBelonging: 1,
        //   ),
        //   ToolOptionModel(
        //     title: localized(others).capitalize!,
        //     optionType: ReportPopupOption.others.optionType,
        //     imageUrl: 'assets/svgs/othersIcon.svg',
        //     largeDivider: false,
        //     color: colorTextPrimary,
        //     isShow: true,
        //     tabBelonging: 1,
        //   ),
        // ],
      ),
      ToolOptionModel(
        title: localized(delete),
        optionType: MessagePopupOption.delete.optionType,
        imageUrl: 'assets/svgs/menu_bin.svg',
        color: colorRed,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
        subOptions: [
          ToolOptionModel(
            title: localized(deleteForEveryone),
            optionType: DeletePopupOption.deleteForEveryone.optionType,
            largeDivider: false,
            color: colorRed,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(deleteForMe),
            optionType: DeletePopupOption.deleteForMe.optionType,
            color: colorRed,
            largeDivider: false,
            isShow: true,
            tabBelonging: 1,
          ),
        ],
      ),
    ];

    bool isFailedMsg = message.message_id == 0 && message.isSendFail;
    bool isSendingMsg = message.message_id == 0 && message.isSendSlow;
    bool chatIsInvalid = !chat.isValid;
    bool isStranger = false;
    // bool willExpired = message.expire_time != 0;
    bool isSmallSecretary = chat.typ == chatTypeSmallSecretary;
    bool isReminder = chat.isSystem;

    // group permission
    if (chat.isGroup) {
      if (Get.isRegistered<GroupChatController>(tag: chat.id.toString())) {
        var controller = Get.find<GroupChatController>(tag: chat.id.toString());
        if (!controller.isOwner && !controller.isAdmin) {
          // is member
          // means user not member and need to check permission
          if (!GroupPermissionMap.groupPermissionForwardMessages
              .isAllow(controller.permission.value)) {
            ToolOptionModel? forwardOption =
                originalOptionList.firstWhereOrNull((element) =>
                    element.optionType ==
                    MessagePopupOption.forward.optionType);
            if (forwardOption != null) {
              forwardOption.isShow = false;
            }
          }

          if (!GroupPermissionMap.groupPermissionSendTextVoice
              .isAllow(controller.permission.value)) {
            ToolOptionModel? replyOption = originalOptionList.firstWhereOrNull(
                (element) =>
                    element.optionType == MessagePopupOption.reply.optionType);
            if (replyOption != null) {
              replyOption.isShow = false;
            }
          }

          if (!controller.pinEnable.value) {
            ToolOptionModel? pinOption = originalOptionList.firstWhereOrNull(
                (element) =>
                    element.optionType == MessagePopupOption.pin.optionType);
            if (pinOption != null) {
              pinOption.isShow = false;
            }
          }
        }
      }
    } else {
      User? user = objectMgr.userMgr.getUserById(chat.friend_id);
      if (user != null) {
        isStranger = !chat.isSpecialChat &&
            (user.relationship == Relationship.stranger ||
                user.relationship == Relationship.sentRequest ||
                user.relationship == Relationship.receivedRequest);
      }
    }
    ChatContentController contentController =
        Get.find<ChatContentController>(tag: chat.id.toString());

    return originalOptionList.map<ToolOptionModel>((e) {
      if (contentController.chatController.isPinnedOpened) {
        if (e.optionType == MessagePopupOption.pin.optionType) {
          e.isShow = true;
        } else {
          e.isShow = false;
        }
      }

      if (contentController.chatController.isPinnedOpened) {
        if (e.optionType == MessagePopupOption.reply.optionType ||
            e.optionType == MessagePopupOption.copy.optionType ||
            e.optionType == MessagePopupOption.editMessage.optionType ||
            e.optionType == MessagePopupOption.retry.optionType ||
            e.optionType == MessagePopupOption.forward.optionType ||
            e.optionType == MessagePopupOption.saveToDownload.optionType ||
            e.optionType == MessagePopupOption.delete.optionType ||
            e.optionType == MessagePopupOption.share.optionType ||
            e.optionType == MessagePopupOption.report.optionType ||
            e.optionType == MessagePopupOption.translate.optionType ||
            e.optionType == MessagePopupOption.showOriginal.optionType ||
            e.optionType == MessagePopupOption.playbackDevice.optionType ||
            e.optionType == MessagePopupOption.showInText.optionType ||
            e.optionType == MessagePopupOption.hideText.optionType ||
            e.optionType == MessagePopupOption.textToVoice.optionType ||
            e.optionType == MessagePopupOption.collect.optionType) {
          e.isShow = false;
          return e;
        }
      } else {
        if (e.optionType == MessagePopupOption.findInChat.optionType) {
          e.isShow = false;
          return e;
        }

        // if (chatIsInvalid || willExpired || isSendingMsg || isFailedMsg) {
        if (chatIsInvalid || isSendingMsg || isFailedMsg) {
          if (e.optionType == MessagePopupOption.reply.optionType ||
              e.optionType == MessagePopupOption.pin.optionType ||
              e.optionType == MessagePopupOption.share.optionType ||
              e.optionType == MessagePopupOption.translate.optionType ||
              e.optionType == MessagePopupOption.textToVoice.optionType) {
            e.isShow = false;
            return e;
          }
        }

        if (isFailedMsg) {
          if (e.optionType == MessagePopupOption.friendRequest.optionType) {
            e.isShow = isStranger;
            return e;
          }
          if (e.optionType == MessagePopupOption.retry.optionType) {
            if (isStranger) {
              e.isShow = false;
              return e;
            } else {
              e.isShow = true;
              return e;
            }
          }

          if (e.optionType == MessagePopupOption.delete.optionType ||
              e.optionType == MessagePopupOption.select.optionType) {
            e.isShow = true;
          } else {
            e.isShow = false;
          }
          return e;
        }

        if (isSendingMsg) {
          if (e.optionType == MessagePopupOption.cancelSending.optionType ||
              e.optionType == MessagePopupOption.select.optionType) {
            e.isShow = true;
          } else {
            e.isShow = false;
          }
          return e;
        }

        if (isSmallSecretary &&
            (e.optionType == MessagePopupOption.reply.optionType ||
                e.optionType == MessagePopupOption.share.optionType)) {
          e.isShow = false;
          return e;
        }
      }

      if (isReminder) {
        e.isShow = false;
        if (e.optionType == MessagePopupOption.copy.optionType ||
            e.optionType == MessagePopupOption.delete.optionType ||
            e.optionType == MessagePopupOption.forward.optionType ||
            e.optionType == MessagePopupOption.collect.optionType) {
          e.isShow = true;
          return e;
        }
      }

      TranslationModel? translationModel = message.getTranslationModel();

      // text to speech function
      if (message.isTranslatableType) {
        if (notBlank(message.messageContent)) {
          if (e.optionType == MessagePopupOption.textToVoice.optionType) {
            if (message.typ == messageTypeVoice) {
              e.isShow = false;
              return e;
            }
            // if (mediaSubType == MenuMediaSubType.subMediaImageTxt ||
            //     mediaSubType == MenuMediaSubType.subMediaVideoTxt ||
            //     mediaSubType == MenuMediaSubType.subMediaNewAlbumTxt) {
            //   e.isShow = false;
            //   return e;
            // }
            e.isShow = true;
            if (translationModel != null && translationModel.showTranslation) {
              if (translationModel.visualType ==
                  TranslationModel.showTranslationOnly) {
                e.subOptions = null;
              }
            } else {
              e.subOptions = null;
            }
            return e;
          }
        }
      }

      switch (message.typ) {
        case messageTypeImage:
          handleOptionIsShow(e, message, translationModel);
          if (e.optionType == MessagePopupOption.saveImage.optionType) {
            e.isShow = true;
          }
          if (mediaSubType == MenuMediaSubType.subMediaImageTxt) {
            if (e.optionType == MessagePopupOption.textToVoice.optionType ||
                e.optionType ==
                    MessagePopupOption.textToVoiceOriginal.optionType ||
                e.optionType ==
                    MessagePopupOption.textToVoiceTranslation.optionType ||
                // e.optionType == MessagePopupOption.translate.optionType ||
                e.optionType == MessagePopupOption.editMessage.optionType) {
              e.isShow = false;
            }
            if (e.optionType == MessagePopupOption.saveImage.optionType) {
              e.title = localized(saveButton);
            }
          }
          return e;
        case messageTypeVideo:
          handleOptionIsShow(e, message, translationModel);
          if (e.optionType == MessagePopupOption.saveVideo.optionType) {
            e.isShow = true;
          }
          if (mediaSubType == MenuMediaSubType.subMediaVideoTxt) {
            if (e.optionType == MessagePopupOption.textToVoice.optionType ||
                e.optionType ==
                    MessagePopupOption.textToVoiceOriginal.optionType ||
                e.optionType ==
                    MessagePopupOption.textToVoiceTranslation.optionType ||
                // e.optionType == MessagePopupOption.translate.optionType ||
                e.optionType == MessagePopupOption.editMessage.optionType) {
              e.isShow = false;
            }
            if (e.optionType == MessagePopupOption.saveVideo.optionType) {
              e.title = localized(saveButton);
            }
          }
          return e;
        case messageTypeReel:
        case messageTypeFile:
          handleOptionIsShow(e, message, translationModel);
          return e;
        case messageTypeVoice:
          handleOptionIsShow(e, message, translationModel);
          //需求：语音消息禁止分享
          if (e.optionType == MessagePopupOption.share.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.textToVoice.optionType ||
              e.optionType ==
                  MessagePopupOption.textToVoiceOriginal.optionType ||
              e.optionType ==
                  MessagePopupOption.textToVoiceTranslation.optionType) {
            e.isShow = false;
          }

          return e;
        case messageTypeRecommendFriend:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }
          return e;
        case messageTypeText:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }

          if (e.optionType == MessagePopupOption.editMessage.optionType &&
              isLess24Hours(message.send_time) &&
              message.isSendOk) {
            if (objectMgr.userMgr.isMe(message.send_id)) {
              e.isShow = true;
            }
          }

          var content = jsonDecode(message.content);
          if (!EmojiParser.hasOnlyEmojis(content['text'])) {
            if (translationModel != null && translationModel.showTranslation) {
              if (e.optionType == MessagePopupOption.showOriginal.optionType) {
                e.isShow = true;
              }
            } else {
              if (e.optionType == MessagePopupOption.translate.optionType) {
                e.isShow = true;
              }
            }
          }

          return e;
        case messageTypeFace:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType ||
              e.optionType == MessagePopupOption.collect.optionType) {
            e.isShow = false;
          }

          return e;
        case messageTypeGif:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType ||
              e.optionType == MessagePopupOption.collect.optionType) {
            e.isShow = false;
          }

          return e;
        case messageTypeSendRed:
        case messageTypeTransferMoneySuccess:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.forward.optionType ||
              e.optionType == MessagePopupOption.pin.optionType ||
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }

          return e;
        case messageTypeNewAlbum:
          if (translationModel != null && translationModel.showTranslation) {
            if (e.optionType == MessagePopupOption.showOriginal.optionType) {
              e.isShow = true;
            }
          } else {
            if (e.optionType == MessagePopupOption.translate.optionType) {
              var messageContent = jsonDecode(message.content);
              if (notBlank(messageContent['caption']) &&
                  !EmojiParser.hasOnlyEmojis(messageContent['caption'])) {
                e.isShow = true; //default false
              }
            }
          }

          if (e.optionType == MessagePopupOption.copy.optionType) {
            var messageContent = jsonDecode(message.content);
            e.isShow = notBlank(messageContent['caption']);
          }

          if (e.optionType == MessagePopupOption.editMessage.optionType &&
              isLess24Hours(message.send_time) &&
              message.isSendOk) {
            if (objectMgr.userMgr.isMe(message.send_id)) {
              var messageContent = jsonDecode(message.content);
              if (notBlank(messageContent['caption'])) {
                e.isShow = true; //default false
              }
            }
          }
          if (mediaSubType == MenuMediaSubType.subMediaNewAlbumTxt) {
            if (e.optionType == MessagePopupOption.textToVoice.optionType ||
                e.optionType ==
                    MessagePopupOption.textToVoiceOriginal.optionType ||
                e.optionType ==
                    MessagePopupOption.textToVoiceTranslation.optionType ||
                e.optionType == MessagePopupOption.translate.optionType ||
                e.optionType == MessagePopupOption.editMessage.optionType) {
              e.isShow = false;
            }
          }
          if (e.optionType == MessagePopupOption.forward.optionType) {
            e.title = localized(chatOptionsForwardAll);
          }
          if (e.optionType == MessagePopupOption.select.optionType) {
            e.title = localized(chatOptionsSelectAll);
          }
          return e;
        case messageTypeLocation:
          if (e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }
          return e;
        case messageTypeLink:
          if (translationModel != null && translationModel.showTranslation) {
            if (e.optionType == MessagePopupOption.showOriginal.optionType) {
              e.isShow = true;
            }
          } else {
            if (e.optionType == MessagePopupOption.translate.optionType) {
              e.isShow = true;
            }
          }

          if (e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = true;
          }

          if (e.optionType == MessagePopupOption.editMessage.optionType &&
              isLess24Hours(message.send_time) &&
              message.isSendOk) {
            if (objectMgr.userMgr.isMe(message.send_id)) {
              e.isShow = true;
            }
          }
          return e;
        case messageTypeReply:
          if (translationModel != null && translationModel.showTranslation) {
            if (e.optionType == MessagePopupOption.showOriginal.optionType) {
              e.isShow = true;
            }
          } else {
            if (e.optionType == MessagePopupOption.translate.optionType) {
              var messageContent = jsonDecode(message.content);
              if (notBlank(messageContent['text']) &&
                  !EmojiParser.hasOnlyEmojis(messageContent['text'])) {
                e.isShow = true; //default false
              }
            }
          }
          if (e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }
          if (e.optionType == MessagePopupOption.editMessage.optionType &&
              isLess24Hours(message.send_time) &&
              message.isSendOk) {
            if (objectMgr.userMgr.isMe(message.send_id)) {
              e.isShow = true;
            }
          }
          return e;

        // case messageTypeVoice:
        //   if (e.optionType == MessagePopupOption.share.optionType)
        //     e.isShow = false;
        //   return e;
        default:
          return e;
      }
    }).toList();
  }

  /// 长按计算坐标使用
  static double getMenuHeight(
    Message message,
    Chat chat, {
    bool extr = true,
    List<MessagePopupOption> options = const [],
    MenuMediaSubType mediaSubType = MenuMediaSubType.none,
    ChatPopMenuSheetType chatPopMenuSheetType =
        ChatPopMenuSheetType.chatPopMenuSheetChatBubble,
    ChatPopMenuSheetSubType chatPopMenuSheetSubType =
        ChatPopMenuSheetSubType.none,
  }) {
    List<ToolOptionModel> optionList =
        ChatPopMenuUtil.getFilteredOptionListByPage(
      true,
      message,
      chat,
      mediaSubType: mediaSubType,
      chatPopMenuSheetType: chatPopMenuSheetType,
      chatPopMenuSheetSubType: chatPopMenuSheetSubType,
    );
    List<ToolOptionModel> optionListSec =
        ChatPopMenuUtil.getFilteredOptionListByPage(
      true,
      message,
      chat,
      mediaSubType: mediaSubType,
      chatPopMenuSheetType: chatPopMenuSheetType,
      chatPopMenuSheetSubType: chatPopMenuSheetSubType,
    );
    if (options.isNotEmpty) {
      optionList = optionList
          .where((element) =>
              options.any((opt) => opt.optionType == element.optionType))
          .toList();
    }

    double menuHeight = 0;
    for (int i = 0; i < optionList.length; i++) {
      ToolOptionModel toolOptionModel = optionList[i];
      if (toolOptionModel.isShow) {
        menuHeight = 44 + menuHeight;
        // if (toolOptionModel.largeDivider != null &&
        //     toolOptionModel.largeDivider!) {
        //   menuHeight = 5 + menuHeight;
        // } else {
        //   menuHeight = 1 + menuHeight;
        // }
      }
    }

    if (extr || optionListSec.isNotEmpty) {
      menuHeight = 51 + menuHeight + 51;
    }

    return menuHeight;
  }

  static void handleOptionIsShow(
      ToolOptionModel e, Message message, TranslationModel? translationModel) {
    if (translationModel != null && translationModel.showTranslation) {
      if (e.optionType == MessagePopupOption.showOriginal.optionType) {
        e.isShow = true;
      }
    } else {
      if (e.optionType == MessagePopupOption.translate.optionType) {
        var messageContent = jsonDecode(message.content);
        if (notBlank(messageContent['caption']) &&
            !EmojiParser.hasOnlyEmojis(messageContent['caption'])) {
          e.isShow = true; //default false
        }
      }
    }

    if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
        e.optionType == MessagePopupOption.copy.optionType) {
      e.isShow = false; //default false
    }

    /*  if (message.typ == messageTypeReel &&
        (e.optionType == MessagePopupOption.forward.optionType ||
            e.optionType == MessagePopupOption.share.optionType)) {
      e.isShow = false;
    }*/

    if (message.typ == messageTypeVoice) {
      if (e.optionType == MessagePopupOption.share.optionType ||
          e.optionType == MessagePopupOption.playbackDevice.optionType) {
        e.isShow = true;
      }

      var content = jsonDecode(message.content);
      if (content['transcribe'] != null && content['transcribe'] != '') {
        if (e.optionType == MessagePopupOption.copy.optionType) {
          e.isShow = true;
        }

        if (e.optionType == MessagePopupOption.hideText.optionType) {
          e.isShow = true;
        }

        if (translationModel != null && translationModel.showTranslation) {
          if (e.optionType == MessagePopupOption.showOriginal.optionType) {
            e.isShow = true;
          }
        } else {
          if (e.optionType == MessagePopupOption.translate.optionType) {
            e.isShow = true;
          }
        }
      } else {
        if (e.optionType == MessagePopupOption.showInText.optionType) {
          e.isShow = true;
        }
      }
    }

    if (e.optionType == MessagePopupOption.copy.optionType) {
      var messageContent = jsonDecode(message.content);
      if (notBlank(messageContent['caption'])) {
        e.isShow = true;
      }
    }

    if (e.optionType == MessagePopupOption.editMessage.optionType &&
        isLess24Hours(message.send_time) &&
        message.isSendOk) {
      var messageContent = jsonDecode(message.content);
      if (objectMgr.userMgr.isMe(message.send_id) &&
          notBlank(messageContent['caption'])) {
        e.isShow = true;
      }
    }

    if (objectMgr.loginMgr.isDesktop &&
        (e.optionType == MessagePopupOption.saveToDownload.optionType ||
            e.optionType == MessagePopupOption.share.optionType)) {
      e.isShow = true;
    }

    if (objectMgr.loginMgr.isDesktop &&
        e.optionType == MessagePopupOption.copy.optionType &&
        message.typ == messageTypeImage) {
      e.isShow = true;
    }
  }
}
