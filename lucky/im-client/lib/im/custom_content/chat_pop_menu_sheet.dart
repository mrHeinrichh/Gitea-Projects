import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/chat.dart';
import 'package:im/im_plugin.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/report_bottom_sheet.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/desktop_forward_container.dart';
import 'package:pasteboard/pasteboard.dart';
import '../../routes.dart';
import '../../utils/im_toast/im_bottom_toast.dart';
import '../../utils/lang_util.dart';
import '../../views_desktop/component/delete_message_context.dart';
import '../../views_desktop/component/desktop_general_button.dart';
import '../../views_desktop/component/desktop_general_dialog.dart';

class ChatPopMenuSheet extends StatefulWidget {
  final Message message;
  final Chat chat;
  final int sendID;
  final List<MessagePopupOption> options;

  const ChatPopMenuSheet({
    Key? key,
    required this.message,
    required this.chat,
    required this.sendID,
    this.options = const [],
  }) : super(key: key);

  static List<ToolOptionModel> getFilteredOptionList(
      Message message, Chat chat) {
    List<ToolOptionModel> _originalOptionList = [
      ToolOptionModel(
        title: localized(reply),
        optionType: MessagePopupOption.reply.optionType,
        imageUrl: 'assets/svgs/menu_reply.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(copy),
        optionType: MessagePopupOption.copy.optionType,
        imageUrl: 'assets/svgs/menu_copy.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsTranslate),
        optionType: MessagePopupOption.translate.optionType,
        imageUrl: 'assets/svgs/menu_translate.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(retry),
        optionType: MessagePopupOption.retry.optionType,
        icon: Icons.send_outlined,
        color: JXColors.primaryTextBlack,
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
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(showInText),
        optionType: MessagePopupOption.showInText.optionType,
        imageUrl: 'assets/svgs/menu_text.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatPin),
        optionType: MessagePopupOption.pin.optionType,
        imageUrl: 'assets/svgs/menu_pin.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(findInChat),
        optionType: MessagePopupOption.findInChat.optionType,
        icon: Icons.find_in_page_outlined,
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(forward),
        optionType: MessagePopupOption.forward.optionType,
        imageUrl: 'assets/svgs/menu_forward.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(chatOptionsShare),
        optionType: MessagePopupOption.share.optionType,
        imageUrl: 'assets/svgs/menu_share.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(saveToDownload),
        optionType: MessagePopupOption.saveToDownload.optionType,
        imageUrl: 'assets/svgs/download.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: false,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(report),
        optionType: MessagePopupOption.report.optionType,
        imageUrl: 'assets/svgs/menu_report.svg',
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: !objectMgr.userMgr.isMe(message.send_id),
        tabBelonging: 1,
        subOptions: [
          ToolOptionModel(
            title: localized(violence),
            optionType: ReportPopupOption.violence.optionType,
            imageUrl: 'assets/svgs/reportIcon1.svg',
            largeDivider: false,
            color: JXColors.primaryTextBlack,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(drugs),
            optionType: ReportPopupOption.drugs.optionType,
            imageUrl: 'assets/svgs/reportIcon2.svg',
            largeDivider: false,
            color: JXColors.primaryTextBlack,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(gambling),
            optionType: ReportPopupOption.gambling.optionType,
            imageUrl: 'assets/svgs/reportIcon3.svg',
            largeDivider: false,
            color: JXColors.primaryTextBlack,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(pornography),
            optionType: ReportPopupOption.pornography.optionType,
            imageUrl: 'assets/svgs/reportIcon4.svg',
            largeDivider: false,
            color: JXColors.primaryTextBlack,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(scams),
            optionType: ReportPopupOption.scams.optionType,
            imageUrl: 'assets/svgs/reportIcon5.svg',
            largeDivider: false,
            color: JXColors.primaryTextBlack,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(others).capitalize!,
            optionType: ReportPopupOption.others.optionType,
            imageUrl: 'assets/svgs/othersIcon.svg',
            largeDivider: false,
            color: JXColors.primaryTextBlack,
            isShow: true,
            tabBelonging: 1,
          ),
        ],
      ),
      ToolOptionModel(
        title: localized(delete),
        optionType: MessagePopupOption.delete.optionType,
        imageUrl: 'assets/svgs/menu_bin.svg',
        color: errorColor,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
        subOptions: [
          ToolOptionModel(
            title: localized(deleteForEveryone),
            optionType: DeletePopupOption.deleteForEveryone.optionType,
            largeDivider: false,
            color: errorColor,
            isShow: true,
            tabBelonging: 1,
          ),
          ToolOptionModel(
            title: localized(deleteForMe),
            optionType: DeletePopupOption.deleteForMe.optionType,
            color: errorColor,
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
                _originalOptionList.firstWhereOrNull((element) =>
                    element.optionType ==
                    MessagePopupOption.forward.optionType);
            if (forwardOption != null) {
              forwardOption.isShow = false;
            }
          }

          if (!GroupPermissionMap.groupPermissionSendTextVoice
              .isAllow(controller.permission.value)) {
            ToolOptionModel? replyOption = _originalOptionList.firstWhereOrNull(
                (element) =>
                    element.optionType == MessagePopupOption.reply.optionType);
            if (replyOption != null) {
              replyOption.isShow = false;
            }
          }

          if (!controller.pinEnable.value) {
            ToolOptionModel? pinOption = _originalOptionList.firstWhereOrNull(
                (element) =>
                    element.optionType == MessagePopupOption.pin.optionType);
            if (pinOption != null) {
              pinOption.isShow = false;
            }
          }
        }
      }
    }

    ChatContentController contentController =
        Get.find<ChatContentController>(tag: chat.id.toString());

    return _originalOptionList.map<ToolOptionModel>((e) {
      if (contentController.chatController.isPinnedOpened) {
        if (e.optionType == MessagePopupOption.reply.optionType ||
            e.optionType == MessagePopupOption.copy.optionType ||
            e.optionType == MessagePopupOption.retry.optionType ||
            e.optionType == MessagePopupOption.forward.optionType ||
            e.optionType == MessagePopupOption.saveToDownload.optionType ||
            e.optionType == MessagePopupOption.delete.optionType ||
            e.optionType == MessagePopupOption.share.optionType) {
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
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }
        }

        // if (willExpired || isSendingMsg || isFailedMsg) {
        if (isSendingMsg || isFailedMsg) {
          if (e.optionType == MessagePopupOption.forward.optionType ||
              e.optionType == MessagePopupOption.delete.optionType ||
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }
        }

        if (isFailedMsg) {
          if (e.optionType == MessagePopupOption.retry.optionType ||
              e.optionType == MessagePopupOption.delete.optionType ||
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = true;
          }
        }

        if (isSmallSecretary &&
            (e.optionType == MessagePopupOption.reply.optionType ||
                e.optionType == MessagePopupOption.share.optionType)) {
          e.isShow = false;
        }
      }

      if (isReminder) {
        e.isShow = false;
        if (e.optionType == MessagePopupOption.copy.optionType ||
            e.optionType == MessagePopupOption.delete.optionType ||
            e.optionType == MessagePopupOption.forward.optionType) {
          e.isShow = true;
        }
      }

      switch (message.typ) {
        case messageTypeImage:
        case messageTypeVideo:
        case messageTypeReel:
        case messageTypeFile:
        case messageTypeVoice:
          if (e.optionType == MessagePopupOption.translate.optionType) {
            var messageContent = jsonDecode(message.content);
            if (notBlank(messageContent['caption'])) {
              e.isShow = true; //default false
            }
          }

          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType) {
            e.isShow = false; //default false
          }

          if (message.typ == messageTypeReel &&
              (e.optionType == MessagePopupOption.forward.optionType ||
                  e.optionType == MessagePopupOption.share.optionType)) {
            e.isShow = false;
          }

          if (message.typ == messageTypeVoice &&
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }

          if (message.typ == messageTypeVoice &&
              e.optionType == MessagePopupOption.playbackDevice.optionType) {
            e.isShow = true;
          }

          if (message.typ == messageTypeVoice &&
              e.optionType == MessagePopupOption.showInText.optionType) {
            e.isShow = true;
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

          return e;
        case messageTypeRecommendFriend:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType)
            e.isShow = false;
          return e;
        case messageTypeText:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.share.optionType)
            e.isShow = false;

          if (e.optionType == MessagePopupOption.translate.optionType) {
            e.isShow = true;
          }
          return e;
        case messageTypeFace:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType)
            e.isShow = false;

          return e;
        case messageTypeGif:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType)
            e.isShow = false;

          return e;
        case messageTypeSendRed:
          if (e.optionType == MessagePopupOption.saveToDownload.optionType ||
              e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.forward.optionType ||
              e.optionType == MessagePopupOption.pin.optionType ||
              e.optionType == MessagePopupOption.share.optionType)
            e.isShow = false;

          return e;
        case messageTypeNewAlbum:
          if (e.optionType == MessagePopupOption.copy.optionType)
            e.isShow = false;
          return e;
        case messageTypeLocation:
          if (e.optionType == MessagePopupOption.copy.optionType ||
              e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = false;
          }
          return e;
        case messageTypeLink:
          if (e.optionType == MessagePopupOption.share.optionType) {
            e.isShow = true;
          }
          return e;
        case messageTypeReply:
          if (e.optionType == MessagePopupOption.translate.optionType) {
            var messageContent = jsonDecode(message.content);
            if (notBlank(messageContent['text'])) {
              e.isShow = true; //default false
            }
          } else if (e.optionType == MessagePopupOption.share.optionType)
            e.isShow = false;
          return e;
        default:
          return e;
      }
    }).toList();
  }

  /// 长按计算坐标使用
  static double getMenuHeight(Message message, Chat chat,
      {bool extr = true, List<MessagePopupOption> options = const []}) {
    List<ToolOptionModel> optionList =
        ChatPopMenuSheet.getFilteredOptionList(message, chat);
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
        menuHeight = 41 + menuHeight;
        // if (toolOptionModel.largeDivider != null &&
        //     toolOptionModel.largeDivider!) {
        //   menuHeight = 5 + menuHeight;
        // } else {
        //   menuHeight = 1 + menuHeight;
        // }
      }
    }

    if (extr) {
      menuHeight = menuHeight + 44;
    }

    return menuHeight;
  }

  @override
  State<ChatPopMenuSheet> createState() => _ChatPopMenuSheetState();
}

class _ChatPopMenuSheetState extends State<ChatPopMenuSheet> {
  late CustomInputController inputController;
  late ChatContentController contentController;
  final isDesktop = objectMgr.loginMgr.isDesktop;
  final isMobile = objectMgr.loginMgr.isMobile;

  /// ============================== 消息长按 配置 ===============================
  List<ToolOptionModel> optionList = [];
  bool isSubList = false, _hasSelect = true;
  bool _isSend = false;

  @override
  void initState() {
    super.initState();

    inputController =
        Get.find<CustomInputController>(tag: widget.chat.id.toString());
    contentController =
        Get.find<ChatContentController>(tag: widget.chat.id.toString());

    optionList =
        ChatPopMenuSheet.getFilteredOptionList(widget.message, widget.chat);
    if (widget.options.isNotEmpty) {
      optionList = optionList
          .where((element) =>
              widget.options.any((opt) => opt.optionType == element.optionType))
          .toList();
      _hasSelect = widget.options.any((opt) =>
          opt.optionType ==
          MessagePopupOption.select.optionType); // when list involved select
    }

    final ToolOptionModel? deleteOption = optionList.firstWhereOrNull(
        (element) =>
            element.optionType == MessagePopupOption.delete.optionType);
    if (deleteOption != null) {
      if (widget.message.message_id == 0 && widget.message.isSendFail) {
        deleteOption.subOptions![0].isShow = false;
        ToolOptionModel? retryOption = optionList.firstWhereOrNull((element) =>
            element.optionType == MessagePopupOption.retry.optionType);
        if (retryOption != null) {
          retryOption.isShow = true;
          deleteOption.isShow = true;
        }
      } else {
        if (!widget.chat.isValid ||
            widget.chat.isSaveMsg ||
            widget.message.typ == messageTypeSendRed ||
            widget.chat.typ == chatTypeSmallSecretary) {
          deleteOption.subOptions![0].isShow = false;
        } else {
          if (inputController.type == chatTypeGroup) {
            final GroupChatController groupController =
                Get.find<GroupChatController>(tag: widget.chat.id.toString());

            if (groupController.isOwner) {
              if (objectMgr.userMgr.isMe(widget.message.send_id)) {
                deleteOption.subOptions![0].isShow =
                    deleteMessagePermissionCheck(widget.message);
              }
            } else if (groupController.isAdmin) {
              if (objectMgr.userMgr.isMe(widget.message.send_id)) {
                deleteOption.subOptions![0].isShow =
                    deleteMessagePermissionCheck(widget.message);
              } else if (groupController.group.value != null &&
                  groupController.group.value!.owner ==
                      widget.message.send_id) {
                deleteOption.subOptions![0].isShow = false;
              }
            } else {
              deleteOption.subOptions![0].isShow =
                  deleteMessagePermissionCheck(widget.message);
            }
          } else if (inputController.type == chatTypeSingle) {
            deleteOption.subOptions![0].isShow =
                deleteMessagePermissionCheck(widget.message);
          }
        }
      }
    }

    final ToolOptionModel? pinOption = optionList.firstWhereOrNull((element) =>
        element.optionType == MessagePopupOption.pin.optionType ||
        element.optionType == MessagePopupOption.unPin.optionType);
    if (pinOption != null) {
      final Message? pinnedMessage = contentController
          .chatController.pinMessageList
          .firstWhereOrNull((element) => element.id == widget.message.id);
      if (pinnedMessage != null) {
        pinOption.optionType = 'unpin';
        pinOption.title = localized(unpin);
      } else {
        pinOption.optionType = 'pin';
        pinOption.title = localized(pin);
      }
    }
  }

  bool deleteMessagePermissionCheck(Message message) {
    return objectMgr.userMgr.isMe(message.send_id) &&
        DateTime.now().millisecondsSinceEpoch - (message.create_time * 1000) <
            const Duration(days: 1).inMilliseconds;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onTapSecondMenu(ToolOptionModel option, Message message) {
    switch (option.optionType) {
      case 'deleteForEveryone':
        if (_isSend) {
          return;
        }
        _isSend = true;
        inputController.chatController.resetPopupWindow();
        inputController.onDeleteMessage(
          inputController.chatController.context,
          [message],
          isAll: true,
        );
        if (isDesktop) Get.back();
        break;
      case 'deleteForMe':
        if (_isSend) {
          return;
        }
        _isSend = true;
        inputController.chatController.resetPopupWindow();
        inputController.onDeleteMessage(
          inputController.chatController.context,
          [message],
          isAll: false,
        );
        if (isDesktop) Get.back();
        break;
      case 'violence':
        showReportPopup(option.optionType);
        break;
      case 'drugs':
        showReportPopup(option.optionType);
        break;
      case 'gambling':
        showReportPopup(option.optionType);
        break;
      case 'pornography':
        showReportPopup(option.optionType);
        break;
      case 'scams':
        showReportPopup(option.optionType);
        break;
      case 'others':
        showReportPopup(option.optionType);
        break;
      default:
        break;
    }
  }

  void onClick(
    String title,
  ) async {
    if (title == MessagePopupOption.select.optionType) {
      if (inputController.chatController.isSearching.value)
        inputController.chatController.isSearching.value = false;
      inputController.chatController.chooseMore.value = true;
      inputController.chatController.onChooseMessage(context, widget.message);
      inputController.chatController.resetPopupWindow();
      return;
    }

    final ToolOptionModel option = optionList.firstWhere((element) {
      return element.optionType == title;
    });

    if (isSubList) {
      onTapSecondMenu(option, widget.message);
      isSubList = false;
      return;
    }

    /// 获取到指定的option

    if (option.hasSubOption) {
      if (isDesktop) {
        inputController.chatController.resetPopupWindow();
        Get.back();
        DesktopGeneralDialog(
          context,
          widgetChild: DeleteMessageContext(
            onTapSecondMenu: onTapSecondMenu,
            message: widget.message,
          ),
        );
      } else if (isMobile) {
        optionList = option.subOptions!;
        isSubList = true;
        setState(() {});
      }
    } else {
      /// 实现对应逻辑
      switch (title) {
        case 'reply': //回复
          inputController.onReply(widget.sendID, widget.message, widget.chat);
          //切換成原生鍵盤
          gameManager.onChangeSwitchKeyboard();
          break;
        case 'copy': //复制
          if (widget.message.typ == messageTypeImage) {
            if (objectMgr.loginMgr.isDesktop) {
              MessageImage imgObj =
                  widget.message.decodeContent(cl: MessageImage.creator);
              final result = await cacheMediaMgr.downloadMedia(imgObj.url);
              if (result != null) {
                await Pasteboard.writeFiles([result]);
                Toast.showToast(localized(toastCopySuccess));
              } else {
                Toast.showToast(localized(toastCopyFailed));
              }
              Get.back();
              return;
            }
            if (widget.message.asset != null) {
              copyContent(widget.message.asset);
            } else {
              MessageImage imgObj =
                  widget.message.decodeContent(cl: MessageImage.creator);
              copyContent(imgObj.url);
            }
          } else {
            var _messageText =
                widget.message.decodeContent(cl: MessageText.creator);
            String formalizedText = ChatHelp.formalizeMentionContent(
                _messageText.text, widget.message);
            if (isDesktop) {
              Get.back();
            }
            copyToClipboard(formalizedText);
          }

          inputController.chatController.resetPopupWindow();
          break;
        case 'playbackDevice':
          VolumePlayerService.sharedInstance.playbackDevice =
              VolumePlayerService.sharedInstance.playbackDevice ==
                      AudioDevice.speaker
                  ? AudioDevice.earPiece
                  : AudioDevice.speaker;

          await VolumePlayerService.sharedInstance.setAudioSession(
            device: VolumePlayerService.sharedInstance.playbackDevice,
          );
          inputController.chatController.resetPopupWindow();
          break;
        case 'showInText':
          inputController.chatController.transcribe(widget.message);
          break;
        case 'translate':
          String content = "";
          if (widget.message.typ == messageTypeImage ||
              widget.message.typ == messageTypeVideo) {
            final messageContent = jsonDecode(widget.message.content);
            content = messageContent['caption'];
          } else {
            var _messageText =
                widget.message.decodeContent(cl: MessageText.creator);
            content = _messageText.text;
          }
          String formalizedText =
              ChatHelp.formalizeMentionContent(content, widget.message);
          inputController.chatController.translateMessage(formalizedText);
          break;
        case 'pin':
        case 'unpin':
          if (option.optionType == 'pin') {
            if (contentController.chatController.pinMessageList.length > 99) {
              ImBottomToast(Routes.navigatorKey.currentContext!,
                  title: localized(maxPin), icon: ImBottomNotifType.pin);
              break;
            }
            objectMgr.chatMgr.onPinMessage(
              inputController.chatController.chat.id,
              widget.message.message_id,
            );
          } else {
            objectMgr.chatMgr.onUnpinMessage(
              inputController.chatController.chat.id,
              widget.message.message_id,
            );
          }
          inputController.chatController.resetPopupWindow();
          break;
        case 'findInChat':
          inputController.chatController.resetPopupWindow();
          Get.back();
          Future.delayed(const Duration(milliseconds: 300), () {
            /// have to delay for some times to close the pop up and scroll
            inputController.chatController.showMessageOnScreen(
                widget.message.chat_idx,
                widget.message.id,
                widget.message.create_time);
            inputController.chatController.onCreateHighlightTimer();
          });

          break;
        case 'forward': //转发
          inputController.chatController.resetPopupWindow();
          objectMgr.chatMgr.replyMessageMap.remove(widget.chat.id);
          inputController.chatController
              .chooseMessage[widget.message.message_id] = widget.message;

          inputController.chatController.chooseMore.value = false;

          if (isMobile)
            inputController.onForwardMessage();
          else if (isDesktop) {
            Get.back();
            DesktopGeneralDialog(
              context,
              widgetChild: await DesktopForwardContainer(chat: widget.chat),
            );
          }
          break;
        //下载
        case 'saveToDownload':
          if (isDesktop) {
            inputController.chatController.resetPopupWindow();
            desktopDownloadMgr.desktopDownload(
              widget.message,
              context,
            );
          }
          break;
        case 'retry': //重发
          inputController.chatController.resetPopupWindow();
          if (widget.message.message_id == 0 &&
              widget.message.sendState == MESSAGE_SEND_FAIL) {
            contentController.chatController.removeMessage(widget.message);
            objectMgr.chatMgr.mySendMgr.onResend(widget.message);
          }
          break;
        case 'share':
          objectMgr.shareMgr.shareMessage(context, widget.message);
          contentController.chatController.resetPopupWindow();
          break;
      }
      if (isDesktop && (title != 'copy' && title != 'forward')) {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: EdgeInsets.only(
          left: objectMgr.userMgr.isMe(widget.message.send_id) ||
                  widget.chat.isSingle
              ? 0
              : 40,
        ),
        width: isDesktop ? 250 : 220,
        child: Container(
          decoration: jxDimension.chatPopMenuDecoration(),
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: optionList.length,
                itemBuilder: (BuildContext context, int index) {
                  if (optionList[index].isShow == false)
                    return const SizedBox();
                  final Widget childWidget = OverlayEffect(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: isDesktop ? 0 : 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: optionList[index].optionType == 'delete' ||
                                  (optionList.length - 1) == index ||
                                  contentController
                                      .chatController.isPinnedOpened
                              ? BorderSide.none
                              : BorderSide(
                                  color: JXColors.outlineColor,
                                  width:
                                      (optionList[index].largeDivider != null &&
                                              optionList[index].largeDivider!)
                                          ? 5.0
                                          : 1.0,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              optionList[index].title,
                              style: isDesktop
                                  ? jxTextStyle.textStyle13(
                                      color: optionList[index].color ??
                                          accentColor)
                                  : jxTextStyle.textStyle16(
                                      color: optionList[index].color ??
                                          accentColor),
                            ),
                          ),
                          if (optionList[index].icon != null)
                            Icon(
                              optionList[index].icon,
                              color: optionList[index].color ?? accentColor,
                              size: isDesktop ? 16 : 24.0,
                            ),
                          if (optionList[index].imageUrl != null)
                            SvgPicture.asset(
                              optionList[index].imageUrl!,
                              width: isDesktop ? 16 : 24,
                              height: isDesktop ? 16 : 24,
                              color: optionList[index].color ?? accentColor,
                            ),
                        ],
                      ),
                    ),
                  );
                  if (isMobile)
                    return GestureDetector(
                      onTap: () => onClick(optionList[index].optionType),
                      child: childWidget,
                    );
                  else
                    return ElevatedButtonTheme(
                        data: ElevatedButtonThemeData(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: JXColors.outlineColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0.0,
                          ),
                        ),
                        child: ElevatedButton(
                            onPressed: () {
                              onClick(optionList[index].optionType);
                            },
                            child: childWidget));
                  return DesktopGeneralButton(
                    horizontalPadding: 0,
                    onPressed: () => onClick(optionList[index].optionType),
                    child: childWidget,
                  );
                },
              ),
              if (!isSubList &&
                  _hasSelect &&
                  !contentController.chatController.isPinnedOpened &&
                  !isDesktop)
                GestureDetector(
                  onTap: () => onClick(MessagePopupOption.select.optionType),
                  child: OverlayEffect(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: JXColors.outlineColor,
                            width: 5.0,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(localized(select),
                              style: jxTextStyle.textStyle16(
                                  color: JXColors.primaryTextBlack)),
                          SvgPicture.asset(
                            'assets/svgs/menu_select.svg',
                            width: 24,
                            height: 24,
                            color: JXColors.primaryTextBlack,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void showReportPopup(String optionType) {
    inputController.chatController.resetPopupWindow();
    // showModalBottomSheet(
    //   context: context,
    //   isDismissible: true,
    //   isScrollControlled: true,
    //   backgroundColor: Colors.transparent,
    //   builder: (BuildContext context) {
    //     return ReportBottomSheet(
    //       confirmCallback: (String feedback) {
    //         Navigator.pop(context);
    //         onConfirmReport(optionType, feedback);
    //       },
    //     );
    //   },
    // );

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return ReportBottomSheet(
          confirmCallback: (String feedback) {
            Navigator.pop(context);
            onConfirmReport(optionType, feedback);
          },
          cancelCallback: () => Navigator.pop(context),
        );
      },
    );
  }

  Future<void> onConfirmReport(String type, String feedback) async {
    final res = await reportIssue(
        widget.chat.chat_id, widget.message.message_id, type, feedback);
    if (res) {
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(weWillReviewYourReport),
          icon: ImBottomNotifType.success);
    }
  }
}
