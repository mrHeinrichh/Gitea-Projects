import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/media_detail/media_detail_view.dart';
import 'package:jxim_client/im/custom_content/components/task/sub_task_detail.dart';
import 'package:jxim_client/im/custom_content/sticker_modal_sheet.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/im/services/scroll_event_dispatcher.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/navigator_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/swipeable_page_route.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/floating_window/assist/floating_slide_type.dart';
import 'package:jxim_client/views/floating_window/floating.dart';
import 'package:jxim_client/views/floating_window/manager/floating_manager.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_large_photo.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/im/custom_content/components/emoji_bottom_sheet.dart';

class ChatContentController extends GetxController {
  /// VARIABLES
  late final BaseChatController chatController;
  late final CustomInputController inputController;
  final SettingServices settingServices = SettingServices();
  final Debounce _debounce = Debounce(const Duration(milliseconds: 500));

  /// 加载消息状态
  final scrollThreshold = 400;
  final bottomHideThreshold = 8;

  int lastVisibleUnreadIdx = 0;

  /// 置顶消息滑动控制器
  final AutoScrollController pinnedMessageScrollController =
      AutoScrollController(initialScrollOffset: 0);

  bool isLoading = false;
  bool isScrolling = false;

  int readIdx = 0;

  /// 回复消息点击高亮
  Timer? highlightTimer;
  RxInt highlightIndex = RxInt(-99999999);

  final showFloatingDay = false.obs;

  final isNeedUpdateTopUI = false.obs;

  AppLifecycleState appLifecycleState = AppLifecycleState.resumed;

  // int showDayDelay = 500;
  // Timer? showDayTimer;

  bool isDragging = false;

  // 判断是否是正在回复中
  final swipeToReply = false.obs;
  Offset? dragStart;

  // 拖拽的消息Id - 区分回复的是哪一条
  int dragMsgId = -1;

  // 距离起始点的差值
  RxDouble dragDiff = 0.0.obs;

  Chat? chat;

  ChatContentController();

  ChatContentController.desktop(Chat chat) {
    this.chat = chat;
  }

  @override
  void onInit() {
    super.onInit();
    if (objectMgr.loginMgr.isMobile) {
      final Map<String, dynamic> arguments = Get.arguments;
      if (arguments['chat'] != null) {
        chat = arguments['chat'];
      }
    } else if (objectMgr.loginMgr.isDesktop) {
      MediaKit.ensureInitialized();
    }

    if (chat != null) {
      if (Get.isRegistered<SingleChatController>(tag: chat?.id.toString())) {
        chatController =
            Get.find<SingleChatController>(tag: chat?.id.toString());
        inputController =
            Get.find<CustomInputController>(tag: chat?.id.toString());
      } else {
        chatController =
            Get.find<GroupChatController>(tag: chat?.id.toString());
        inputController =
            Get.find<CustomInputController>(tag: chat?.id.toString());
      }
    }

    objectMgr.navigatorMgr.addRoutes(navigatorTypeChat);
    objectMgr.on(ObjectMgr.eventAppLifeState, _didChangeAppLifecycleState);
    objectMgr.chatMgr.on(ChatMgr.eventChatPinnedMessage, _onMessagePinned);
  }

  onScroll(ScrollNotification notification) async {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;

    //pdebug("onScroll=========> ${notification is UserScrollNotification}-${chatController.messageListController.offset}-${chatController.messageListController.position.minScrollExtent}");

    /// 是否应该滑动到最底部
    if (notification is UserScrollNotification) {
      isScrolling = notification.direction != ScrollDirection.idle;
    } else if (notification is ScrollEndNotification) {
      /// 滑动停止同步已读
      isScrolling = false;
    } else {
      isScrolling = true;
    }

    /// 当滑动停止的时候触发已读消息的时间和隐藏悬浮日期
    if (!isScrolling) {
      Future.delayed(const Duration(milliseconds: 500), () {
        preReadMessage();
        chatController.isShowDay.value = false;
      });
    }

    objectMgr.chatMgr.event(
      objectMgr.chatMgr,
      ChatMgr.eventScrolling,
      data: isScrolling,
    );

    if (!chatController.isShowDay.value &&
        chatController.currMsgDayDisplay.value != 0) {
      chatController.isShowDay.value = true;
      //_startShowDayTimer();
    }

    if (isLoading) return;

    if (notification.metrics.maxScrollExtent > 0 &&
        notification is UserScrollNotification &&
        (notification.metrics.pixels - notification.metrics.minScrollExtent >
            bottomHideThreshold)) {
      if (!chatController.showScrollBottomBtn.value) {
        chatController.setDownButtonVisible(true);
      }
    }

    if ((chatController.messageListController.position.userScrollDirection ==
                ScrollDirection.forward ||
            isDesktop) &&
        notification.metrics.extentBefore < scrollThreshold) {
      bool isEnd = await chatController.isEnd();
      if (!isEnd && !isLoading) {
        isLoading = true;
        pdebug("================== 加载最新消息 ==================");
        await chatController.loadNextMessages();

        // 为了防止scroll到达加载位置的连续加载问题
        _debounce.call(() => isLoading = false);
      }
      if (isEnd && notification.metrics.extentBefore < bottomHideThreshold) {
        reachBottom();
      }
    } else if ((chatController
                    .messageListController.position.userScrollDirection ==
                ScrollDirection.reverse ||
            isDesktop) &&
        (notification.metrics.extentAfter - notification.metrics.extentInside) <
            scrollThreshold &&
        !chatController.isFirst() &&
        !isLoading) {
      pdebug("================== 加载历史消息 ==================");
      isLoading = true;

      await chatController.loadPreviousMessages();

      // 为了防止scroll到达加载位置的连续加载问题
      _debounce.call(() => isLoading = false);
    } else if (chatController
            .messageListController.position.userScrollDirection ==
        ScrollDirection.idle) {
      bool isEnd = await chatController.isEnd();
      if (isEnd && notification.metrics.extentBefore < bottomHideThreshold) {
        reachBottom();
      }
      isLoading = false;
    } else {
      isLoading = false;
    }
  }

  reachBottom() async {
    chatController.unreadCount.value = 0;
    if (chatController.chat.unread_count > 0) {
      chatController.chat.unread_count = 0;
      objectMgr.sharedRemoteDB.applyUpdateBlock(
          UpdateBlockBean.created(blockOptReplace, DBChat.tableName,
              [chatController.chat.toJson()]),
          save: true,
          notify: false);
    }
    chatController.setDownButtonVisible(false);
  }

  scrollToBottomMessage({int fromIdx = -1}) async {
    isLoading = true;

    objectMgr.chatMgr.clearMemMessageByChat(chatController.chat);
    List<Message> messageList = await objectMgr.chatMgr.loadMessageList(
        chatController.chat,
        fromIdx: chatController.chat.msg_idx,
        forward: 0,
        count: messagePageCount);

    if (messageList.isNotEmpty) {
      objectMgr.chatMgr.sortMessage(messageList);
      chatController.endMessage = null;
      chatController.startMessage = null;
      chatController.processDateByMessages(messageList, isPrevious: true);

      chatController.messageKeys.clear();
      chatController.nextMessageList.clear();
      chatController.messageSet.clear();

      chatController.previousMessageList.assignAll(messageList);
      chatController.previousMessageList.forEach((message) {
        if (message.read_num == 0) {
          message.setRead(chatController.chat);
        }
      });

      chatController.updateStartEndIndex();
      chatController.resetVisibleList();
      chatController.preloadPreviousMessages();

      objectMgr.chatMgr.updateChatAfterSetRead(
          chatController.chat.chat_id, chatController.chat.read_chat_msg_idx);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatController.messageListController
            .animateTo(
          chatController.messageListController.position.minScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        )
            .then((value) {
          lastVisibleUnreadIdx = chatController.endMessage?.chat_idx ??
              chatController.chat.msg_idx;
          chatController.mentionChatIdxList.clear();
          if (objectMgr
                  .chatMgr.mentionMessageMap[chatController.chat.chat_id] !=
              null) {
            objectMgr.chatMgr.mentionMessageMap[chatController.chat.chat_id] =
                {};
          }
          preReadMessage();
          reachBottom();
        });
      });
    }

    ScrollEventDispatcher.diff = -1;
    isLoading = false;
  }

  // _startShowDayTimer() {
  //   if (showDayTimer == null) {
  //     showDayTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
  //       _onTick();
  //     });
  //   }
  // }

  // _onTick() {
  //   if (showDayDelay <= 0) {
  //     chatController.isShowDay.value = false;
  //     _stopShowDayTimer();
  //   }
  //   showDayDelay -= 100;
  // }

  // _stopShowDayTimer() {
  //   showDayTimer?.cancel();
  //   showDayTimer = null;
  // }

  @override
  void onClose() {
    preReadMessage();
    // _stopShowDayTimer();
    objectMgr.navigatorMgr.removeRoutes(navigatorTypeChat);

    objectMgr.off(ObjectMgr.eventAppLifeState, _didChangeAppLifecycleState);

    objectMgr.chatMgr.off(ChatMgr.eventChatPinnedMessage, _onMessagePinned);
    super.onClose();
  }

  void _didChangeAppLifecycleState(sender, type, state) {
    appLifecycleState = state;
    if (state != AppLifecycleState.resumed) {
      objectMgr.navigatorMgr.closeRecordVoice();
    }
  }

  /// ============================= 监听回调函数 =================================

  /// 消息置顶
  void _onMessagePinned(Object sender, Object type, Object? data) async {
    if (data == null) {
      return;
    }
    if (data is Map && data.containsKey('id')) {
      int chatID = data['id'];
      if (chatID == chatController.chat.chat_id) {
        List<Message> messageList = (data['pin'] as List)
            .map<Message>((e) => Message()..init(e))
            .toList();
        // List msgDatas = data['pin'] as List;
        // for (final msgData in msgDatas) {
        //   // Message? message = await objectMgr.chatMgr.findMessageByChatIdx(
        //   //     msgData['chat_id'],
        //   //     msgData is Message ? msgData.id : msgData['chat_idx']);
        //
        //   Message message = msgData is Message ? msgData : Message()
        //     ..init(msgData);
        //
        //   if (message.chat_idx > chatController.chat.hide_chat_msg_idx &&
        //           message.content.isNotEmpty
        //       // && !message.  isLocalDel Todo: 以后的需求， 再过滤
        //       ) {
        //     messageList.add(message);
        //   }
        // }
        messageList.sort((a, b) => b.create_time.compareTo(a.create_time));
        chatController.pinMessageList.assignAll(messageList);
        objectMgr.chatMgr.pinnedMessageList[chatID] = messageList;

        if (chatController.pinMessageList.isEmpty) {
          if (chatController.isPinnedOpened) {
            chatController.isPinnedOpened = false;
            Get.back();
          }
        }

        objectMgr.sharedRemoteDB.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptReplace,
            DBChat.tableName,
            [
              {
                'id': chatID,
                'pin': data['pin']
                    .map<Message>((e) => Message()..init(e))
                    .toList(),
              }
            ],
          ),
          save: true, // 不需要保存
          notify: false,
        );
      }
    }
  }

  /// ============================ 监听回调函数结束 ==============================

  /// ================================ 业务函数 =================================
  void showLargePhoto(BuildContext context, Message message,
      {int? index, int? albumIdx}) {
    if (message.typ == messageTypeVideo || message.typ == messageTypeReel) {
      pdebug(
          '视频远程地址: ${message.decodeContent(cl: message.getMessageModel(message.typ)).url}');
    }

    if (message.typ == messageTypeNewAlbum) {
      NewMessageMedia msgMedia =
          message.decodeContent(cl: message.getMessageModel(message.typ));
      if (msgMedia.albumList != null) {
        pdebug('相册远程地址: ${msgMedia.albumList![albumIdx ?? 0].url}');
      }
    }

    chatController.playerService.stopPlayer();
    chatController.playerService.resetPlayer();
    inputController.resetRecordingState();

    if (chatController.popupEnabled) return;

    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    List<Map<String, dynamic>> assetList = List.empty(growable: true);

    if (chatController.isPinnedOpened) {
      assetList = processAssetList(chatController.pinMessageList);
    } else {
      assetList = processAssetList(chatController.combinedMessageList);
    }

    int selectedIdx;
    if (index != null) {
      selectedIdx = index;
    } else {
      selectedIdx =
          assetList.indexWhere((element) => element['message'] == message);
    }

    if (message.typ == messageTypeNewAlbum) {
      NewMessageMedia msgMedia =
          message.decodeContent(cl: message.getMessageModel(message.typ));
      if (msgMedia.albumList != null) {
        selectedIdx += msgMedia.albumList!.length - (albumIdx ?? 0) - 1;
      }
    }

    if (selectedIdx == -1) {
      return;
    }

    if (assetList.isNotEmpty) {
      if (objectMgr.loginMgr.isMobile) {
        Navigator.of(context).push(
          TransparentRoute(
            builder: (BuildContext context) => MediaDetailView(
              assetList: assetList,
              index: selectedIdx,
              contentController: this,
              reverse: true,
            ),
            settings: const RouteSettings(name: RouteName.mediaDetailView),
          ),
        );
      } else if (isDesktop) {
        DesktopGeneralDialog(
          context,
          color: const Color.fromRGBO(25, 25, 25, 0.9),
          dismissible: true,
          widgetChild: NewDesktopLargePhoto(
            assetList: assetList,
            index: selectedIdx,
            contentController: this,
            reverse: true,
          ),
        );
      }
    }
  }

  Floating? _videoFloating;
  final GlobalKey<MediaDetailViewState> _mediaDetailKey =
      GlobalKey<MediaDetailViewState>();

  _onShowMediaView(BuildContext context, int selectedIdx,
      List<Map<String, dynamic>> assetList) {
    if (_videoFloating == null) {
      MediaDetailView mediaDetailView = MediaDetailView(
        key: _mediaDetailKey,
        assetList: assetList,
        index: selectedIdx,
        contentController: this,
        reverse: true,
      );

      _videoFloating = floatingManager.createFloating(
        'reel_view',
        Floating(
            Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: mediaDetailView),
            slideType: FloatingSlideType.onRightAndTop,
            isShowLog: false,
            isSnapToEdge: true,
            isPosCache: true,
            moveOpacity: 1.0,
            height: 200,
            width: 120,
            defaultFullScreen: true),
      );
    }

    _videoFloating?.open(context);
  }

  _toggleFullscreen(bool isFull) {
    // if(isFull){
    //   _videoFloating?.fullscreen();
    //   _mediaDetailKey.currentState?.showToolBar();
    // }else{
    //   _videoFloating?.minimize();
    //   _mediaDetailKey.currentState?.hideToolBar();
    // }
  }

  preReadMessage() async {
    if (lastVisibleUnreadIdx != 0) {
      chatController.chat.readMessage(lastVisibleUnreadIdx);
      objectMgr.scheduleMgr.readMessageTask
          .clearChatRead(chatController.chat.id);
    }
  }

  addVisibleMessage(Message msg) {
    /// 防止刚进聊天室上滑到第一条未读消息位置时导致上滑过程已读很多信息
    //if (chatController.messageListController.isAutoScrolling) return;
    if (lastVisibleUnreadIdx != 0 && msg.chat_idx <= lastVisibleUnreadIdx)
      return;

    bool isFirstEntry = lastVisibleUnreadIdx == 0;

    lastVisibleUnreadIdx = msg.chat_idx;
    objectMgr.scheduleMgr.readMessageTask.addReadMessage(msg);
    if (!objectMgr.userMgr.isMe(msg.send_id)) {
      updateUnread(msg);
      updateMention(msg);

      //当第一次进入聊天室的时候读一下，因为onscroll那边不会触发读的动作
      if (isFirstEntry) {
        preReadMessage();
      }
    }
  }

  updateUnread(Message msg) {
    if (lastVisibleUnreadIdx > chatController.chat.read_chat_msg_idx) {
      if (chatController.unreadCount.value > 0) {
        chatController.unreadCount.value = chatController.oriUnread -
            (lastVisibleUnreadIdx - chatController.oriReadIdx);
      }
    }

    if (msg.read_num == 0 &&
        lastVisibleUnreadIdx <= chatController.chat.read_chat_msg_idx) {
      msg.setRead(chatController.chat);
      objectMgr.chatMgr.updateChatAfterSetRead(
          chatController.chat.chat_id, chatController.chat.read_chat_msg_idx);
    }
  }

  updateMention(Message msg) {
    chatController.mentionChatIdxList
        .removeWhere((e) => e.chat_idx <= lastVisibleUnreadIdx);
    if (objectMgr.chatMgr.mentionMessageMap[chatController.chat.chat_id] !=
        null) {
      objectMgr.chatMgr.mentionMessageMap[chatController.chat.chat_id]!
          .removeWhere((key, value) => key <= lastVisibleUnreadIdx);
    }
  }

  onViewReactList(BuildContext context, List<EmojiModel> emojiList) {
    List<EmojiMember> emojiData = [];
    for (final emoji in emojiList) {
      for (final user in emoji.uidList) {
        EmojiMember member = new EmojiMember();
        member.userId = user;
        member.emoji = emoji.emoji;
        emojiData.add(member);
      }
    }

    if (emojiData.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18.0),
            topRight: Radius.circular(18.0),
          ),
          side: BorderSide(
            color: dividerColor,
          ),
        ),
        builder: (context) => EmojiBottomSheet(
          reactEmojiList: emojiData,
        ),
      );
    }
  }

  void unPinMessage() => objectMgr.chatMgr.onUnpinMessage(
        chatController.chat.id,
        chatController.pinMessageList.last.message_id,
      );

  void unPinAllMessages(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: localized(titleUnpinAllMessages),
          content: Text(
            localized(subtitleUnpinAllMessages),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(buttonYes),
          cancelText: localized(buttonNo),
          confirmColor: accentColor,
          confirmCallback: () async {
            final List<int> idxList = chatController.pinMessageList
                .map((data) => data.message_id)
                .toList()
                .cast<int>();
            objectMgr.chatMgr
                .onUnpinAllMessage(chatController.chat.id, idxList);
            if (objectMgr.loginMgr.isDesktop) {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  void onPinMessageTap() {
    chatController.showMessageOnScreen(
        chatController.pinMessageList.first.chat_idx,
        chatController.pinMessageList.first.id,
        chatController.pinMessageList.first.create_time);
    chatController.onCreateHighlightTimer();
  }

  // =============================== 滑动回复功能 ===============================
  FancyGestureController? _fancyGestureController;

  void onMessageHorizontalDragStart(DragStartDetails details) {
    if (Get.isRegistered<FancyGestureController>()) {
      _fancyGestureController = Get.find<FancyGestureController>();
      _fancyGestureController!.dragStartDetails!(details);
    }
  }

  void onMessageHorizontalDragDown(DragDownDetails details) {
    if (chatController.isPinnedOpened || chatController.chat.isSystem) return;

    if (inputController.inputFocusNode.hasFocus) {
      inputController.inputFocusNode.unfocus();
      return;
    }

    isDragging = true;
    dragStart = details.globalPosition;
  }

  void onMessageHorizontalDragUpdate(DragUpdateDetails details, Message msg) {
    if (chatController.isPinnedOpened || chatController.chat.isSystem) return;

    if (inputController.inputFocusNode.hasFocus) {
      inputController.inputFocusNode.unfocus();
      return;
    }

    final dragUpdate = details.globalPosition;
    final dx = dragUpdate.dx - dragStart!.dx;

    if (dx < 0 && msg.isSwipeToReply && !swipeToReply.value && msg.isSendOk) {
      swipeToReply.value = true;
      dragMsgId = msg.send_time;
      HapticFeedback.mediumImpact();
    }

    if (!swipeToReply.value) {
      if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _fancyGestureController?.dragUpdateDetails?.call(details);
    }

    // move the message widget
    if (swipeToReply.value && msg.isSwipeToReply && dx < 0) {
      if (dx > -100) {
        dragDiff.value = dx;
      }
    }
  }

  void onMessageHorizontalDragEnd(DragEndDetails details, Message message) {
    if (chatController.isPinnedOpened) return;

    if (swipeToReply.value &&
        (message.typ <= 20 || message.typ == 25 || message.isCalling)) {
      if (dragDiff.value.abs() >
          MediaQuery.of(Get.context!).size.width * 0.10) {
        inputController.onReply(message.send_id, message, chatController.chat);
      }
    }

    _fancyGestureController?.dragEndDetails?.call(details);
    dragMsgId = -1;
    dragDiff.value = 0.0;
    swipeToReply.value = false;
  }

  void onMessageHorizontalDragCancel() {
    if (chatController.isPinnedOpened) return;
    _fancyGestureController?.dragCancelDetails?.call();
    dragMsgId = -1;
    dragDiff.value = 0.0;
    swipeToReply.value = false;
  }

  /// =============================== 特殊函数逻辑 ===============================
  Future showStickerModal(BuildContext context, MessageImage messageImage) {
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (context) => StickerModalSheet(messageImage: messageImage),
    );
  }

  void onMessageVisible(Message message) {
    if (!chatController.messageListController.hasClients) return;
    if (chatController.combinedMessageList.isEmpty) return;

    final index = chatController.combinedMessageList.indexOf(message);
    if (chatController.messageListController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (index - 1 > 0) {
        int prevTime = message.create_time;
        int curTime = chatController.combinedMessageList[index - 1].create_time;
        if (!FormatTime.iSameDay(prevTime, curTime)) {
          chatController.currMsgDayDisplay.value = prevTime;
        } else {
          chatController.currMsgDayDisplay.value = message.create_time;
        }
      }
    } else if (chatController
            .messageListController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (index + 1 < chatController.combinedMessageList.length) {
        int curTime = chatController.combinedMessageList[index + 1].create_time;
        int nextTime = message.create_time;
        if (!FormatTime.iSameDay(curTime, nextTime)) {
          chatController.currMsgDayDisplay.value = nextTime;
        } else {
          chatController.currMsgDayDisplay.value = curTime;
        }
      }
    }
  }

  /// [asset] 可以有的状态, asset : AssetEntity | String | AlbumDetailBean,
  /// [file] 可以有的状态, file : File
  /// [cover] 可以有的状态, url : String
  /// [message] 对应的消息
  List<Map<String, dynamic>> processAssetList(List<Message> messageList) {
    List<Map<String, dynamic>> assetList = [];
    objectMgr.chatMgr.sortMessage(messageList);
    for (Message message in messageList) {
      if (message.deleted == 1 || !message.isMediaType || !message.isSendOk) {
        continue;
      }

      if (message.typ == messageTypeImage) {
        Map<String, dynamic> assetMap = {};
        if (message.asset != null) {
          assetMap['asset'] = message.asset;
          assetMap['message'] = message;
        } else {
          MessageImage messageImage =
              message.decodeContent(cl: message.getMessageModel(message.typ));
          assetMap['asset'] = messageImage.url;
          assetMap['message'] = message;
        }
        assetList.add(assetMap);
      } else if (message.typ == messageTypeVideo ||
          message.typ == messageTypeReel) {
        Map<String, dynamic> assetMap = {};
        if (message.asset != null) {
          MessageVideo messageVideo =
              message.decodeContent(cl: MessageVideo.creator);
          assetMap['asset'] = message.asset;
          assetMap['message'] = message;
          assetMap['hasVideo'] = true;
        } else {
          MessageVideo messageVideo =
              message.decodeContent(cl: message.getMessageModel(message.typ));
          assetMap['asset'] = messageVideo.url;
          assetMap['cover'] = messageVideo.cover;
          assetMap['message'] = message;
          assetMap['hasVideo'] = true;
        }

        assetList.add(assetMap);
      } else {
        if (notBlank(message.asset)) {
          List<Map<String, dynamic>> tempAlbumAssetList = [];
          for (int i = 0; i < message.asset.length; i++) {
            Map<String, dynamic> assetMap = {};
            dynamic asset = message.asset[i];
            NewMessageMedia msgMedia = message.decodeContent(
              cl: NewMessageMedia.creator,
            );

            if (notBlank(msgMedia.albumList) &&
                msgMedia.albumList!.length > i) {
              AlbumDetailBean bean = msgMedia.albumList![i];
              bean.asset = asset;
              assetMap['asset'] = bean;
              assetMap['message'] = message;

              if (asset is AssetEntity && asset.type == AssetType.video) {
                assetMap['hasVideo'] = true;
              }

              if (asset is AssetPreviewDetail &&
                  asset.entity.type == AssetType.video) {
                assetMap['hasVideo'] = true;
              }
            } else {
              AlbumDetailBean bean = AlbumDetailBean(
                url: '',
              );
              bean.asset = asset;

              if (asset is AssetEntity) {
                if (asset.mimeType != null) {
                  bean.mimeType = asset.mimeType;
                } else {
                  AssetType type = asset.type;
                  if (type == AssetType.image) {
                    bean.mimeType = "image/png";
                  } else if (type == AssetType.video) {
                    bean.mimeType = "video/mp4";
                    assetMap['hasVideo'] = true;
                  }
                }
              }
              bean.currentMessage = message;

              assetMap['asset'] = bean;
              assetMap['message'] = message;
            }

            if (assetMap.isNotEmpty) {
              tempAlbumAssetList.add(assetMap);
            }
          }

          if (tempAlbumAssetList.isNotEmpty) {
            assetList.addAll(tempAlbumAssetList.reversed.toList());
          }
        } else {
          NewMessageMedia messageMedia =
              message.decodeContent(cl: NewMessageMedia.creator);
          List<AlbumDetailBean> list = messageMedia.albumList ?? [];
          list = list.reversed.toList();
          for (AlbumDetailBean bean in list) {
            Map<String, dynamic> assetMap = {};
            bean.currentMessage = message;
            assetMap['asset'] = bean;
            assetMap['message'] = message;
            if (bean.mimeType != null && bean.mimeType == "video/mp4") {
              assetMap['hasVideo'] = true;
            }

            assetList.add(assetMap);
          }
        }
      }
    }

    return assetList;
  }

  bool isCTRLPressed() {
    return HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlRight);
  }

  void redirectToChatInfo(int targetUid) {
    Get.toNamed(RouteName.chatInfo, arguments: {
      "uid": targetUid,
    });
  }

  Future<void> onMentionClick(int sendID) async {
    User? user = await objectMgr.userMgr.loadUserById2(sendID);
    if (user != null) {
      inputController.addMentionUser(user);
    }
  }

  /// 任务操作
  void onTaskItemTap(
      BuildContext context, TaskContent taskContent, SubTask subTask) {
    Toast.showBottomSheet(
      context: context,
      container: SubTaskDetail(
        chat: chatController.chat,
        task: taskContent,
        subTask: subTask,
      ),
    );
  }
}
