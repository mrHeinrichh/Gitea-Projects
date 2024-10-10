import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/api/chat.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet_menu_effect.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/chat_reacted_users_widget.dart';
import 'package:jxim_client/im/custom_content/chat_seen_users_widget.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/report_bottom_sheet.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/delete_message_context.dart';
import 'package:jxim_client/views_desktop/component/desktop_forward_container.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

class ChatPopMenuSheet extends StatefulWidget {
  final Message message;
  final Chat chat;
  final int sendID;
  final List<MessagePopupOption> options;
  final MenuMediaSubType mediaSubType;
  final ChatPopMenuSheetType chatPopMenuSheetType;
  final ChatPopMenuSheetSubType chatPopMenuSheetSubType;

  const ChatPopMenuSheet({
    super.key,
    required this.message,
    required this.chat,
    required this.sendID,
    this.options = const [],
    this.mediaSubType = MenuMediaSubType.none,
    this.chatPopMenuSheetType = ChatPopMenuSheetType.chatPopMenuSheetChatBubble,
    this.chatPopMenuSheetSubType = ChatPopMenuSheetSubType.none,
  });

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
  List<ToolOptionModel> optionListFir = [];
  List<ToolOptionModel> optionListSec = [];
  bool isSubList = false, _hasSelect = true;
  bool _isSend = false;

  ChatInfoController? get chatInfoController =>
      Get.isRegistered<ChatInfoController>()
          ? Get.find<ChatInfoController>()
          : null;

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  bool get shouldShowSeen =>
      widget.chatPopMenuSheetType ==
          ChatPopMenuSheetType.chatPopMenuSheetChatBubble &&
      _seenUsersMap.isNotEmpty &&
      isFirstMenuPage;

  final LinkedHashMap<User, String> _emojiUsersMap = LinkedHashMap();
  final LinkedHashMap<User, String> _seenUsersMap = LinkedHashMap();

  int get _emojiUserCount => _emojiUsersMap.length;

  bool isShowSeenList = false;

  bool isFirstMenuPage = true;

  bool isShowMore = true;

  int touchIndex = -1;

  final FlipCardController _flipCardController = FlipCardController();

  void onToggleSeenList() {
    EasyDebounce.debounce(
        'chat_pop_menu_ToggleSeen_click', const Duration(milliseconds: 200),
        () {
      if (mounted) {
        setState(() {
          isShowSeenList = !isShowSeenList;
        });
      }
    });
  }

  void _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
    if (data is Message) {
      if (widget.message.chat_id == data.chat_id &&
          data.id == widget.message.id) {
        getSeenUsers();
      }
    }
  }

  void _updateReadMessage(sender, type, data) {
    if (data != null) {
      if (data['id'] == widget.chat.id && data['other_read_idx'] != null) {
        getSeenUsers();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventReadMessage, _updateReadMessage);

    getSeenUsers();

    inputController =
        Get.find<CustomInputController>(tag: widget.chat.id.toString());
    contentController =
        Get.find<ChatContentController>(tag: widget.chat.id.toString());

    optionListFir = ChatPopMenuUtil.getFilteredOptionListByPage(
      true,
      widget.message,
      widget.chat,
      mediaSubType: widget.mediaSubType,
      chatPopMenuSheetType: widget.chatPopMenuSheetType,
      chatPopMenuSheetSubType: widget.chatPopMenuSheetSubType,
    );
    optionListSec = ChatPopMenuUtil.getFilteredOptionListByPage(
      false,
      widget.message,
      widget.chat,
      mediaSubType: widget.mediaSubType,
      chatPopMenuSheetType: widget.chatPopMenuSheetType,
      chatPopMenuSheetSubType: widget.chatPopMenuSheetSubType,
    );
    optionList = optionListFir;

    if (optionListSec.isEmpty) {
      isShowMore = false;
    }
    if (widget.options.isNotEmpty) {
      optionList = optionList
          .where(
            (element) => widget.options
                .any((opt) => opt.optionType == element.optionType),
          )
          .toList();
      _hasSelect = widget.options.any(
        (opt) => opt.optionType == MessagePopupOption.select.optionType,
      ); // when list involved select
    }

    _updateOptionStatus();
  }

  void _updateOptionStatus() {
    final ToolOptionModel? deleteOption = optionList.firstWhereOrNull(
      (element) => element.optionType == MessagePopupOption.delete.optionType,
    );
    if (deleteOption != null) {
      if (widget.message.message_id == 0 && widget.message.isSendFail) {
        deleteOption.subOptions![0].isShow = false;
        deleteOption.isShow = true;
      } else {
        if (!widget.chat.isValid ||
            widget.chat.isSaveMsg ||
            widget.message.typ == messageTypeSendRed ||
            widget.message.typ == messageTypeTransferMoneySuccess ||
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

    final ToolOptionModel? pinOption = optionList.firstWhereOrNull(
      (element) =>
          element.optionType == MessagePopupOption.pin.optionType ||
          element.optionType == MessagePopupOption.unPin.optionType,
    );
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
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventReadMessage, _updateReadMessage);
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
      case 'cancelSending':
        if (_isSend) {
          return;
        }
        _isSend = true;
        inputController.chatController.resetPopupWindow();
        inputController.onCancelSendingMessage(
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
      case 'textToVoiceOriginal':
        inputController.chatController.convertTextToVoice(message);
        break;
      case 'textToVoiceTranslation':
        inputController.chatController
            .convertTextToVoice(message, isTranslation: true);
        break;
      default:
        break;
    }
  }

  void onClickMore(String title) async {
    EasyDebounce.debounce(
        'chat_pop_menu_more_click', const Duration(milliseconds: 200), () {
      isFirstMenuPage = !isFirstMenuPage;
      optionList = isFirstMenuPage ? optionListFir : optionListSec;
      _updateOptionStatus();
      if (mounted) {
        setState(() {
          Future.delayed(const Duration(milliseconds: 50), () {
            _flipCardController.toggleCard();
          });
        });
      }
    });
  }

  void onClick(String title) async {
    EasyDebounce.debounce(
        'chat_pop_menu_title_click', const Duration(milliseconds: 200),
        () async {
      bool isFailedMsg =
          widget.message.message_id == 0 && widget.message.isSendFail;
      bool isSendingMsg =
          widget.message.message_id == 0 && widget.message.isSendSlow;

      // 红包、转账、通话、失败、发送中，下面的 删除和举报 不进入多选
      if (!(widget.message.typ == messageTypeSendRed ||
          widget.message.typ == messageTypeMarkdown ||
          widget.message.typ == messageTypeTransferMoneySuccess ||
          widget.message.typ == messageEndCall ||
          widget.message.typ == messageRejectCall ||
          widget.message.typ == messageCancelCall ||
          widget.message.typ == messageMissedCall ||
          widget.message.typ == messageBusyCall ||
          isFailedMsg ||
          isSendingMsg)) {
        if (title == MessagePopupOption.forward.optionType ||
            title == MessagePopupOption.delete.optionType ||
            title == MessagePopupOption.collect.optionType) {
          if (inputController.chatController.isSearching.value) {
            inputController.chatController.isSearching.value = false;
          }
          inputController.chatController.chooseMore.value = true;
          if (title == MessagePopupOption.collect.optionType) {
            inputController.chatController.isEnableFavourite.value = true;
          }
          inputController.chatController
              .onChooseMessage(context, widget.message);
          inputController.chatController.resetPopupWindow();
          return;
        }
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
          desktopGeneralDialog(
            context,
            widgetChild: DeleteMessageContext(
              onTapSecondMenu: onTapSecondMenu,
              message: widget.message,
            ),
          );
        } else if (isMobile) {
          optionList = option.subOptions!;
          isSubList = true;
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        /// 实现对应逻辑
        switch (title) {
          case 'cancelSending': // 本地删除
            onTapSecondMenu(option, widget.message);
          case 'reply': //回复
            inputController.onReply(widget.sendID, widget.message, widget.chat);
            break;
          case 'copy': //复制
            if (objectMgr.loginMgr.isDesktop) {
              if (widget.message.typ == messageTypeImage ||
                  widget.message.typ == messageTypeVideo ||
                  widget.message.typ == messageTypeReel ||
                  widget.message.typ == messageTypeNewAlbum ||
                  widget.message.typ == messageTypeFile) {
                final imgObj = widget.message.decodeContent(
                  cl: widget.message.getMessageModel(widget.message.typ),
                );
                final result = await cacheMediaMgr.downloadMedia(imgObj.url);
                if (result != null) {
                  await Pasteboard.writeFiles([result]);
                  Toast.showToast(localized(toastCopySuccess));
                } else {
                  Toast.showToast(localized(toastCopyFailed));
                }
                Get.back();
                return;
              } else {
                var messageText =
                    widget.message.decodeContent(cl: MessageText.creator);
                String formalizedText = ChatHelp.formalizeMentionContent(
                  messageText.text,
                  widget.message,
                );
                if (isDesktop) {
                  Get.back();
                }
                copyToClipboard(formalizedText);
              }
            } else {
              copyToClipboard(widget.message.textAfterMentionWithTranslation);
            }

            inputController.chatController.resetPopupWindow();
            break;
          case 'editMessage':
            inputController.onEdit(widget.sendID, widget.message, widget.chat);
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
          case 'hideText':
            inputController.chatController.hideTranscribe(widget.message);
            break;
          case 'translate':
            inputController.chatController.translateMessage(widget.message);
            break;
          case 'showOriginal':
            inputController.chatController.showOriginalMessage(widget.message);
            break;
          case 'pin':
          case 'unpin':
            if (option.optionType == 'pin') {
              if (contentController.chatController.pinMessageList.length > 99) {
                imBottomToast(
                  navigatorKey.currentContext!,
                  title: localized(maxPin),
                  icon: ImBottomNotifType.pin,
                  isStickBottom: false,
                );
                break;
              }
              objectMgr.chatMgr.localPinMessage(
                true,
                inputController.chatController.chat.id,
                widget.message,
              );

              objectMgr.chatMgr.onPinMessage(
                inputController.chatController.chat.id,
                widget.message.message_id,
              );
            } else {
              objectMgr.chatMgr.localPinMessage(
                false,
                inputController.chatController.chat.id,
                widget.message,
              );
              objectMgr.chatMgr.onUnpinMessage(
                inputController.chatController.chat.id,
                widget.message.message_id,
              );
            }
            inputController.chatController.resetPopupWindow();
            break;
          case 'findInChat':
            _findInChatAction();

            break;
          case 'forward': //转发
            await _forwardAction();
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
          case 'saveImage':
          case 'saveVideo':
            saveMessageMedia(context, widget.message,
                isFromChatRoom: true, isVideo: title == 'saveVideo');
            inputController.chatController.resetPopupWindow();
          case 'retry': //重发
            inputController.chatController.resetPopupWindow();
            if (widget.message.message_id == 0 &&
                widget.message.sendState == MESSAGE_SEND_FAIL) {
              contentController.chatController.removeMessage(widget.message);
              objectMgr.chatMgr.mySendMgr.onResend(widget.message);
            }
            break;
          case 'share':
            objectMgr.shareMgr
                .shareMessage(context, widget.message, isFromChatRoom: true);
            contentController.chatController.resetPopupWindow();
            break;
          case 'textToVoice':
            inputController.chatController.convertTextToVoice(widget.message);
            break;
          case 'friendRequest':
            inputController.chatController.showFriendRequestSheet();
            break;
          case 'report':
            _showReportPopUpList(context);
            contentController.chatController.resetPopupWindow();
            break;
        }
        if (isDesktop && (title != 'copy' && title != 'forward')) {
          Get.back();
        }
      }
    });
  }

  void _findInChatAction() {
    inputController.chatController.resetPopupWindow();
    Get.back();
    Future.delayed(const Duration(milliseconds: 300), () {
      /// have to delay for some times to close the pop up and scroll
      inputController.chatController.showMessageOnScreen(
        widget.message.chat_idx,
        widget.message.id,
        widget.message.create_time,
      );
      inputController.chatController.onCreateHighlightTimer();
    });
  }

  Future<void> _forwardAction() async {
    inputController.chatController.resetPopupWindow();
    objectMgr.chatMgr.replyMessageMap.remove(widget.chat.id);
    inputController.chatController.chooseMessage[widget.message.message_id] =
        widget.message;

    inputController.chatController.chooseMore.value = false;

    if (isMobile) {
      inputController.onForwardMessage();
    } else if (isDesktop) {
      Get.back();
      desktopGeneralDialog(
        context,
        widgetChild: DesktopForwardContainer(chat: widget.chat),
      );
    }
  }

  Future<void> saveMessageMedia(
    BuildContext context,
    Message message, {
    bool isFromChatRoom = false,
    bool isVideo = false,
  }) async {
    final (List<File?> cacheFileList, String? albumMessage) = await objectMgr
        .shareMgr
        .getShareFile(message, isFromChatRoom: isFromChatRoom);
    List<XFile> fileList = [];
    for (File? cacheFile in cacheFileList) {
      if (cacheFile != null && cacheFile.existsSync()) {
        fileList.add(XFile(cacheFile.path));
      }
    }
    if (fileList.isEmpty) {
      imBottomToast(
        context,
        title: localized(albumMessage ??
            (isVideo ? toastHavenDownload : toastSaveUnsuccessful)),
        icon: ImBottomNotifType.warning,
        isStickBottom: false,
      );
    } else {
      final fileObj = fileList.first;
      saveMedia(fileObj.path);
    }
  }

  saveMedia(String path, {bool isReturnPathOfIOS = false}) async {
    final result = await ImageGallerySaver.saveFile(
      path,
      isReturnPathOfIOS: isReturnPathOfIOS,
    );

    if (result != null && result["isSuccess"]) {
      imBottomToast(
        Get.context!,
        title: localized(toastSaveSuccess),
        icon: ImBottomNotifType.saving,
        duration: 3,
        isStickBottom: false,
      );
    } else {
      _onSaveFailToast(context);
    }
  }

  void _onSaveFailToast(BuildContext context) {
    BotToast.removeAll(BotToast.textKey);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(toastTryLater),
          subTitle: localized(toastSaveUnsuccessfulWaitVideoDownload),
          confirmButtonColor: colorRed,
          cancelButtonColor: themeColor,
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonConfirm),
          cancelCallback: Navigator.of(context).pop,
          confirmCallback: () {},
        );
      },
    );
  }

  Widget _buildSeen() {
    final isMe = objectMgr.userMgr.isMe(widget.message.send_id);

    return OverlayEffectMenu(
      isHighLight: touchIndex == 0,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 16,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorBorder,
                width: 7.0,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                _emojiUserCount == 0
                    ? 'assets/svgs/menu_seen.svg'
                    : 'assets/svgs/menu_like.svg',
                // 'assets/svgs/menu_seen.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  colorTextPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _emojiUserCount == 0
                      ? localized(
                          commonSeen,
                          params: [_seenUsersMap.length.toString()],
                        )
                      : isMe
                          ? localized(
                              commonReacted,
                              params: [
                                _emojiUserCount.toString(),
                                _seenUsersMap.length.toString(),
                              ],
                            )
                          : localized(
                              commonReactedNotMe,
                              params: [
                                _emojiUserCount.toString(),
                              ],
                            ),
                  style: jxTextStyle.textStyle17(
                    color: colorTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ChatSeenUsersWidget(
                _emojiUsersMap.isNotEmpty ? _emojiUsersMap : _seenUsersMap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactedUsers() {
    final userList = _seenUsersMap.entries.toList();

    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          OverlayEffectMenu(
            isHighLight: touchIndex == 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorBorder,
                    width: 7.0,
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/svgs/menu_back.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      colorTextPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localized(buttonBack),
                    style: jxTextStyle.textStyle17(
                      color: colorTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ChatReactedUsersWidget(
            users: userList,
          ),
        ],
      ),
    );
  }

  int getMenuNum() {
    int num = optionList.length;
    if (shouldShowSeen) {
      num = num + 1;
    }
    if (isShowMore) {
      num = num + 1;
    }
    return num;
  }

  int getMenuEqualNum(int index) {
    if (shouldShowSeen) {
      return index - 1;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      flipOnTouch: false,
      speed: 200,
      controller: _flipCardController,
      front: _buildMenuContainer(),
      back: _buildMenuContainer(),
    );
  }

  Widget _buildMenuContainer() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: EdgeInsets.only(
          left: objectMgr.userMgr.isMe(widget.message.send_id) ||
                  widget.chat.isSingle
              ? 0
              : 40,
        ),
        width: isDesktop ? 250 : 240,
        child: ChatPopMenuSheetMenuEffect(
          num: getMenuNum(),
          index: touchIndex,
          isShowSeen: shouldShowSeen,
          isShowMore: isShowMore,
          isNeedVibrate: !isShowSeenList,
          itemTouchUpDown: (index) {
            bool isInMenuArea = false;
            if (index != -1) {
              isInMenuArea = true;
            }
            objectMgr.stickerMgr.onChatPopMenuAreaEvent(isInMenuArea);
          },
          itemTouch: (index) {
            if (mounted) {
              setState(() {
                touchIndex = index;
              });
            }
          },
          itemTouchEnd: (index) {
            objectMgr.stickerMgr.onChatPopMenuAreaEvent(false);
            if (index < 0 || index >= getMenuNum()) {
              return;
            }
            if (isShowSeenList && index != 0) {
              return;
            }
            if (shouldShowSeen) {
              if (index == 0) {
                // 表情点击
                onToggleSeenList();
              } else if (index == (getMenuNum() - 1) && isShowMore) {
                // 最后一个是否是更多，点击
                onClickMore(MessagePopupOption.menuMore.optionType);
              } else {
                onClick(optionList[index - 1].optionType);
              }
            } else {
              if (index == (getMenuNum() - 1) && isShowMore) {
                // 最后一个是否是更多，点击
                onClickMore(MessagePopupOption.menuMore.optionType);
              } else {
                onClick(optionList[index].optionType);
              }
            }
            touchIndex = -1;
          },
          child: Container(
            decoration: jxDimension.chatPopMenuDecoration(),
            child: isShowSeenList
                ? _buildReactedUsers()
                : Column(
                    children: [
                      if (shouldShowSeen && optionList == optionListFir)
                        _buildSeen(),
                      ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: optionList.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (optionList[index].isShow == false) {
                            return const SizedBox();
                          }
                          final Widget childWidget = OverlayEffectMenu(
                            isHighLight: index == getMenuEqualNum(touchIndex),
                            child: Container(
                              height: 44,
                              padding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: isDesktop ? 0 : 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: optionList[index].optionType ==
                                              'delete' ||
                                          (optionList.length - 1) == index ||
                                          contentController
                                              .chatController.isPinnedOpened
                                      ? BorderSide.none
                                      : BorderSide(
                                          color: colorBorder,
                                          width:
                                              (optionList[index].largeDivider !=
                                                          null &&
                                                      optionList[index]
                                                          .largeDivider!)
                                                  ? 5.0
                                                  : 1.0,
                                        ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      optionList[index].title,
                                      style: isDesktop
                                          ? jxTextStyle.textStyle13(
                                              color: optionList[index].color ??
                                                  themeColor,
                                            )
                                          : jxTextStyle.textStyle17(
                                              color: optionList[index].color ??
                                                  themeColor,
                                            ),
                                    ),
                                  ),
                                  if (optionList[index].icon != null)
                                    Icon(
                                      optionList[index].icon,
                                      color:
                                          optionList[index].color ?? themeColor,
                                      size: isDesktop ? 16 : 24.0,
                                    ),
                                  if (optionList[index].imageUrl != null)
                                    SvgPicture.asset(
                                      optionList[index].imageUrl!,
                                      width: isDesktop ? 16 : 24,
                                      height: isDesktop ? 16 : 24,
                                      color:
                                          optionList[index].color ?? themeColor,
                                    ),
                                ],
                              ),
                            ),
                          );
                          if (isMobile) {
                            return GestureDetector(
                              onTap: () =>
                                  onClick(optionList[index].optionType),
                              child: childWidget,
                            );
                          } else {
                            return ElevatedButtonTheme(
                              data: ElevatedButtonThemeData(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  surfaceTintColor: colorBorder,
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
                                child: childWidget,
                              ),
                            );
                          }
                        },
                      ),
                      if (!isSubList &&
                          _hasSelect &&
                          !contentController.chatController.isPinnedOpened &&
                          !isDesktop &&
                          isShowMore)
                        GestureDetector(
                          onTap: () => onClickMore(
                            MessagePopupOption.menuMore.optionType,
                          ),
                          child: OverlayEffectMenu(
                            isHighLight: touchIndex == getMenuNum() - 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 16,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: colorBorder,
                                    width: 7.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    localized(chatOptionsMoreMenu),
                                    style: jxTextStyle.textStyle16(
                                      color: colorTextPrimary,
                                    ),
                                  ),
                                  // SvgPicture.asset(
                                  //   'assets/svgs/menu_select.svg',
                                  //   width: 24,
                                  //   height: 24,
                                  //   color: colorTextPrimary,
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReportPopup(String optionType) async {
    // inputController.chatController.resetPopupWindow();

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

  Future<void> _showReportPopUpList(BuildContext context) async {
    inputController.chatController.resetPopupWindow();
    List<String> reportList =
        ReportPopupOption.values.map((e) => e.name).toList();

    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: List.generate(reportList.length, (index) {
        return CustomBottomAlertItem(
          text: localized(reportList[index]),
          onClick: () => _showReportPopup(reportList[index]),
        );
      }),
    );
  }

  Future<void> onConfirmReport(String type, String feedback) async {
    final res = await reportIssue(
      widget.chat.chat_id,
      widget.message.message_id,
      widget.message.send_id,
      type,
      feedback,
    );
    if (res) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(weWillReviewYourReport),
        icon: ImBottomNotifType.success,
        isStickBottom: false,
      );
    }
  }

  void getSeenUsers() async {
    if (widget.chatPopMenuSheetType !=
        ChatPopMenuSheetType.chatPopMenuSheetChatBubble) return;
    if (!widget.chat.isGroup) return;
    if (widget.message.sendState != MESSAGE_SEND_SUCCESS) return;

    final msgSendTime =
        DateTime.fromMillisecondsSinceEpoch(widget.message.send_time);

    final diffMs = DateTime.now().difference(msgSendTime).inMilliseconds;

    // 7 day expired
    if (diffMs > 7 * 24 * 60 * 60 * 1000) return;

    Group? group = objectMgr.myGroupMgr.getGroupById(widget.chat.id);
    if (group == null) return;

    List<User> tempUserList = group.members.map<User>((e) {
      User user = User.fromJson({
        'uid': e['user_id'],
        'nickname': e['user_name'],
        'profile_pic': e['icon'],
        'last_online': e['last_online'],
        'deleted_at': e['delete_time'],
      });
      return user;
    }).toList();

    final tempUserMap = {for (final u in tempUserList) u.uid: u};

    _seenUsersMap.clear();
    _emojiUsersMap.clear();

    for (final e in widget.message.emojis) {
      for (final u in e.uidList) {
        final user = tempUserMap[u];
        if (user != null) {
          _seenUsersMap[user] = e.emoji;
        }
      }
    }

    _emojiUsersMap.addAll(_seenUsersMap);

    if (objectMgr.userMgr.isMe(widget.message.send_id)) {
      final result = await userRead(
        widget.chat.chat_id,
        widget.message.chat_idx,
      );

      result
          .removeWhere((element) => element == objectMgr.userMgr.mainUser.uid);

      for (final uid in result) {
        final user = tempUserMap[uid];

        if (user != null) {
          if (_seenUsersMap.containsKey(user) == true) {
            continue;
          } else {
            _seenUsersMap[user] = '';
          }
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
}
