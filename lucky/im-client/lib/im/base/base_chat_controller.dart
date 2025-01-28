import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:agora/agora_plugin.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/im/bet_msg_filter/bet_msg_filter_manager.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/get_utils.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/translate/translate_container.dart';
import 'package:jxim_client/im/custom_content/translate/translate_controller.dart';
import 'package:jxim_client/im/custom_input/component/chat_attachment_view.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/custom_text_editing_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views/red_packet/red_packet_page.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:jxim_client/views/transfer_money/transfer_money.dart';
import 'package:synchronized/synchronized.dart';

import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/translate_model.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/views_desktop/component/attach_file_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/model/group/group.dart';

RxDouble keyboardHeight = 0.0.obs;

class BaseChatController extends GetxController with WidgetsBindingObserver {
  /// VARIABLES
  final prevMessageListThreshold = 20;

  /// 通用数据
  final BuildContext context = Routes.navigatorKey.currentContext!;
  final Size screenSize =
      MediaQuery.of(Routes.navigatorKey.currentContext!).size;

  /// 当前聊天室数据
  late Chat chat;

  RxBool chatIsDeleted = false.obs;

  /// 聊天列表控制器
  AutoScrollController messageListController =
      AutoScrollController(initialScrollOffset: -8);

  RxInt unreadCount = RxInt(0);
  int oriUnread = 0;
  int oriReadIdx = 0;

  final previousMessageList = <Message>[].obs;
  final nextMessageList = <Message>[].obs;
  final messageSet = <int>[];

  bool isAutoDeleteIntervalEnable = false;

  RxList<Message> get combinedMessageList =>
      RxList<Message>.from(nextMessageList)..addAll(previousMessageList);

  RxList<Message> visibleMessageList = <Message>[].obs;

  Message? visibleFirstMessage;
  final Map<int, GlobalKey> messageKeys = {};

  // 置顶消息List
  final pinMessageList = <Message>[].obs;
  final pinnedIndex = ValueNotifier(0);

  /// 回复消息点击高亮
  Timer? highlightTimer;
  RxMap<String, int> highlightIndex = RxMap({
    'list': 0,
    'index': -9999999999,
  });

  bool noMorePrevious = false;
  bool noMoreNext = false;
  Message? startMessage;
  Message? endMessage;

  RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  RxString searchParam = "".obs;
  String preSearchContent = "";

  // chat_idx of searched messages
  Lock searchMsgLock = Lock();
  RxList<Message> searchedIndexList = RxList<Message>();

  // idx in searchedIndexList
  RxInt listIndex = 0.obs;

  /// 发送联系人弹窗，搜索联系人
  RxList<User> friendList = RxList<User>();
  RxBool isContactSearching = false.obs;
  final TextEditingController searchContactController = TextEditingController();
  final FocusNode searchContactFocusNode = FocusNode();
  RxString searchContactParam = "".obs;

  RxBool isShowDay = RxBool(false);

  /// 顶部显示悬浮天数
  final currMsgDayDisplay = 0.obs;

  /// 撤回消息id
  int withdrawMessageId = 0;

  Message? searchMsg;

  /// 对方是否输入中...
  Rx<ChatInput> inputNotify = Rx(ChatInput());

  RxBool showFaceView = RxBool(false);
  RxBool showAttachmentView = RxBool(false);

  late List<ChatAttachmentOption> attachmentOptions =
      List.empty(growable: true);

  late final attachmentPictureOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_picture.svg',
    title: localized(attachmentCallPicture),
    onTap: () {
      final controller =
          Get.find<CustomInputController>(tag: chat.id.toString());

      controller.showBottomPopup(
        context,
        tag: chat.chat_id.toString(),
        mediaOption: MediaOption.gallery,
      );
    },
  );

  late final attachmentCameraOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_camera.svg',
    title: localized(attachmentCamera),
    onTap: () {
      final controller =
          Get.find<CustomInputController>(tag: chat.id.toString());

      controller.onPhoto(context);
    },
  );

  late final attachmentCallViceOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_call_voice.svg',
    title: localized(attachmentCallVoice),
    onTap: () {
      final controller =
          Get.find<CustomInputController>(tag: chat.id.toString())
              .chatController;
      final localChat = controller.chat;

      if (localChat.isGroup) {
        if (localChat.isValid) {
          if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
            Toast.showToast(localized(toastEndCall));
          } else {
            audioManager.audioStateBtnClick(context);
          }
        } else {
          Toast.showToast(localized(youAreNoLongerInThisGroup));
        }
      } else {
        startCall(isVoiceCall: true);
      }
    },
  );

  late final attachmentCallVideoOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_call_video.svg',
    title: localized(attachmentCallVideo),
    onTap: () => startCall(isVoiceCall: false),
  );

  late final attachmentLocationOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_location.svg',
    title: localized(attachmentLocation),
    onTap: () {
      final controller =
          Get.find<CustomInputController>(tag: chat.id.toString());

      controller.showBottomPopup(
        context,
        tag: chat.chat_id.toString(),
        mediaOption: MediaOption.location,
      );
    },
  );

  late final attachmentRedPacketOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_red_packet.svg',
    title: localized(attachmentRedPacket),
    onTap: () {
      final tag = chat.chat_id.toString();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RedPacketPage(tag: tag),
        ),
      );
    },
  );

  late final attachmentTransferMoneyOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_transfer_money.svg',
    title: localized(transferMoney),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransferMoney(chat.chat_id)),
      );
    },
  );

  late final attachmentFileOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_file.svg',
    title: localized(attachmentFiles),
    onTap: () {
      final controller =
          Get.find<CustomInputController>(tag: chat.id.toString());

      controller.showBottomPopup(
        context,
        tag: chat.chat_id.toString(),
        mediaOption: MediaOption.document,
      );
    },
  );

  late final attachmentContactOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_contact.svg',
    title: localized(attachmentContact),
    onTap: () {
      final controller =
          Get.find<CustomInputController>(tag: chat.id.toString());

      controller.showBottomPopup(
        context,
        tag: chat.chat_id.toString(),
        mediaOption: MediaOption.contact,
      );
    },
  );

  void startCall({required bool isVoiceCall}) {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCall));
      return;
    }

    try {
      objectMgr.callMgr.startCall(chat, isVoiceCall);
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  /// 是否选择更多
  RxBool chooseMore = RxBool(false);

  RxBool canForward = true.obs;
  RxBool canDelete = true.obs;
  RxMap<int, Message> chooseMessage = RxMap<int, Message>();

  VolumePlayerService playerService = VolumePlayerService.sharedInstance;

  final isVoice = true.obs;

  final showScrollBottomBtn = false.obs;

  double selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
              .toUtc()
              .millisecondsSinceEpoch /
          1000;

  OverlayEntry? redPacketEntry;

  bool isPinnedOpened = false;

  bool popupEnabled = false;
  OverlayEntry? chatPopEntry;

  /// 选取 “@” 用户列表状态
  RxBool showMentionList = false.obs;
  RxList<Message> mentionChatIdxList = RxList<Message>();

  Message? unreadBarMsg;

  /// permission
  final inputType = 0.obs;
  final permission = 999.obs;
  final pinEnable = true.obs;
  bool showTextVoice = true;
  bool showGallery = true;
  bool showDocument = true;
  bool showContact = true;
  bool showRedPacket = true;
  bool showTextStickerEmoji = true;
  bool showTransferMoney = true;
  bool linkEnable = true;
  bool isScreenshotEnabled = false;
  AppLifecycleState appState = AppLifecycleState.resumed;
  final isSetPassword = false.obs;

  final List<AudioPlayer> audioPlayersList = [];

  /// Desktop variable
  final GlobalKey upperDropAreaKey = GlobalKey();
  final GlobalKey lowerDropAreaKey = GlobalKey();

  FocusNode mainListFocusNode = FocusNode();

  bool allImage = false;
  bool allVideo = false;

  TextEditingController captionController = TextEditingController();
  List<FileType> fileTypeList = [];
  RxBool onHover = false.obs;
  bool isDialogShown = false;
  RxBool showingProfile = false.obs;
  int profileId = 0;

  bool hasAllSameFile(FileType fileType) =>
      fileTypeList.every((element) => element == fileType);

  Lock messageLock = Lock();

  int? unreadPos;

  bool fromNotificationTap = false;

  Lock uiMessageListLock = Lock();

  /// 左侧头像
  final RxInt currentAvatarId = RxInt(-1);
  final RxString currentAvatarTag = "".obs;

  List<List<Message>> gameMessageList = [];
  List<Message> gameMessageGroup = <Message>[];
  List<List<Message>> normalMessageList = [];
  List<Message> normalMessageGroup = <Message>[];
  final gameMessageIds = [
    // 20001,
    // 20002,
    20003,
    20004,
    20005,
    20006,
  ];

  @override
  void onInit() {
    super.onInit();
    CustomTextEditingController.mentionRange.clear();

    objectMgr.chatMgr.on(ChatMgr.eventUpdateUnread, onUpdateUnread);
    objectMgr.chatMgr.on(ChatMgr.eventMessageComing, onMessageComing);
    objectMgr.chatMgr.on(ChatMgr.eventMessageSend, onMessageSend);
    objectMgr.chatMgr.on(ChatMgr.eventChatReload, onChatReload);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, onChatMessageAutoDelete);
    objectMgr.chatMgr
        .on(ChatMgr.eventAddMentionChange, _onAddMentionListChange);
    objectMgr.chatMgr
        .on(ChatMgr.eventDelMentionChange, _onDelMentionListChange);
    objectMgr.chatMgr.on(ChatMgr.eventSetPassword, _onSetPassword);
    objectMgr.chatMgr.on(ChatMgr.eventUnreadPosition, _updateUnreadPosition);
    objectMgr.chatMgr.on(ChatMgr.cancelKeyboardEvent, _cancelKeyBoardEvent);
    WidgetsBinding.instance.addObserver(this);

    ever(isSearching, (_) {
      if (isSearching.value) showFaceView(false);
    });

    if (!checkIsMute(chat.mute) && chat.isMute)
      objectMgr.chatMgr.updateNotificationStatus(chat, 0);

    objectMgr.stickerMgr.getRemoteRecentStickers();

    isAutoDeleteIntervalEnable = chat.autoDeleteEnabled;
    unreadCount.value = chat.unread_count;
    oriUnread = chat.unread_count;
    oriReadIdx = chat.read_chat_msg_idx;

    ///桌面端不用Like
    if (!objectMgr.loginMgr.isDesktop) {
      loadMentions();
    }

    checkPasscodeStatus();
    initPinMessages();
    initData();
  }

  initData() async {
    int fromIdx = chat.msg_idx;
    int fromTime = 0;
    int extra = 0;
    bool mostLatest = false;
    if (objectMgr.chatMgr.lastChatMessageMap[chat.id] != null &&
        objectMgr.chatMgr.lastChatMessageMap[chat.id]!.chat_idx > fromIdx) {
      fromIdx = objectMgr.chatMgr.lastChatMessageMap[chat.id]!.chat_idx;
    }

    /// 如果2条消息是图片的话，很有可能unread Bar会在屏幕外面
    if (chat.unread_count > 0) {
      fromIdx = chat.read_chat_msg_idx;

      /// 当清空聊天室后, 聊天室有未读消息的时候会发生read_chat_msg_idx == hide_chat_msg_idx的情况, 或者已读的消息很少导致上面空屏的情况
      if (chat.read_chat_msg_idx - chat.hide_chat_msg_idx < 10) {
        extra = 10;
      } else if (chat.unread_count <= 5) {
        extra = chat.unread_count;
      } else {
        extra = 2;
      }
      if (chat.msg_idx - chat.read_chat_msg_idx > extra) {
        setDownButtonVisible(true);
      }
    } else {
      // 小于五条未读消息从最新一条往上加载
      mostLatest = true;
    }

    if (!objectMgr.loginMgr.isDesktop) {
      final arguments = Get.arguments as Map<String, dynamic>;
      if (arguments['selectedMsgIds'] != null &&
          arguments['selectedMsgIds'].length > 0) {
        searchMsg = arguments['selectedMsgIds'][0];
      }
    }

    if (searchMsg != null) {
      fromIdx = searchMsg!.chat_idx;
      fromTime = searchMsg!.create_time;
      extra = 0;
      if (unreadCount.value > 0) {
        setDownButtonVisible(true);
      }
    }

    List<Message> messageList = await objectMgr.chatMgr.loadMessageList(chat,
        fromIdx: fromIdx,
        extra: extra,
        count: messagePageCount,
        fromTime: fromTime);
    pdebug('initMessages===> ${messageList.length}');
    if (searchMsg != null && messageList.isNotEmpty) {
      messageList.forEach((element) {
        if (element.id == searchMsg!.id) {
          element.select = 1;
        }
      });
    }
    if (messageList.isNotEmpty) {
      processDateByMessages(messageList, isPrevious: true);
      messageSet.addAll(messageList.map((e) => e.id));

      initRenderList(messageList, mostLatest);
      // 继续加载下一屏剩余的消息, 为了提升用户体验
      if (!noMoreNext) {
        await loadNextMessages(messageCount: messagePageCount - extra);
      }
      if (searchMsg != null) {
        scrollMessage(searchMsg!.chat_idx, searchMsg!.id,
            shouldDisappear: true);
      } else {
        scrollToUnreadBar();
      }
    } else {
      toLoadMessages();
    }

    attachmentOptions = chat.isGroup
        ? [
            attachmentPictureOption,
            attachmentCameraOption,
            attachmentCallViceOption,
            attachmentLocationOption,
            attachmentRedPacketOption,
            attachmentFileOption,
            attachmentContactOption,
          ]
        : [
            attachmentPictureOption,
            attachmentCameraOption,
            attachmentCallViceOption,
            attachmentCallVideoOption,
            attachmentLocationOption,
            attachmentTransferMoneyOption,
            attachmentFileOption,
            attachmentContactOption,
          ];

    if (!chat.isGroup && !Config().enableWallet) {
      attachmentOptions.remove(attachmentTransferMoneyOption);
    } else if (chat.isGroup && !Config().enableWallet) {
      attachmentOptions.remove(attachmentRedPacketOption);
    }
  }

  loadMentions() async {
    if (objectMgr.chatMgr.mentionMessageMap[chat.chat_id] != null) {
      mentionChatIdxList.addAll(
          objectMgr.chatMgr.mentionMessageMap[chat.chat_id]!.values.toList());
    }
  }

  scrollToUnreadBar() {
    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (unreadPos != null) {
        bool hasScroll = false;
        if (chat.unread_count > 5) {
          hasScroll = true;
        } else {
          int getSplitPosition = ChatHelp.getSplitPosition(previousMessageList);
          hasScroll = getSplitPosition > 0;
        }

        if (hasScroll) {
          bool hasExtraSpace = pinMessageList.isNotEmpty &&
              previousMessageList.length > unreadPos!;
          messageListController.scrollToIndex(unreadPos!,
              preferPosition: AutoScrollPosition.end,
              duration: const Duration(milliseconds: 0),
              extraOffset: hasExtraSpace ? 48 : 0);
        }
      }
    });
  }

  bool scrollMessage(
    int chat_idx,
    int id, {
    bool shouldDisappear = false,
  }) {
    bool find = true;
    var pre_index = -1;
    var next_index = -1;
    if (id != 0) {
      pre_index = previousMessageList.indexWhere((element) => element.id == id);
      next_index = nextMessageList.indexWhere((element) => element.id == id);
    } else {
      pre_index = previousMessageList
          .indexWhere((element) => element.chat_idx == chat_idx);
      next_index = next_index =
          nextMessageList.indexWhere((element) => element.chat_idx == chat_idx);
    }

    if (pre_index == -1 && next_index == -1) {
      find = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((t) {
      int index = -1;
      if (pre_index == -1) {
        if (next_index != -1) {
          if (shouldDisappear) {
            highlightIndex.value = {
              'list': 1,
              'index': next_index,
            };
          }
          index = next_index;
        }
      } else {
        if (shouldDisappear) {
          highlightIndex.value = {
            'list': 0,
            'index': pre_index,
          };
        }
        index = pre_index;
      }
      var extraOffset = 0.0;
      if (chat.msg_idx > chat_idx + 3) {
        extraOffset = -150;
      }

      if (index != -1) {
        messageListController.scrollToIndex(index,
            preferPosition: AutoScrollPosition.begin,
            duration: const Duration(milliseconds: 0),
            extraOffset: extraOffset);
        find = true;

        if (shouldDisappear) onCreateHighlightTimer();
      }
    });
    return find;
  }

  void toLoadMessages() async {
    List<Message> messageList = await ChatMgr.loadDBMessages(
        objectMgr.localDB, chat,
        count: messagePageCount, dbLatest: true);

    if (messageList.isNotEmpty) {
      processDateByMessages(messageList, isPrevious: true);
      messageSet.addAll(messageList.map((e) => e.id));

      initRenderList(messageList, true);
    }
  }

  /// isPrevious = true 传进来的messages的顺序一定要保证是倒叙的, = false时是正顺的
  void processDateByMessages(List<Message> messages,
      {bool isPrevious = false}) {
    List<Message> copyMessages = List.from(messages);
    Message? preMessage;
    int dateAmount = 0;

    //刚进入聊天室或者今日聊天室后没有任何消息时突然来了一条新的消息
    if (isPrevious && startMessage != null) {
      //向上加载历史消息
      preMessage = startMessage;
      for (int i = 0; i < copyMessages.length; i++) {
        Message message = copyMessages[i];
        if (!message.isChatRoomVisible) continue;

        if (!FormatTime.iSameDay(
            message.create_time, preMessage!.create_time)) {
          messages.insert(i + dateAmount, getDateMessage(preMessage));
          dateAmount++;
        }

        //最后一条消息
        if (i == copyMessages.length - 1) {
          if (message.chat_idx == 1 ||
              message.chat_idx == chat.hide_chat_msg_idx + 1) {
            messages.add(getDateMessage(message, sendTime: -1));

            /// -1 保证是在第一的位置
          }
        }

        preMessage = message;
      }

      ///这里需要重新倒叙排序一次，因为过滤出去的隐藏消息可能导致列表不联系，之后插入unreadBar的位置可能不对，例如今日在unreadBar的上面
      objectMgr.chatMgr.sortMessage(messages);
    } else if (!isPrevious && endMessage != null) {
      //向下加载更多消息
      preMessage = endMessage;
      for (int i = 0; i < copyMessages.length; i++) {
        Message message = copyMessages[i];
        if (!message.isChatRoomVisible) continue;

        if (!FormatTime.iSameDay(
            message.create_time, preMessage!.create_time)) {
          messages.insert(i + dateAmount, getDateMessage(message));
          dateAmount++;
        }

        preMessage = message;
      }

      ///这里需要重新倒叙排序一次，因为过滤出去的隐藏消息可能导致列表不联系，之后插入unreadBar的位置可能不对，例如今日在unreadBar的上面
      objectMgr.chatMgr.sortMessage(messages, ascending: true);
    } else if (startMessage == null && endMessage == null) {
      for (int i = 0; i < copyMessages.length; i++) {
        Message message = copyMessages[i];
        if (!message.isChatRoomVisible) continue;

        if (preMessage != null) {
          if (!FormatTime.iSameDay(
              message.create_time, preMessage.create_time)) {
            messages.insert(
                i + dateAmount,
                getDateMessage(isPrevious ? preMessage : message,
                    sendTime: isPrevious ? -1 : 0));
            dateAmount++;
          }
        }

        //最后一条消息
        if (i == copyMessages.length - 1) {
          if (message.chat_idx == 1 ||
              message.chat_idx == chat.hide_chat_msg_idx + 1) {
            messages.add(getDateMessage(message, sendTime: -1));

            /// -1 保证是在第一的位置
          }
        }

        preMessage = message;
      }

      ///这里需要重新倒叙排序一次，因为过滤出去的隐藏消息可能导致列表不联系，之后插入unreadBar的位置可能不对，例如今日在unreadBar的上面
      objectMgr.chatMgr.sortMessage(messages);
    }
  }

  getDateMessage(Message message, {int sendTime = 0}) {
    Message timeMsg = Message();
    timeMsg.message_id = message.message_id;
    timeMsg.chat_idx = message.chat_idx;
    timeMsg.create_time = message.create_time;
    timeMsg.chat_id = message.chat_id;
    timeMsg.send_time = sendTime == 0
        ? DateTime.now().millisecondsSinceEpoch ~/ 1000
        : sendTime;
    timeMsg.typ = messageTypeDate;
    return timeMsg;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    appState = state;
    if (state != AppLifecycleState.resumed) {
      if (inputNotify.value.state != 0) {
        inputNotify.value.state = 2;
      }
      playerService.stopPlayer();
      playerService.resetPlayer();
      if (state == AppLifecycleState.paused) {
        //關閉螢幕或是退到後台要關閉相機
        if (audioManager.isVideoOn) {
          liveMemberListPageModel.turnOnOffVideo(context);
        }
        cancelBottomView();
      }
    }
  }

  /// ============================== APP LIFECYCLE =============================
  initRenderList(List<Message> messages, bool mostLatest) {
    if (!mostLatest) {
      int firstUnreadIndex = chat.read_chat_msg_idx + 1;
      int unreadIndex =
          messages.lastIndexWhere((e) => e.chat_idx >= firstUnreadIndex);
      if (messages.length >= unreadIndex) {
        bool isUnreadInMessages =
            (firstUnreadIndex >= messages.last.chat_idx) &&
                (firstUnreadIndex <= messages.first.chat_idx);

        /// messageList里面是否包含unreadIdx
        if (isUnreadInMessages) {
          if (unreadIndex >= 0) {
            unreadPos = unreadIndex + 1;
            List<Message> extraMessages = messages.sublist(0, unreadPos);
            if (extraMessages.isNotEmpty) {
              extraMessages
                  .add(getUnreadBar(messages[extraMessages.length - 1]));
            }

            previousMessageList.assignAll(extraMessages);
            if (unreadPos! < messages.length) {
              previousMessageList
                  .addAll(messages.sublist(unreadPos!, messages.length));
            }
          } else {
            previousMessageList.assignAll(messages);
          }
        } else {
          previousMessageList.assignAll(messages);
        }
      } else {
        previousMessageList.assignAll(messages);
      }
    } else {
      if (chat.read_chat_msg_idx < chat.msg_idx) {
        int firstUnreadIndex = chat.read_chat_msg_idx + 1;
        Message? firstValidUnreadMessage; // 未读消息有可能是不可显示的消息
        bool hasValidMessage = false;
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].chat_idx <= firstUnreadIndex) {
            if (!hasValidMessage && messages[i].isChatRoomVisible) {
              hasValidMessage = true;
            }

            if (messages[i].chat_idx == firstUnreadIndex) {
              firstValidUnreadMessage = messages[i];
              firstUnreadIndex = i;
              break;
            }
          }
        }

        if (hasValidMessage && firstValidUnreadMessage != null) {
          messages.insert(
              firstUnreadIndex + 1, getUnreadBar(firstValidUnreadMessage));
        }
      }
      previousMessageList.assignAll(messages);
    }

    updateStartEndIndex();
    resetVisibleList();
    preloadPreviousMessages();
  }

  Message getUnreadBar(Message message) {
    unreadBarMsg = Message.creator();
    unreadBarMsg?.typ = messageTypeUnreadBar;
    unreadBarMsg?.chat_idx = message.chat_idx;
    unreadBarMsg?.chat_id = message.chat_id;
    unreadBarMsg?.create_time = message.create_time;
    return unreadBarMsg!;
  }

  void initPinMessages() {
    List<Message> pinMessages =
        (objectMgr.chatMgr.pinnedMessageList[chat.id] ?? [])
            .where((e) => !e.isDeleted)
            .toList();
    objectMgr.chatMgr.sortMessage(pinMessages);
    pinMessageList.assignAll(pinMessages);
  }

  void updateStartEndIndex() {
    _updateStartIndex();
    _updateEndIndex();
  }

  _updateStartIndex() {
    messageLock.synchronized(() {
      if (previousMessageList.isNotEmpty) {
        startMessage = previousMessageList.last;
      } else if (previousMessageList.isEmpty && nextMessageList.isNotEmpty) {
        startMessage = nextMessageList.first;
      }

      if (startMessage != null) {
        if (startMessage!.chat_idx <= (chat.hide_chat_msg_idx + 1)) {
          noMorePrevious = true;
        } else {
          noMorePrevious = false;
        }
      }
    });
  }

  _updateEndIndex() {
    if (nextMessageList.isNotEmpty) {
      for (int i = nextMessageList.length - 1; i >= 0; i--) {
        if (endMessage == null ||
            nextMessageList[i].chat_idx > endMessage!.chat_idx) {
          endMessage = nextMessageList[i];
          break;
        }
      }
    } else if (previousMessageList.isNotEmpty) {
      for (int i = 0; i < previousMessageList.length; i++) {
        if (endMessage == null ||
            previousMessageList[i].chat_idx > endMessage!.chat_idx) {
          endMessage = previousMessageList[i];
          break;
        }
      }
    }

    if (endMessage != null) {
      if (endMessage!.chat_idx >= chat.msg_idx) {
        noMoreNext = true;
      } else {
        noMoreNext = false;
      }
    }
  }

  void _clearStartEndIndex() {
    endMessage = null;
    startMessage = null;
    noMorePrevious = false;
    noMoreNext = false;
  }

  Future<void> loadPreviousMessages() async {
    if (!isFirst()) {
      pdebug(
          "beforeLoadPrevious===>  ${startMessage?.chat_idx}-${previousMessageList.length}");
      int fromIdx =
          startMessage != null ? startMessage!.chat_idx : chat.msg_idx;
      int fromTime = startMessage != null ? startMessage!.create_time : 0;
      List<Message> tempMessageList = await objectMgr.chatMgr.loadMessageList(
          chat,
          fromIdx: fromIdx - 1,
          count: messagePageCount,
          fromTime: fromTime);

      await uiMessageListLock.synchronized(() async {
        if (tempMessageList.isNotEmpty) {
          List<Message> messageList = [];
          for (final m in tempMessageList) {
            if (messageSet.contains(m.id) || _isExistSentMessage(m)) continue;
            messageSet.add(m.id);
            messageList.add(m);
          }

          /// 插入时间逻辑
          processDateByMessages(messageList, isPrevious: true);

          previousMessageList.addAll(messageList);
          previousMessageList.forEach((element) {
            if (element.read_num == 0) {
              element.setRead(chat);
            }
          });

          if (isSearching.value) {
            filterSearchedItem();
          }

          updateStartEndIndex();
          resetVisibleList();

          // 如果还有更多的历史已读消息就预先加载50条到本地内存里，方面下次取的时候效率高些
          preloadPreviousMessages();
        }
      });
    }
  }

  bool _isExistSentMessage(Message message) {
    bool isMine = objectMgr.userMgr.isMe(message.send_id);
    if (!isMine) {
      return false;
    }
    int nextIndex = nextMessageList.indexWhere((e) =>
        e.send_id == message.send_id && e.send_time == message.send_time);
    int previousIndex = previousMessageList.indexWhere((e) =>
        e.send_id == message.send_id && e.send_time == message.send_time);

    if (nextIndex >= 0 || previousIndex >= 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> loadNextMessages({int messageCount = 0}) async {
    int requestCount = 0;
    if (!isEnd()) {
      int fromIdx = endMessage != null ? endMessage!.chat_idx : 0;
      int fromTime = endMessage != null ? endMessage!.create_time : 0;
      requestCount = messageCount > 0 ? messageCount : messagePageCount;
      List<Message> tempMessageList = await objectMgr.chatMgr.loadMessageList(
          chat,
          fromIdx: fromIdx + 1,
          forward: 1,
          count: requestCount,
          fromTime: fromTime);

      pdebug("loadNext===> ${endMessage?.chat_idx}-${tempMessageList.length}");

      await uiMessageListLock.synchronized(() async {
        if (tempMessageList.isNotEmpty) {
          List<Message> messageList = [];
          for (final m in tempMessageList) {
            if (messageSet.contains(m.id) || _isExistSentMessage(m)) continue;
            messageSet.add(m.id);
            messageList.add(m);
            //pdebug("loadNext===> chat idx:${m.chat_idx} content: ${m.content}");
          }

          /// 插入时间逻辑
          processDateByMessages(messageList, isPrevious: false);
          // 当previousList数量小于填充整个屏幕高度的时候，为了填充整个屏幕需要把n+previousMessageList.length=20个消息放到previousList里面去
          final int prevMsgListDiff =
              prevMessageListThreshold - previousMessageList.length;
          if (prevMsgListDiff > 0) {
            final List<Message> msgList = messageList
                .getRange(
                    0,
                    messageList.length > prevMsgListDiff
                        ? prevMsgListDiff
                        : messageList.length)
                .toList();
            objectMgr.chatMgr.sortMessage(msgList);
            previousMessageList.insertAll(0, msgList);

            if (messageList.length > prevMsgListDiff) {
              messageList.removeRange(0, prevMsgListDiff);
              nextMessageList.addAll(messageList);
            }
          } else {
            nextMessageList.addAll(messageList);
          }
        }
      });

      if (isSearching.value) {
        filterSearchedItem();
      }

      updateStartEndIndex();
      resetVisibleList();

      // 如果还有更多的未读消息就提前与加载50条到本地内存里，方面下次取的时候效率高些
      preloadNextMessages();
    }
  }

  preloadNextMessages() async {
    if (!noMoreNext) {
      int fromIdx = endMessage != null ? endMessage!.chat_idx : 0;
      int fromTime = endMessage != null ? endMessage!.create_time : 0;
      objectMgr.scheduleMgr.chatMessageTask.preLoadDBMessages(chat,
          fromChatIdx: fromIdx,
          forward: 1,
          count: messagePageCount * 6,
          fromTime: fromTime);
    }
  }

  preloadPreviousMessages() async {
    if (!noMorePrevious) {
      int fromIdx =
          startMessage != null ? startMessage!.chat_idx : chat.msg_idx;
      int fromTime = startMessage != null ? startMessage!.create_time : 0;
      objectMgr.scheduleMgr.chatMessageTask.preLoadDBMessages(chat,
          fromChatIdx: fromIdx,
          forward: 0,
          count: messagePageCount * 6,
          fromTime: fromTime);
    }
  }

  preloadInitMessages() async {
    objectMgr.scheduleMgr.chatMessageTask.addChatItem(chat, force: true);
  }

  bool isEnd() {
    _updateEndIndex();
    return noMoreNext;
  }

  bool isFirst() {
    _updateStartIndex();
    return noMorePrevious;
  }

  void _updateUnreadPosition(sender, type, data) async {
    if (data != null) {
      ///17224 2422457

      int chatId = data["id"] ?? 0;
      if (chatId == chat.id) {
        int newReadIdx = data['read_chat_msg_idx'] ?? 0;
        if (newReadIdx > chat.read_chat_msg_idx) {
          toMessagePosition(newReadIdx);
        }
      }
    }
  }

  /// 聊天室刷新
  onChatReload(sender, type, data) async {
    if (inputNotify.value.state != 0) {
      inputNotify.value.state = 2;
    }

    if (nextMessageList.isNotEmpty) {
      if (chat.msg_idx > nextMessageList.last.chat_idx) {
        noMoreNext = false;
      }
    } else if (previousMessageList.isNotEmpty) {
      if (chat.msg_idx > previousMessageList.first.chat_idx) {
        noMoreNext = false;
      }
    }
  }

  onChatMessageDelete(sender, type, data) {
    // 发送消息不属于当前聊天室
    if (data['id'] != chat.id) {
      return;
    }

    if (data['isClear']) {
      setDownButtonVisible(false);
      nextMessageList.clear();
      previousMessageList.clear();
      unreadBarMsg = null;
      messageSet.clear();
      messageKeys.clear();
      _clearStartEndIndex();
      oriUnread = 0;
      oriReadIdx = 0;
      resetVisibleList();
    } else {
      if (data['message'] != null) {
        for (var item in data['message']) {
          int id = 0;
          int message_id = 0;
          if (item is Message) {
            id = item.id;
          } else {
            message_id = item;
          }
          int nextMessageIndex = -1;
          int previousMessageIndex = -1;
          nextMessageIndex = nextMessageList.indexWhere((message) {
            if (id != 0) {
              return message.id == id;
            } else {
              return message.message_id == message_id;
            }
          });
          previousMessageIndex = previousMessageList.indexWhere((message) {
            if (id != 0) {
              return message.id == id;
            } else {
              return message.message_id == message_id;
            }
          });

          if (nextMessageIndex != -1) {
            nextMessageList.removeAt(nextMessageIndex);
            nextMessageList.refresh();
          } else if (previousMessageIndex != -1) {
            previousMessageList.removeAt(previousMessageIndex);
            previousMessageList.refresh();
          }
          if (unreadBarMsg != null && item.chat_idx == unreadBarMsg!.chat_idx) {
            removeUnreadBar();
          }
        }

        resetVisibleList();
      }
    }
  }

  onChatMessageAutoDelete(sender, type, data) {
    if (data != null && data is Message){
      if (chat.id == data.chat_id) {
        chooseMessage.removeWhere((key, value) => value.id == data.id);
        pinMessageList.removeWhere((element) => element.id == data.id);
      }
    }
  }

  onUpdateUnread(sender, type, data) {
    if (data is Chat) {
      if (data.chat_id == chat.chat_id && unreadCount != chat.unread_count) {
        if (chat.unread_count <= 0) {
          setDownButtonVisible(false);
        } else {
          setDownButtonVisible(true);
        }
        unreadCount.value = chat.unread_count;
      }
    }
  }

  onMessageComing(sender, type, data) async {
    if (!(data is Message)) {
      return;
    }

    if (data.chat_id != chat.id) {
      return;
    }

    if (data.typ == messageTypeAddReactEmoji ||
        data.typ == messageTypeRemoveReactEmoji ||
        data.typ == messageTypeDeleted) {
      return;
    }

    if (unreadBarMsg != null) {
      removeUnreadBar(removeUnreadBar: true);
      unreadBarMsg = null;
    }

    if (data.typ == messageTypePin || data.typ == messageTypeUnPin) {
      return;
    }
    pdebug(
        'onMessageComing===> ${data.chat_idx}|${endMessage?.chat_idx}-${endMessage?.message_id == 0}|${messageSet.contains(data.chat_idx)}');

    if (objectMgr.userMgr.isMe(data.send_id)) {
      objectMgr.chatMgr.updateSlowMode(message: data);
    }

    int endIdx =
        (endMessage?.chat_idx ?? max(chat.hide_chat_msg_idx, chat.start_idx));
    if (endIdx + 1 != data.chat_idx) {
      return;
    }
    if (objectMgr.chatMgr.chatMessageMap[chat.id] == null) {
      objectMgr.chatMgr.chatMessageMap[chat.id] = {};
    }
    if (objectMgr.chatMgr.chatMessageMap[chat.id]![data.id] == null) {
      objectMgr.chatMgr.chatMessageMap[chat.id]![data.id] = data;
    }
    if (!messageSet.contains(data.id)) {
      messageSet.add(data.id);
      addMoreNewMessageFromLock(data);
    }
  }

  void addMoreNewMessageFromLock(Message message) async {
    await uiMessageListLock.synchronized(() async {
      addMoreNewMessageFrom(message);
    });
  }

  addMoreNewMessageFrom(Message message) {
    addGameMessage(message);
    bool isMine = objectMgr.userMgr.isMe(message.send_id);
    int nextIndex = -1;
    int previousIndex = -1;
    if (isMine) {
      nextIndex = nextMessageList.indexWhere((e) =>
          e.send_id == message.send_id && e.send_time == message.send_time);
      previousIndex = previousMessageList.indexWhere((e) =>
          e.send_id == message.send_id && e.send_time == message.send_time);
    }
    pdebug(
        "_addMoreNewMessageFrom===> $nextIndex|$previousIndex|${message.chat_idx}|${message.send_time}|${message.content}");

    /// 本人刚发的消息在nextList
    if (nextIndex != -1) {
      if (nextMessageList[nextIndex].typ == messageTypeImage ||
          nextMessageList[nextIndex].typ == messageTypeVideo ||
          nextMessageList[nextIndex].typ == messageTypeReel ||
          nextMessageList[nextIndex].typ == messageTypeNewAlbum ||
          nextMessageList[nextIndex].typ == messageTypeLocation) {
        dynamic asset = nextMessageList[nextIndex].asset;
        message.asset = asset;
        message.showDoneIcon = true;
      }
      nextMessageList[nextIndex] = message;
      objectMgr.chatMgr.sortMessage(nextMessageList, ascending: true);
    } else if (previousIndex != -1) {
      // 本人刚发的消息在previousList
      if (previousMessageList[previousIndex].typ == messageTypeImage ||
          previousMessageList[previousIndex].typ == messageTypeVideo ||
          previousMessageList[previousIndex].typ == messageTypeReel ||
          previousMessageList[previousIndex].typ == messageTypeNewAlbum) {
        dynamic asset = previousMessageList[previousIndex].asset;
        message.asset = asset;
        message.showDoneIcon = true;
      }
      previousMessageList[previousIndex] = message;
      objectMgr.chatMgr.sortMessage(previousMessageList);
    } else {
      // 其他人发的消息
      // 消息没有满屏时，新来的消息如果放到next里面会藏在下面，需要手动往上滑才可以
      if (previousMessageList.length < prevMessageListThreshold) {
        List<Message> addMessages = [];
        addMessages.add(message);

        bool addDateMessage = endMessage != null
            ? FormatTime.iSameDay(message.create_time, endMessage!.create_time)
                ? false
                : true
            : true;
        if (addDateMessage) {
          if (message.typ != messageTypeAddReactEmoji &&
              message.typ != messageTypeRemoveReactEmoji)
            addMessages.add(getDateMessage(message, sendTime: -1));
        }

        if (nextMessageList.isNotEmpty) {
          List<Message> nextMessages = List.from(nextMessageList);
          objectMgr.chatMgr.sortMessage(nextMessages);
          addMessages.addAll(nextMessages);
          nextMessageList.clear();
        }
        previousMessageList.insertAll(0, addMessages);
      } else {
        List<Message> addMessages = [];

        ///从通知点进来的需要加入未读消息的分割
        if (fromNotificationTap &&
            message.chat_idx > chat.read_chat_msg_idx &&
            message.isChatRoomVisible &&
            unreadBarMsg == null) {
          addMessages.add(getUnreadBar(message));
          fromNotificationTap = false;
        }

        bool addDateMessage = endMessage != null
            ? FormatTime.iSameDay(message.create_time, endMessage!.create_time)
                ? false
                : true
            : true;
        if (message.create_time < endMessage!.create_time) {
          addDateMessage = false;
        }
        if (addDateMessage) {
          addMessages.add(getDateMessage(message, sendTime: -1));
        }
        addMessages.add(message);
        nextMessageList.addAll(addMessages);
      }

      if (message.typ == messageTypeGetRed) {
        objectMgr.chatMgr.event(
          objectMgr.chatMgr,
          ChatMgr.eventRedPacketStatus,
          data: message,
        );
      }
    }

    _updateEndIndex();
    resetVisibleList();
    updateStartEndIndex();

    if (message.typ == messageTypeAutoDeleteInterval) {
      final msgInterval = message.decodeContent(cl: MessageInterval.creator);
      if (msgInterval.interval != 0) {
        isAutoDeleteIntervalEnable = true;
      } else {
        isAutoDeleteIntervalEnable = false;
      }
    }

    bool shouldScroll = true;

    if (message.typ == messageTypeAddReactEmoji ||
        message.typ == messageTypeRemoveReactEmoji) {
      shouldScroll = false;
    }

    /// pin message 的sendId有可能是自己
    double offset = messageListController.offset -
        messageListController.position.minScrollExtent;
    final isBetMsg = messageBetTypes.contains(message.typ);
    if (isBetMsg && offset < 50) {
      handleMessage20005(message, isMine);
    } else {
      if (!popupEnabled &&
          ((objectMgr.userMgr.isMe(message.send_id) &&
              shouldScroll &&
              message.typ != messageTypePin &&
              message.typ != messageTypeUnPin) ||
              offset < 20)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          messageListController.animateTo(
              messageListController.position.minScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear);
        });

        if (!isMine) {
          chat.readMessage(message.chat_idx);
        }

        setDownButtonVisible(false);
        unreadCount.value = 0;
      }
    }


    if (!objectMgr.userMgr.isMe(message.send_id) && message.isChatRoomVisible) {
      unreadCount.value = chat.unread_count;
    }
  }

  onMessageSend(sender, type, data) async {
    await uiMessageListLock.synchronized(() async {
      onMessageSendLock(sender, type, data);
    });
  }

  onMessageSendLock(sender, type, data) {
    if (data.message_id == 0) {
      if (data.chat_id != chat.chat_id || _isExistSentMessage(data)) {
        return;
      }
      int endIdx =
          (endMessage?.chat_idx ?? max(chat.hide_chat_msg_idx, chat.start_idx));
      if (endIdx < data.chat_idx) {
        int fromTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        showMessageOnScreen(chat.msg_idx, 0, fromTime,
            shouldDisappear: false, isMustFind: false);
        chat.readMessage(chat.msg_idx);
        unreadCount.value = 0;
      }

      // todo: 时间插入逻辑有问题
      if (previousMessageList.length < prevMessageListThreshold) {
        List<Message> nextMessages = nextMessageList.reversed.toList();

        bool addDateMessage = endMessage != null
            ? FormatTime.iSameDay(data.create_time, endMessage!.create_time)
                ? false
                : true
            : true;
        if (addDateMessage) {
          final sameDateBarExist = previousMessageList.indexWhere((e) =>
              e.typ == messageTypeDate &&
              FormatTime.iSameDay(data.create_time, e.create_time));
          if (sameDateBarExist == -1) {
            nextMessages.add(getDateMessage(data,
                sendTime: DateTime.now().millisecondsSinceEpoch));
          }
        }

        previousMessageList.insertAll(0, nextMessages);
        previousMessageList.insert(0, data);
        nextMessageList.clear();
      } else {
        bool addDateMessage = endMessage != null
            ? FormatTime.iSameDay(data.create_time, endMessage!.create_time)
                ? false
                : true
            : true;
        if (addDateMessage) {
          nextMessageList.add(getDateMessage(data, sendTime: -1));
        }

        nextMessageList.add(data);
      }

      resetVisibleList();

      if (data.typ == messageTypeAddReactEmoji ||
          data.typ == messageTypeRemoveReactEmoji) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        messageListController.animateTo(
            messageListController.position.minScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear);
      });
    }
  }

  void removeMessage(Message sendMessage) {
    bool nextCheck = true;
    for (Message msg in previousMessageList) {
      if (msg.id == sendMessage.id) {
        previousMessageList.remove(msg);
        nextCheck = false;
        break;
      }
    }

    if (nextCheck) {
      for (Message msg in nextMessageList) {
        if (msg.id == sendMessage.id) {
          nextMessageList.remove(msg);
          break;
        }
      }
    }
    updateStartEndIndex();
  }

  void removeUnreadBar({
    bool removeUnreadBar = false,
  }) {
    int prevUnreadBarIndex =
        previousMessageList.indexWhere((m) => m.typ == messageTypeUnreadBar);
    int nextUnreadBarIndex =
        nextMessageList.indexWhere((m) => m.typ == messageTypeUnreadBar);

    if (prevUnreadBarIndex != -1) {
      _removeUnreadBarInPreviousList(prevUnreadBarIndex);
      if (removeUnreadBar) {
        previousMessageList.removeAt(prevUnreadBarIndex);
        unreadBarMsg = null;
      }
    }

    if (nextUnreadBarIndex != -1) {
      _removeUnreadBarInNextList(nextUnreadBarIndex);

      if (removeUnreadBar) {
        nextMessageList.removeAt(nextUnreadBarIndex);
        unreadBarMsg = null;
      }
    }
  }

  _removeUnreadBarInPreviousList(int prevUnreadBarIndex) {
    Message? validMessage;
    for (int i = prevUnreadBarIndex - 1; i >= 0; i--) {
      final Message message = previousMessageList[i];
      if (!message.isChatRoomVisible) {
        continue;
      }

      if (message.typ == messageTypeGetRed) {
        MessageRed msgRed = message.decodeContent(cl: MessageRed.creator);
        if (msgRed.userId != objectMgr.userMgr.mainUser.uid &&
            msgRed.senderUid != objectMgr.userMgr.mainUser.uid) {
          continue;
        }
      }

      validMessage = message;
      break;
    }

    for (final message in nextMessageList) {
      if (!message.isChatRoomVisible) {
        continue;
      }

      if (message.typ == messageTypeGetRed) {
        MessageRed msgRed = message.decodeContent(cl: MessageRed.creator);
        if (msgRed.userId != objectMgr.userMgr.mainUser.uid &&
            msgRed.senderUid != objectMgr.userMgr.mainUser.uid) {
          continue;
        }
      }

      validMessage = message;
      break;
    }

    //删除的消息的上方是unreadBar, 下方没有消息或者全是不显示的消息时移除unreadBar
    if (validMessage == null) {
      previousMessageList.removeAt(prevUnreadBarIndex);
      unreadBarMsg = null;
    } else {
      // 更新unreadBar的idx
      unreadBarMsg?.chat_idx = validMessage.chat_idx;
    }

    pdebug("previousUpdateUnreadBar===============> ${unreadBarMsg?.chat_idx}");
  }

  _removeUnreadBarInNextList(int nextUnreadBarIndex) {
    Message? validMessage;
    for (int i = nextUnreadBarIndex + 1; i < nextMessageList.length; i++) {
      final Message message = nextMessageList[i];
      if (!message.isChatRoomVisible) {
        continue;
      }

      if (message.typ == messageTypeGetRed) {
        MessageRed msgRed = message.decodeContent(cl: MessageRed.creator);
        if (msgRed.userId != objectMgr.userMgr.mainUser.uid &&
            msgRed.senderUid != objectMgr.userMgr.mainUser.uid) continue;
      }

      validMessage = message;
      break;
    }

    if (validMessage == null) {
      nextMessageList.removeAt(nextUnreadBarIndex);
    } else {
      unreadBarMsg?.chat_idx = validMessage.chat_idx;
    }

    pdebug("NextUpdateUnreadBar===============> ${unreadBarMsg?.chat_idx}");
  }

  _onSetPassword(Object sender, Object type, Object? data) async {
    if (data is bool) {
      if (data) {
        checkPasscodeStatus();
      }
    }
  }

  _onDelMentionListChange(Object sender, Object type, Object? data) async {
    if (data is Message &&
        data.isMentionMessage(objectMgr.userMgr.mainUser.uid)) {
      mentionChatIdxList
          .removeWhere((message) => message.chat_idx == data.chat_idx);
      if (objectMgr.chatMgr.mentionMessageMap[data.chat_id] != null) {
        objectMgr.chatMgr.mentionMessageMap[data.chat_id]!
            .remove(data.chat_idx);
      }
    }
  }

  _onAddMentionListChange(Object sender, Object type, Object? data) async {
    if (data is Message && data.chat_id == chat.id) {
      bool find = false;
      mentionChatIdxList.forEach((element) {
        if (element.chat_idx == data.chat_idx) {
          find = true;
          return;
        }
      });
      if (find) {
        return;
      }
      if (data.isMentionMessage(objectMgr.userMgr.mainUser.uid)) {
        mentionChatIdxList.add(data);
      }
    }
  }

  /// ============================== 共享函数 ===================================
  void onCancelFocus() {
    /// 输入框部分 重置
    CustomInputController? _inputController;
    if (Get.isRegistered<CustomInputController>(tag: chat.id.toString())) {
      _inputController =
          Get.find<CustomInputController>(tag: chat.id.toString());
    }

    if (_inputController != null) {
      _inputController.inputState = 0;
      showMentionList.value = false;
      _inputController.inputFocusNode.unfocus();
      _inputController.update();
      showAttachmentView.value = false;
    }

    if (isSearching.value) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    pdebug(
        "onCancelFocus=========> ${FocusManager.instance.primaryFocus?.hasFocus} | ${_inputController?.inputFocusNode.hasFocus}");
    if (Platform.isIOS &&
        (FocusManager.instance.primaryFocus?.hasFocus ?? false)) {
      // if(Get.isRegistered<ChatListController>()){
      //   ChatListController chatListController = Get.find<ChatListController>();
      //   chatListController.searchFocus.requestFocus();
      //   Future.delayed(const Duration(milliseconds: 300), () => chatListController.searchFocus.unfocus());
      // }
    }

    _inputController?.isShowShortTalk.value = false;
    showFaceView.value = false;
  }

  void resetVisibleList() {
    visibleMessageList.clear();
    visibleMessageList
        .addAll(combinedMessageList.where((e) => e.isChatRoomVisible).toList());
    objectMgr.chatMgr.sortMessage(visibleMessageList);
  }

  /// 选择更多消息 函数部分
  void addChooseMessage(Message message, User user) {
    if (message.message_id == 0) {
      chooseMessage[message.send_time] = message;
    } else {
      chooseMessage[message.message_id] = message;
    }
  }

  void removeChooseMessage(int messageId) {
    if (chooseMessage.containsKey(messageId)) {
      chooseMessage.remove(messageId);
    }
  }

  void onChooseMessage(BuildContext context, Message message) {
    if (chooseMessage.containsKey(
        message.message_id == 0 ? message.send_time : message.message_id)) {
      removeChooseMessage(
          message.message_id == 0 ? message.send_time : message.message_id);
    } else {
      addChooseMessage(message, objectMgr.userMgr.mainUser);
    }

    bool forward = true;
    chooseMessage.forEach((key, value) {
      // if (value.expire_time != 0) {
      //   canDelete.value = false;
      //   forward = false;
      //   return;
      // }

      if (!checkChatPermission(value)) {
        forward = false;
        return;
      }

      if (value.sendState == MESSAGE_SEND_ING) {
        canDelete.value = false;
        forward = false;
        return;
      } else {
        canDelete.value = true;
        forward = true;
      }

      if (value.sendState != MESSAGE_SEND_SUCCESS) {
        forward = false;
        return;
      }

      if (value.typ == messageTypeSendRed) {
        forward = false;
        return;
      }
    });

    canForward.value = forward &&
        GroupPermissionMap.groupPermissionForwardMessages
            .isAllow(permission.value);
  }

  /// 取消多选操作
  void onChooseMoreCancel() {
    chooseMessage.clear();
    chooseMore.value = false;
  }

  void onClearChooseMessage() {
    chooseMessage.clear();
  }

  /// 进入详情页
  /// 单聊 -> id 为 对方 friend_id
  /// 群聊 -> id 为 群聊 chat_id
  Future<void> onEnterChatInfo(
    bool isSingle,
    Chat chat,
    int id,
  ) async {
    playerService.stopPlayer();
    playerService.resetPlayer();
    showMentionList.value = false;
    if (Get.isRegistered<CustomInputController>(tag: chat.id.toString())) {
      Get.find<CustomInputController>(tag: chat.id.toString())
          .inputFocusNode
          .unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    }
    if (Get.isRegistered<ChatInfoController>()) {
      Get.back();
    } else {
      if (isSingle) {
        final User? user = await objectMgr.userMgr.loadUserById(id);
        if (user != null) {
          Get.toNamed(RouteName.chatInfo,
                  arguments: {"uid": user.uid},
                  id: objectMgr.loginMgr.isDesktop ? 1 : null)!
              .whenComplete(() => FocusNode().requestFocus());
        }
      } else {
          //代表是開通狀態
          Get.toNamed(RouteName.groupChatGameInfo,
                  arguments: {'groupId': chat.id},
                  id: objectMgr.loginMgr.isDesktop ? 1 : null)!
              .whenComplete(() => FocusNode().requestFocus())
              .then((value) {
            if (value is Function()) {
              value.call();
            }
            if(sharedDataManager.isNeedRefreshGroupData)
            sharedDataManager.onGameInit();
          });
      }
    }
  }

  GlobalKey? getMessageKey(Message message) {
    if (messageKeys.containsKey(message.message_id) &&
        messageKeys[message.message_id]!.currentContext == null) {
      messageKeys[message.message_id] = GlobalKey();
    }
    return messageKeys[message.message_id];
  }

  setDownButtonVisible(bool isVisible) {
    if (!isVisible) {
      if (showScrollBottomBtn.value) {
        showScrollBottomBtn(false);
      }
    } else if (!showScrollBottomBtn.value) {
      showScrollBottomBtn(true);
    }
  }

  /// ================================== 搜索 ===================================
  Future<void> searchMessageFromColdTable(String content, int chat_id) async {
    List<String> tables = await objectMgr.localDB.getColdMessageTables(0, 0);
    for (int i = 0; i < tables.length; i++) {
      List<Message> messages = [];
      List<Map<String, dynamic>> rows = await objectMgr.localDB
          .searchMessage(content, tbname: tables[i], chat_id: chat.id);
      messages = objectMgr.chatMgr.searchMessageFromRows(content, rows);
      messages.sort((a, b) => b.create_time - a.create_time);
      if (content != searchParam.value) {
        return;
      }
      searchedIndexList.addAll(messages);
      messages.clear();
    }
  }

  void getIndexList() async {
    await filterSearchedItem();
    if (searchedIndexList.isNotEmpty) {
      showMessageOnScreen(searchedIndexList.first.chat_idx,
          searchedIndexList.first.id, searchedIndexList.first.create_time);
    }

  }

  filterSearchedItem() async {
    await searchMsgLock.synchronized(() async {
      if (preSearchContent == searchParam.value) {
        return;
      }
      preSearchContent = searchParam.value;
      searchedIndexList.value = [];
      listIndex.value = 0;
      if (!notBlank(searchParam.value)) {
        return;
      }
      // 暂时储存信息的列表
      await searchMessageFromColdTable(searchParam.value, chat.chat_id);
    });
  }

  toMessagePosition(int chatIdx) async {
    // int previousIndex =
    //     previousMessageList.indexWhere((e) => chatIdx == e.chat_idx);
    // if (previousIndex > 0) {
    //   searchMessage(chatIdx, true);
    //   return;
    // }
    //
    // int nextIndex = nextMessageList.indexWhere((e) => chatIdx == e.chat_idx);
    // if (nextIndex != -1) {
    //   searchMessage(chatIdx, false);
    //   return;
    // }

    /// fromIdx > toIdx
    // int fromIdx = chatIdx;
    // int toIdx = fromIdx - messagePageCount;
    // if(chat.msg_idx == chatIdx){
    //   fromIdx = -1;
    //   if(fromIdx - chat.hide_chat_msg_idx < messagePageCount){
    //     toIdx = chat.hide_chat_msg_idx;
    //   }
    // }else if(chat.msg_idx > chatIdx){
    //   if(chat.msg_idx - fromIdx >= messagePageCount ~/ 2){
    //     fromIdx = fromIdx + messagePageCount ~/ 2;
    //   }
    //
    //
    // }
    //
    // if(toIdx > 0){
    //   Get.find<ChatContentController>(tag: chat.id.toString()).scrollToBottomMessage(fromIdx: fromIdx);
    // }
  }

  void showMessageOnScreen(int chat_idx, int id, int create_time,
      {bool shouldDisappear = true, bool isMustFind = true}) async {
    if (scrollMessage(chat_idx, id, shouldDisappear: shouldDisappear)) {
      return;
    }
    int end_idx = (endMessage != null) ? endMessage!.chat_idx : 0;
    int start_idx = (startMessage != null) ? startMessage!.chat_idx : 0;
    if (isMustFind && chat_idx >= start_idx && chat_idx <= end_idx) {
      Toast.showToast(localized(unableToFindMessage));
      return;
    }
    List<Message> messageList = await objectMgr.chatMgr.loadMessageList(chat,
        fromIdx: chat_idx,
        extra: 0,
        count: messagePageCount,
        fromTime: create_time);
    bool isContinue = true;
    if (isMustFind) {
      var index = -1;
      if (id == 0) {
        index =
            messageList.indexWhere((element) => element.chat_idx == chat_idx);
      } else {
        index = messageList.indexWhere((element) => element.id == id);
      }
      if (index == -1) {
        isContinue = false;
      }
    }
    if (messageList.isNotEmpty && isContinue) {
      _clearStartEndIndex();
      processDateByMessages(messageList, isPrevious: true);
      messageKeys.clear();
      previousMessageList.clear();
      nextMessageList.clear();
      messageSet.clear();

      previousMessageList.assignAll(messageList);

      updateStartEndIndex();
      resetVisibleList();
      if (!noMoreNext) {
        await loadNextMessages(messageCount: messagePageCount);
      }
      scrollMessage(chat_idx, id, shouldDisappear: shouldDisappear);
      return;
    }
    Toast.showToast(localized(unableToFindMessage));
  }

  void locateToSpecificPosition(List<int> indexList) =>
      showMessageOnScreen(indexList.first, 0, 0);

  void previousSearch() {
    if (listIndex == 0) return;
    listIndex -= 1;
    Message? msg = searchedIndexList[listIndex.value];
    if (msg == null) return;
    showMessageOnScreen(msg.chat_idx, msg.id, msg.create_time);
  }

  void nextSearch() {
    if (listIndex == searchedIndexList.length - 1) return;
    listIndex += 1;
    Message? msg = searchedIndexList[listIndex.value];
    if (msg == null) return;
    showMessageOnScreen(msg.chat_idx, msg.id, msg.create_time);
  }

  void clearSearching() {
    isSearching(false);
    searchController.clear();
    searchParam.value = '';
    getIndexList();
  }

  /// 搜索联系人列表
  onSearchContactChanged(String value) {
    searchContactParam.value = value;
    getFriendList();
  }

  void clearContactSearching() {
    isContactSearching(false);
    searchContactController.clear();
    searchContactParam.value = '';
    getFriendList();
  }

  getFriendList() {
    if (searchContactParam.value.isNotEmpty) {
      friendList.value = objectMgr.userMgr.filterFriends
          .where((element) => objectMgr.userMgr
              .getUserTitle(element)
              .toLowerCase()
              .contains(searchContactParam.toLowerCase()))
          .toList();
    } else {
      friendList.value = objectMgr.userMgr.filterFriends;
    }
  }

  /// =============================== 特殊函数逻辑 ===============================

  void onCreateHighlightTimer() {
    highlightTimer?.cancel();
    highlightTimer = null;
    final timer = Timer(const Duration(seconds: 1), () {
      highlightIndex.value = {
        'list': 0,
        'index': -9999999999,
      };
      onCloseHighlightTimer();
    });
    highlightTimer = timer;
  }

  void onCloseHighlightTimer() {
    highlightTimer?.cancel();
    highlightTimer = null;
  }

  void resetPopupWindow() {
    popupEnabled = false;
    chatPopEntry?.remove();
    chatPopEntry = null;
  }

  void getMemberPermission(bool isMember) {
    if (isMember) {
      bool isSendTextVoice = GroupPermissionMap.groupPermissionSendTextVoice
          .isAllow(permission.value);
      bool isSendTextStickerEmoji = GroupPermissionMap
          .groupPermissionSendTextStickerEmoji
          .isAllow(permission.value);
      bool isSendMedia =
          GroupPermissionMap.groupPermissionSendMedia.isAllow(permission.value);
      bool isSendDocument = GroupPermissionMap.groupPermissionSendDocument
          .isAllow(permission.value);
      bool isSendContacts = GroupPermissionMap.groupPermissionSendContacts
          .isAllow(permission.value);
      bool isSendRedPacket = GroupPermissionMap.groupPermissionSendRedPacket
          .isAllow(permission.value);
      bool isGameGroupSendMsg = GameGroupPermissionMap.groupPermissionSendMsg
          .isAllow(permission.value);
      pinEnable.value =
          GroupPermissionMap.groupPermissionPin.isAllow(permission.value);
      linkEnable =
          GroupPermissionMap.groupPermissionSendLink.isAllow(permission.value);
      canForward.value = GroupPermissionMap.groupPermissionForwardMessages
          .isAllow(permission.value);
      showTextVoice = isSendTextVoice;
      showTextStickerEmoji = isSendTextStickerEmoji;
      showGallery = isSendMedia;
      showDocument = isSendDocument;
      showContact = isSendContacts;
      showRedPacket = isSendRedPacket;
      if (isGameGroupSendMsg) {
        inputType.value = 8;
        return;
      }
      if (!isSendTextVoice) {
        if (isSendTextStickerEmoji &&
            (isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 1; // only text not allowed
        } else if (isSendTextStickerEmoji &&
            !(isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 3; // only sticker allowed
        } else if (isSendMedia ||
            isSendDocument ||
            isSendContacts ||
            isSendRedPacket) {
          inputType.value = 2; // Add attachment
        } else {
          inputType.value = 4; // Sending message not allowed
        }
      } else {
        if (!isSendTextStickerEmoji &&
            (isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 5; // Text allow but sticker not allow
        } else if (isSendTextStickerEmoji &&
            !(isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 6; // Text allow but attachment not allow
        } else if (isSendTextStickerEmoji &&
            (isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 0; // show everything
        } else {
          inputType.value = 7; // Only text allow
        }
      }
    } else {
      inputType.value = 0;
    }
    showTransferMoney = !chat.isGroup;
  }

  Future<void> checkPasscodeStatus() async {
    bool? passwordStatus =
        await objectMgr.localStorageMgr.read(LocalStorageMgr.SET_PASSWORD);
    if (passwordStatus != null) {
      isSetPassword.value = passwordStatus;
    } else {
      Secure? data = await SettingServices().getPasscodeSetting();
      if (data != null) {
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.SET_PASSWORD, !data.isNoPassword);
        isSetPassword.value = !data.isNoPassword;
      }
    }
  }

  /// Desktop Functions

  Future<void> checkFileType(List<XFile> files) async {
    allVideo = false;
    allImage = false;
    fileTypeList.clear();
    fileTypeList = files.map((file) => getFileType(file.path)).toList();

    if (hasAllSameFile(FileType.image)) {
      allImage = true;
    }

    if (hasAllSameFile(FileType.video)) {
      allVideo = true;
    }
  }

  Future<void> dropDesktopFile(
    DropDoneDetails details,
    BuildContext context,
  ) async {
    ///获取指定地区
    final Offset offset = details.localPosition;
    RenderBox dropAreaBox =
        ((upperDropAreaKey.currentContext ?? lowerDropAreaKey.currentContext)
            ?.findRenderObject() as RenderBox);

    final dropAreaHeight = dropAreaBox.size.height;
    final dropAreaWidth = dropAreaBox.size.width;

    Rect upperDropArea = Rect.fromLTWH(30, 15, dropAreaWidth, dropAreaHeight);
    Rect lowerDropArea =
        Rect.fromLTWH(30, 30 + dropAreaHeight, dropAreaWidth, dropAreaHeight);

    ///辨认发送的种类
    if (upperDropArea.contains(offset)) {
      if (allImage || allVideo) {
        ChatHelp.desktopSendFile(details.files, chat.id, '', null);
      }
    }

    if (lowerDropArea.contains(offset)) {
      if (allImage || allVideo) {
        captionController.text = '';
        captionController.clear();
        DesktopGeneralDialog(
          context,
          widgetChild: AttachFileDialog(
            title: allImage
                ? localized(image)
                : allVideo
                    ? localized(video)
                    : localized(media),
            file: details.files,
            chatId: chat.id,
            fileType: allImage
                ? FileType.image
                : allVideo
                    ? FileType.video
                    : FileType.allMedia,
          ),
        );
      } else {
        ChatHelp.desktopSendFile(details.files, chat.id, '', null);
      }
    }
  }

  @override
  void onClose() {
    CustomTextEditingController.mentionRange.clear();
    // playerService.stopPlayer();
    // playerService.resetPlayer();
    resetPopupWindow();
    redPacketEntry?.remove();
    redPacketEntry = null;
    unreadBarMsg = null;
    if (searchMsg != null &&
        objectMgr.chatMgr.chatMessageMap[chat.id] != null &&
        objectMgr.chatMgr.chatMessageMap[chat.id]![searchMsg!.id] != null) {
      objectMgr.chatMgr.chatMessageMap[chat.id]![searchMsg!.id]!.select = 0;
    }

    if (objectMgr.chatMgr.chatMessageMap[chat.id] != null) {
      objectMgr.chatMgr.chatMessageMap[chat.id]!.removeWhere((key, value) =>
          (value.chat_idx + messagePageCount < chat.read_chat_msg_idx) ||
          (chat.read_chat_msg_idx + 20 < value.chat_idx));
    }
    objectMgr.chatMgr.off(ChatMgr.eventMessageSend, onMessageSend);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, onMessageComing);
    objectMgr.chatMgr.off(ChatMgr.eventChatReload, onChatReload);
    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, onChatMessageAutoDelete);
    objectMgr.chatMgr.off(ChatMgr.eventSetPassword, _onSetPassword);
    objectMgr.chatMgr
        .off(ChatMgr.eventAddMentionChange, _onAddMentionListChange);
    objectMgr.chatMgr
        .off(ChatMgr.eventDelMentionChange, _onDelMentionListChange);
    objectMgr.chatMgr.off(ChatMgr.eventUnreadPosition, _updateUnreadPosition);
    objectMgr.chatMgr.off(ChatMgr.cancelKeyboardEvent, _updateUnreadPosition);
    FocusManager.instance.primaryFocus?.unfocus();
    messageListController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  bool checkChatPermission(Message value) {
    bool status = true;

    if ((value.typ == messageTypeText || value.typ == messageTypeVoice) &&
        !showTextVoice) {
      status = false;
    }

    if (value.typ == messageTypeFace && !showTextStickerEmoji) {
      status = false;
    }

    if ((value.typ == messageTypeImage ||
            value.typ == messageTypeVideo ||
            value.typ == messageTypeReel ||
            value.typ == messageTypeNewAlbum) &&
        !showGallery) {
      status = false;
    }

    if (value.typ == messageTypeFile && !showDocument) {
      status = false;
    }

    if (value.typ == messageTypeRecommendFriend && !showContact) {
      status = false;
    }

    if (value.typ == messageTypeSendRed && !showRedPacket) {
      status = false;
    }

    return status;
  }

  addMessageKeys(Message message, GlobalKey key) {
    messageKeys[message.message_id] = key;
  }

  void translateMessage(String text) {
    resetPopupWindow();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TranslateContainer(
          messageText: text,
        );
      },
    ).then((value) {
      Get.findAndDelete<TranslateController>();
    });
  }

  void handleMessage20005(Message message, bool isMine) {}

  void addGameMessage(Message newMessage) {}

  Future<void> transcribe(Message message) async {
    resetPopupWindow();

    MessageVoice messageVoice = message.decodeContent(cl: MessageVoice.creator);
    String mediaPath = messageVoice.url;
    if (notBlank(mediaPath)) {
      sendConvertTextEvent(message, "", true);

      try {
        final TranscribeModel data =
            await getTranscribeText("en,zh,jp", mediaPath);
        sendConvertTextEvent(message, data.transText ?? "", false);
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
        sendConvertTextEvent(message, "", false);
      }
    }
  }

  void sendConvertTextEvent(
      Message message, String convertText, bool isConverting) {
    EventTranscribeModel eventData = EventTranscribeModel(
      messageId: message.id,
      text: convertText,
      isConverting: isConverting,
    );
    message.event(Message, Message.eventConvertText, data: eventData);
  }

  void cancelBottomView() {
    final chatController =
        Get.find<CustomInputController>(tag: chat.id.toString()).chatController;
    chatController.showAttachmentView.value = false;
    chatController.showFaceView.value = false;
  }

  void _cancelKeyBoardEvent(Object sender, Object type, Object? data) {
    if (!showFaceView.value && !showAttachmentView.value) {
      bool b = FocusManager.instance.primaryFocus?.hasFocus ?? true;
      if (!b) {
        onCancelFocus();
      }
    }
  }
}

double get getKeyboardHeight {
  if (keyboardHeight.value == 0) {
    if (KeyBoardObserver.instance.keyboardHeightOpen < 200 &&
        keyboardHeight.value < 200) {
      keyboardHeight.value = getPanelFixHeight;
      KeyBoardObserver.instance.keyboardHeightOpen = getPanelFixHeight;
    } else {
      keyboardHeight.value = KeyBoardObserver.instance.keyboardHeightOpen;
      return keyboardHeight.value;
    }
    if (Platform.isIOS) {
      return 336.w;
    } else {
      return 240.w;
    }
  }
  return keyboardHeight.value;
}

double get getPanelFixHeight {
  if (Platform.isIOS) {
    var sWidth = 1.sw;
    var sHeight = 1.sh;
    if (sWidth == 430 && sHeight == 932) {
      return 346;
    } else if (sWidth == 375 && sHeight == 667) {
      ///iphone SE
      return 260;
    } else {
      return 336;
    }
  } else {
    return 294;
  }
}

double get getBottomInputAreaRealHeight {
  CustomInputController? controller = getFindOrNull<CustomInputController>();
  if (controller != null) {
    return (controller.chatController.showFaceView.value ||
            controller.chatController.showAttachmentView.value)
        ? getPanelFixHeight
        : controller.inputFocusNode.hasFocus
            ? getKeyboardHeight
            : 0;
  }
  return 0;
}
