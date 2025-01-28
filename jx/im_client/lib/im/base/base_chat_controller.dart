import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:agora/agora_plugin.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/record_audio_control_item.dart';
import 'package:jxim_client/im/custom_input/component/chat_attachment_view.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/services/audio_services/audios_to_play.dart';
import 'package:jxim_client/im/services/audio_services/desktop_audio_player.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/custom_text_editing_controller.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/read_more_model.dart';
import 'package:jxim_client/object/translate_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/special_container/special_container_util.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/get_utils.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/contact/friend_request_confirm.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views/red_packet/red_packet_page.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:jxim_client/views_desktop/component/attach_file_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

RxDouble keyboardHeight = 0.0.obs;

class BaseChatController extends GetxController
    with WidgetsBindingObserver, BaseChatControllerMixin {
  final BuildContext context = navigatorKey.currentContext!;
  final prevMessageListThreshold = 20;

  late Chat chat;

  RxBool chatIsDeleted = false.obs;

  AutoScrollController? messageListController;

  RxInt unreadCount = RxInt(0);
  int oriUnread = 0;
  int oriReadIdx = 0;

  final previousMessageList = <Message>[].obs;
  final nextMessageList = <Message>[].obs;
  final messageSet = <int>[];

  RxList<Message> get combinedMessageList =>
      RxList<Message>.from(nextMessageList)..addAll(previousMessageList);

  Message? visibleFirstMessage;
  final Map<int, GlobalKey> messageKeys = {};

  final pinMessageList = <Message>[].obs;

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
  RxBool showSearchBar = false.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  RxString searchParam = "".obs;
  String preSearchContent = "";

  Lock searchMsgLock = Lock();
  RxList<Message> searchedIndexList = RxList<Message>();

  RxInt listIndex = 0.obs;

  RxList<User> friendList = RxList<User>();
  RxBool isContactSearching = false.obs;
  final TextEditingController searchContactController = TextEditingController();
  final FocusNode searchContactFocusNode = FocusNode();
  RxString searchContactParam = "".obs;

  RxBool isShowDay = RxBool(false);

  final currMsgDayDisplay = 0.obs;

  int withdrawMessageId = 0;

  Message? searchMsg;

  Rx<ChatInput> inputNotify = Rx(ChatInput());

  RxBool showFaceView = RxBool(false);
  RxBool showAttachmentView = RxBool(false);

  late List<ChatAttachmentOption> attachmentOptions =
      List.empty(growable: true);

  late final attachmentPictureOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_picture.svg',
    title: localized(attachmentCallPicture),
    onTap: () {
      removeShortcutImage();
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
      removeShortcutImage();
      final controller =
          Get.find<CustomInputController>(tag: chat.id.toString());

      controller.onPhoto(context);
    },
  );

  late final attachmentCallViceOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_call_voice.svg',
    title: localized(attachmentCallVoice),
    onTap: () {
      removeShortcutImage();
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
      removeShortcutImage();
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
      removeShortcutImage();
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
      removeShortcutImage();
      Get.toNamed(
        RouteName.chatTransferMoney,
        arguments: {
          "chatId": chat.chat_id,
        },
      );
    },
  );

  late final attachmentFileOption = ChatAttachmentOption(
    icon: 'assets/svgs/attachment_file.svg',
    title: localized(attachmentFiles),
    onTap: () {
      removeShortcutImage();
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
      removeShortcutImage();
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
    removeShortcutImage();
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

  RxBool chooseMore = RxBool(false);

  RxBool isEnableFavourite = true.obs;

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

  RxBool showMentionList = false.obs;
  RxList<Message> mentionChatIdxList = RxList<Message>();

  Message? unreadBarMsg;

  final inputType = 0.obs;
  final permission = 999.obs;
  final pinEnable = true.obs;
  bool showTextVoice = true;
  bool showGallery = true;
  bool showDocument = true;
  bool showContact = true;
  bool showRedPacket = true;
  bool showTextStickerEmoji = true;
  bool linkEnable = true;
  bool isScreenshotEnabled = false;
  AppLifecycleState appState = AppLifecycleState.resumed;
  final isSetPassword = false.obs;

  final List<AudioPlayer> audioPlayersList = [];

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

  int unreadPosId = 0;

  bool fromNotificationTap = false;

  Lock uiMessageListLock = Lock();
  int oriChatIdx = 0;

  RxBool isGroupExpireSoon = false.obs;
  final showEditExpireShortcutArrow = false.obs;
  final remainingTime = '...'.obs;
  Timer? expireCountDownTimer;

  // 快捷发送图片
  var recentPhoto = Rxn<AssetEntity>();
  bool isFetching = false;
  final showShortcutImage = false.obs;
  final showShortcutAnimation = false.obs;
  Timer? _shortcutDismissTimer;
  int _remainingTime = 10;
  bool isAskingPermission = false;

  @override
  void onInit() {
    super.onInit();
    messageListController = AutoScrollController(initialScrollOffset: -8);
    CustomTextEditingController.mentionRange.clear();

    objectMgr.chatMgr.on(ChatMgr.eventUpdateUnread, onUpdateUnread);
    objectMgr.chatMgr.on(ChatMgr.eventMessageListComing, onMessageComing);
    objectMgr.chatMgr.on(ChatMgr.eventMessageSend, onMessageSend);
    objectMgr.chatMgr.on(ChatMgr.eventChatReload, onChatReload);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, onChatMessageAutoDelete);
    objectMgr.chatMgr
        .on(ChatMgr.eventAddMentionChange, _onAddMentionListChange);
    objectMgr.chatMgr
        .on(ChatMgr.eventDelMentionChange, _onDelMentionListChange);
    objectMgr.chatMgr.on(ChatMgr.eventSetPassword, _onSetPassword);
    objectMgr.chatMgr.on(ChatMgr.cancelKeyboardEvent, _cancelKeyBoardEvent);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, _onEditMessage);
    objectMgr.chatMgr.on(ChatMgr.eventDecryptChat, _onDecryptChat);
    objectMgr.chatMgr.on(ChatMgr.messageStopAllReading, _messageStopReading);
    if (chat.isTmpGroup) {
      objectMgr.myGroupMgr
          .on(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);
    }

    WidgetsBinding.instance.addObserver(this);

    ever(isSearching, (_) {
      if (isSearching.value) showFaceView(false);
    });

    if (!checkIsMute(chat.mute) && chat.isMute) {
      objectMgr.chatMgr.updateNotificationStatus(chat, 0);
    }

    unreadCount.value = chat.unread_count;
    oriUnread = chat.unread_count;
    oriReadIdx = chat.read_chat_msg_idx;
    oriChatIdx = chat.msg_idx;

    if (!objectMgr.loginMgr.isDesktop) {
      loadMentions();
    }

    checkPasscodeStatus();
    initPinMessages();
    initData();
    objectMgr.encryptionMgr.decryptChatIfNeeded(chat);
  }

  checkPhotoPermission() async {
    PermissionState ps = await requestAssetPickerPermission(showToast: false);
    if (ps == PermissionState.denied) return false;
    return true;
  }

  initData() async {
    int fromIdx = chat.msg_idx;
    int fromTime = 0;
    if (objectMgr.chatMgr.lastChatMessageMap[chat.id] != null &&
        objectMgr.chatMgr.lastChatMessageMap[chat.id]!.chat_idx > fromIdx) {
      fromIdx = objectMgr.chatMgr.lastChatMessageMap[chat.id]!.chat_idx;
    }

    if (unreadCount.value > 3) {
      setDownButtonVisible(true);
    }
    if (unreadCount.value > 20) {
      fromIdx = chat.read_chat_msg_idx + 20;
    }

    if (!objectMgr.loginMgr.isDesktop) {
      final arguments = Get.arguments as Map<String, dynamic>;
      if (arguments['selectedMsgIds'] != null &&
          arguments['selectedMsgIds'].length > 0) {
        searchMsg = arguments['selectedMsgIds'][0];
      }
    }

    if (searchMsg != null) {
      fromIdx = searchMsg!.chat_idx + 10;
      fromTime = searchMsg!.create_time;
      if (unreadCount.value > 0) {
        setDownButtonVisible(true);
      }
    }

    List<Message> messageList = await objectMgr.chatMgr.loadMessageList(
      chat,
      fromIdx: fromIdx,
      extra: 0,
      count: searchMsg != null ? prevMessageListThreshold : messagePageCount,
      fromTime: fromTime,
    );
    pdebug('initMessages===> ${messageList.length}');
    if (searchMsg != null && messageList.isNotEmpty) {
      for (var element in messageList) {
        if (element.id == searchMsg!.id) {
          element.select = 1;
        }
      }
    }
    if (messageList.isNotEmpty) {
      processDateByMessages(messageList, isPrevious: true);
      await initRenderListLock(messageList);
      if (searchMsg != null) {
        objectMgr.chatMgr
            .updateUnread(chat, searchMsg!.chat_idx, isForceDB: true);
        scrollMessage(
          searchMsg!.chat_idx,
          searchMsg!.id,
          shouldDisappear: true,
        );
      } else {
        scrollMessage(
          chat.read_chat_msg_idx + 1,
          unreadPosId,
          shouldDisappear: false,
          isInit: true,
        );
      }
    } else {
      toLoadMessages();
    }

    if (chat.isSingle) {
      attachmentOptions = [
        attachmentPictureOption,
        attachmentCameraOption,
        attachmentCallViceOption,
        attachmentCallVideoOption,
        attachmentLocationOption,
        attachmentTransferMoneyOption,
        attachmentFileOption,
        attachmentContactOption,
      ];
    } else if (chat.isGroup) {
      attachmentOptions = [
        attachmentPictureOption,
        attachmentCameraOption,
        attachmentCallViceOption,
        attachmentLocationOption,
        attachmentRedPacketOption,
        attachmentFileOption,
        attachmentContactOption,
      ];
    } else if (chat.isSaveMsg) {
      attachmentOptions = [
        attachmentPictureOption,
        attachmentCameraOption,
        attachmentLocationOption,
        attachmentFileOption,
        attachmentContactOption,
      ];
    } else {
      attachmentOptions = [
        attachmentPictureOption,
        attachmentCameraOption,
        attachmentFileOption,
      ];
    }

    if (!chat.isGroup && !isWalletEnable()) {
      attachmentOptions.remove(attachmentTransferMoneyOption);
    } else if (chat.isGroup && !isWalletEnable()) {
      attachmentOptions.remove(attachmentRedPacketOption);
    }
  }

  loadMentions() async {
    if (objectMgr.chatMgr.mentionMessageMap[chat.chat_id] != null) {
      mentionChatIdxList.addAll(
        objectMgr.chatMgr.mentionMessageMap[chat.chat_id]!.values.toList(),
      );
    }
  }

  bool scrollMessage(
    int chatIdx,
    int id, {
    bool shouldDisappear = false,
    bool isInit = false,
  }) {
    bool find = true;
    var preIndex = -1;
    var nextIndex = -1;
    if (id != 0) {
      preIndex = previousMessageList.indexWhere((element) => element.id == id);
      nextIndex = nextMessageList.indexWhere((element) => element.id == id);
    } else {
      preIndex = previousMessageList
          .indexWhere((element) => element.chat_idx == chatIdx);
      nextIndex = nextIndex =
          nextMessageList.indexWhere((element) => element.chat_idx == chatIdx);
    }

    if (preIndex == -1 && nextIndex == -1) {
      find = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((t) {
      int index = -1;
      if (preIndex == -1) {
        if (nextIndex != -1) {
          if (shouldDisappear) {
            highlightIndex.value = {
              'list': 1,
              'index': nextIndex,
            };
          }
          index = nextIndex;
        }
      } else {
        if (shouldDisappear) {
          highlightIndex.value = {
            'list': 0,
            'index': preIndex,
          };
        }
        index = preIndex;
      }
      var extraOffset = 0.0;
      if (chat.msg_idx > chatIdx + 3) {
        extraOffset = -150;
      }
      if (index != -1) {
        messageListController?.scrollToIndex(
          index,
          preferPosition:
              isInit ? AutoScrollPosition.middle : AutoScrollPosition.begin,
          duration: const Duration(milliseconds: 0),
          extraOffset: isInit ? 0 : extraOffset,
        );
        find = true;

        if (shouldDisappear) onCreateHighlightTimer();
      }

      if (fromNotificationTap) fromNotificationTap = false;
    });
    return find;
  }

  void toLoadMessages() async {
    List<Message> messageList = await ChatMgr.loadDBMessages(
      objectMgr.localDB,
      chat,
      count: messagePageCount,
      dbLatest: true,
    );

    if (messageList.isNotEmpty) {
      processDateByMessages(messageList, isPrevious: true);
      messageSet.addAll(messageList.map((e) => e.id));

      initRenderListLock(messageList);
    }
  }

  void processDateByMessages(
    List<Message> messages, {
    bool isPrevious = false,
  }) {
    if (messages.isEmpty) return;
    List<Message> copyMessages = List.from(messages);
    Message? preMessage;
    int dateAmount = 0;

    if (isPrevious && startMessage != null) {
      preMessage = startMessage;
      for (int i = 0; i < copyMessages.length; i++) {
        Message message = copyMessages[i];
        if (!message.isChatRoomVisible) continue;

        if (!FormatTime.iSameDay(
          message.create_time,
          preMessage!.create_time,
        )) {
          messages.insert(i + dateAmount, getDateMessage(preMessage));
          dateAmount++;
        }

        if (i == copyMessages.length - 1) {
          if (message.chat_idx == 1 ||
              message.chat_idx == chat.hide_chat_msg_idx + 1) {
            messages.add(getDateMessage(message));
          }
        }

        preMessage = message;
      }

      objectMgr.chatMgr.sortMessage(messages);
    } else if (!isPrevious && endMessage != null) {
      preMessage = endMessage;
      for (int i = 0; i < copyMessages.length; i++) {
        Message message = copyMessages[i];
        if (!message.isChatRoomVisible) continue;

        if (!FormatTime.iSameDay(
          message.create_time,
          preMessage!.create_time,
        )) {
          messages.insert(i + dateAmount, getDateMessage(message));
          dateAmount++;
        }

        preMessage = message;
      }

      objectMgr.chatMgr.sortMessage(messages, ascending: true);
    } else if (startMessage == null && endMessage == null) {
      for (int i = 0; i < copyMessages.length; i++) {
        Message message = copyMessages[i];
        if (!message.isChatRoomVisible) continue;

        if (preMessage != null) {
          if (!FormatTime.iSameDay(
            message.create_time,
            preMessage.create_time,
          )) {
            messages.insert(
              i + dateAmount,
              getDateMessage(
                isPrevious ? preMessage : message,
              ),
            );
            dateAmount++;
          }
        }

        if (i == copyMessages.length - 1) {
          if (message.chat_idx == 1 ||
              message.chat_idx == chat.hide_chat_msg_idx + 1) {
            messages.add(getDateMessage(message));
          }
        }

        preMessage = message;
      }

      objectMgr.chatMgr.sortMessage(messages);
    }
  }

  getDateMessage(Message message) {
    Message timeMsg = Message();
    timeMsg.message_id = message.message_id;
    timeMsg.chat_idx = message.chat_idx;
    timeMsg.create_time = message.create_time;
    timeMsg.chat_id = message.chat_id;
    timeMsg.send_time = message.send_time;
    timeMsg.typ = messageTypeDate;
    return timeMsg;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    appState = state;
    if (state != AppLifecycleState.resumed) {
      if (inputNotify.value.state != ChatInputState.noTyping) {
        inputNotify.value.state = ChatInputState.noTyping;
      }

      if (state == AppLifecycleState.paused) {
        if (audioManager.isVideoOn) {
          liveMemberListPageModel.turnOnOffVideo(context);
        }
        cancelBottomView();
      }
    }
  }

  initRenderListLock(List<Message> messages) async {
    await uiMessageListLock.synchronized(() async {
      List<Message> list = [];
      for (Message message in messages) {
        if (messageSet.contains(message.id) || message.isInvisibleMsg) {
          continue;
        }
        messageSet.add(message.id);
        list.add(message);
      }
      _initRenderList(list);
    });
  }

  _initRenderList(List<Message> messages) {
    List<Message> preListTmp = [];
    List<Message> nextListTmp = [];
    bool isNeedUnReadBar = false;
    Message? preMsg;
    for (Message message in messages.reversed) {
      if (preMsg != null) {
        int diffTime = message.send_time - preMsg.send_time;
        if (diffTime >= 120 * 1000 ||
            preMsg.send_id != message.send_id ||
            message.isSystemMsg) {
          message.isFirst = true;
          preMsg.isLast = true;
        }
      }
      preMsg = message;
      if (message.chat_idx <= chat.read_chat_msg_idx) {
        preListTmp.add(message);
      } else {
        if (!isNeedUnReadBar) {
          if (message.isSystemMsg || objectMgr.userMgr.isMe(message.send_id)) {
            preListTmp.add(message);
            continue;
          } else {
            isNeedUnReadBar = true;
            preListTmp.add(getUnreadBar(message));
          }
        }
        if (preListTmp.length > prevMessageListThreshold && isNeedUnReadBar) {
          nextListTmp.add(message);
        } else {
          preListTmp.add(message);
        }
      }
    }
    if (preMsg != null) {
      preMsg.isLast = true;
    }
    if (preListTmp.isNotEmpty) {
      previousMessageList.assignAll(preListTmp.reversed);
    }
    if (nextListTmp.isNotEmpty) {
      nextMessageList.assignAll(nextListTmp);
    }
    updateStartEndIndex();
  }

  Message getUnreadBar(Message message) {
    unreadBarMsg = Message.creator();
    unreadBarMsg?.typ = messageTypeUnreadBar;
    unreadBarMsg?.chat_idx = message.chat_idx;
    unreadBarMsg?.chat_id = message.chat_id;
    unreadBarMsg?.create_time = message.create_time;
    unreadBarMsg?.send_time = message.send_time + 1;
    unreadBarMsg?.id = unreadBarMsg!.getID();
    unreadPosId = unreadBarMsg!.getID();
    return unreadBarMsg!;
  }

  void initPinMessages() {
    List<Message> pinMessages =
        (objectMgr.chatMgr.pinnedMessageList[chat.id] ?? [])
            .where((e) => !e.isDeleted)
            .toList();
    if (chat.isActiveChatKeyValid) {
      for (var message in pinMessages) {
        if (message.isEncrypted) {
          MessageMgr.decodeMsg(message, chat, objectMgr.userMgr.mainUser.uid);
        }
      }
    }
    objectMgr.chatMgr.sortMessage(pinMessages);
    pinMessageList.assignAll(pinMessages);
  }

  void updateStartEndIndex() {
    _updateStartIndex();
    _updateEndIndex();
  }

  _updateStartIndex() {
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
  }

  _updateEndIndex() {
    if (nextMessageList.isNotEmpty) {
      for (int i = nextMessageList.length - 1; i >= 0; i--) {
        if (endMessage == null ||
            nextMessageList[i].chat_idx >= endMessage!.chat_idx) {
          endMessage = nextMessageList[i];
          break;
        }
      }
    } else if (previousMessageList.isNotEmpty) {
      for (int i = 0; i < previousMessageList.length; i++) {
        if (endMessage == null ||
            previousMessageList[i].chat_idx >= endMessage!.chat_idx) {
          endMessage = previousMessageList[i];
          break;
        }
      }
    }

    if (endMessage != null) {
      if (endMessage!.chat_idx >= chat.msg_idx) {
        noMoreNext = true;
      } else {
        int lastMsgIdx = -1;
        if (objectMgr.chatMgr.lastChatMessageMap[chat.id] != null) {
          lastMsgIdx = objectMgr.chatMgr.lastChatMessageMap[chat.id]!.chat_idx;
        }
        if (endMessage!.chat_idx >= lastMsgIdx) {
          noMoreNext = true;
        } else {
          noMoreNext = false;
        }
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
        "beforeLoadPrevious===>  ${startMessage?.chat_idx}-${previousMessageList.length}",
      );
      int fromIdx =
          startMessage != null ? startMessage!.chat_idx : chat.msg_idx;

      int fromTime = startMessage != null ? startMessage!.create_time : 0;
      List<Message> tempMessageList = await objectMgr.chatMgr.loadMessageList(
        chat,
        fromIdx: fromIdx - 1,
        count: messagePageCount,
        fromTime: fromTime,
      );

      await uiMessageListLock.synchronized(() async {
        if (tempMessageList.isNotEmpty) {
          List<Message> messageList = [];
          for (final m in tempMessageList) {
            if (messageSet.contains(m.id) ||
                m.isInvisibleMsg ||
                _isExistSentMessage(m)) continue;
            messageSet.add(m.id);
            messageList.add(m);
          }

          if (messageList.isEmpty) return;

          processDateByMessages(messageList, isPrevious: true);
          Message? preMsg;
          for (Message message in messageList.reversed) {
            if (preMsg != null) {
              int diffTime = message.send_time - preMsg.send_time;
              if (diffTime >= 120 * 1000 ||
                  preMsg.send_id != message.send_id ||
                  message.isSystemMsg) {
                message.isFirst = true;
                preMsg.isLast = true;
              }
            }
            preMsg = message;
          }
          if (previousMessageList.isNotEmpty) {
            int diffTime =
                previousMessageList.last.send_time - preMsg!.send_time;
            if (diffTime >= 120 * 1000 ||
                previousMessageList.last.send_id != preMsg.send_id) {
              previousMessageList.last.isFirst = true;
              preMsg.isLast = true;
            }
          }

          previousMessageList.addAll(messageList);

          if (isSearching.value) {
            filterSearchedItem();
          }

          updateStartEndIndex();
        }
      });
    }
  }

  bool _isExistSentMessage(Message message) {
    bool isMine = objectMgr.userMgr.isMe(message.send_id);
    if (!isMine) {
      return false;
    }
    int nextIndex = nextMessageList.indexWhere(
      (e) => e.send_id == message.send_id && e.send_time == message.send_time,
    );
    int previousIndex = previousMessageList.indexWhere(
      (e) => e.send_id == message.send_id && e.send_time == message.send_time,
    );

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
        fromTime: fromTime,
      );

      pdebug("loadNext===> ${endMessage?.chat_idx}-${tempMessageList.length}");

      await uiMessageListLock.synchronized(() async {
        if (tempMessageList.isNotEmpty) {
          List<Message> messageList = [];
          for (final m in tempMessageList) {
            if (messageSet.contains(m.id) ||
                m.isInvisibleMsg ||
                _isExistSentMessage(m)) continue;
            messageSet.add(m.id);
            messageList.add(m);
          }
          if (messageList.isEmpty) return;

          Message? preMsg;
          if (previousMessageList.isNotEmpty) {
            preMsg = previousMessageList.first;
          }
          if (nextMessageList.isNotEmpty) {
            preMsg = nextMessageList.last;
          }
          for (Message message in messageList) {
            if (preMsg != null) {
              int diffTime = message.send_time - preMsg.send_time;
              if (diffTime >= 120 * 1000 ||
                  preMsg.send_id != message.send_id ||
                  message.isSystemMsg) {
                message.isFirst = true;
                preMsg.isLast = true;
              } else {
                message.isFirst = false;
                preMsg.isLast = false;
              }
            }
            preMsg = message;
          }
          if (preMsg != null) {
            preMsg.isLast = true;
          }
          processDateByMessages(messageList, isPrevious: false);
          if (previousMessageList.length < prevMessageListThreshold) {
            previousMessageList.insertAll(0, messageList.reversed);
          } else {
            nextMessageList.addAll(messageList);
          }
        }
      });

      if (isSearching.value) {
        filterSearchedItem();
      }
      updateStartEndIndex();
    }
  }

  bool isEnd() {
    _updateEndIndex();
    return noMoreNext;
  }

  bool isFirst() {
    _updateStartIndex();
    return noMorePrevious;
  }

  onChatReload(sender, type, data) async {
    if (inputNotify.value.state != ChatInputState.noTyping) {
      inputNotify.value.state = ChatInputState.noTyping;
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
    } else {
      if (data['message'] != null) {
        bool isNeedRefresh = false;
        for (var item in data['message']) {
          int id = 0;
          int messageId = 0;
          if (item is Message) {
            id = item.id;
          } else {
            messageId = item;
          }
          int nextMessageIndex = -1;
          int previousMessageIndex = -1;

          nextMessageIndex = nextMessageList.indexWhere((message) {
            if (id != 0) {
              return message.id == id;
            } else {
              return message.message_id == messageId;
            }
          });
          previousMessageIndex = previousMessageList.indexWhere((message) {
            if (id != 0) {
              return message.id == id;
            } else {
              return message.message_id == messageId;
            }
          });

          if (nextMessageIndex != -1) {
            Message msg = nextMessageList[nextMessageIndex];
            if (msg.isBlackListOrStranger) {
              if (nextMessageList.length > nextMessageIndex + 1) {
                if (nextMessageList[nextMessageIndex + 1].typ ==
                        messageTypeInBlock ||
                    nextMessageList[nextMessageIndex + 1].typ ==
                        messageTypeNotFriend) {
                  nextMessageList.remove(nextMessageList[nextMessageIndex + 1]);
                }
              }
            }
            nextMessageList.remove(msg);
            if (nextMessageList.isEmpty &&
                previousMessageList.isNotEmpty &&
                unreadBarMsg != null &&
                previousMessageList.first == unreadBarMsg) {
              removeUnreadBar();
            }
            isNeedRefresh = true;
          } else if (previousMessageIndex != -1) {
            Message msg = previousMessageList[previousMessageIndex];
            if (msg.isBlackListOrStranger) {
              if (previousMessageList.length > previousMessageIndex + 1) {
                if (previousMessageList[previousMessageIndex + 1].typ ==
                        messageTypeInBlock ||
                    previousMessageList[previousMessageIndex + 1].typ ==
                        messageTypeNotFriend) {
                  previousMessageList
                      .remove(previousMessageList[previousMessageIndex + 1]);
                }
              }
            }
            previousMessageList.remove(msg);
            if (nextMessageList.isEmpty &&
                previousMessageList.isNotEmpty &&
                unreadBarMsg != null &&
                previousMessageList.first == unreadBarMsg) {
              removeUnreadBar();
            }
            isNeedRefresh = true;
          }
        }
        if (isNeedRefresh) {
          Message? preMsg;
          for (Message message in previousMessageList.reversed) {
            if (preMsg != null) {
              int diffTime = message.send_time - preMsg.send_time;
              if (diffTime >= 120 * 1000 ||
                  preMsg.send_id != message.send_id ||
                  message.isSystemMsg) {
                message.isFirst = true;
                preMsg.isLast = true;
              }
            }
            preMsg = message;
          }

          for (Message message in nextMessageList) {
            if (preMsg != null) {
              int diffTime = message.send_time - preMsg.send_time;
              if (diffTime >= 120 * 1000 ||
                  preMsg.send_id != message.send_id ||
                  message.isSystemMsg) {
                message.isFirst = true;
                preMsg.isLast = true;
              }
            }
            preMsg = message;
          }
          if (preMsg != null) {
            preMsg.isLast = true;
          }
          previousMessageList.refresh();
          nextMessageList.refresh();
        }
      }
    }
  }

  onChatMessageAutoDelete(sender, type, data) {
    if (data != null && data is Message) {
      if (chat.id == data.chat_id) {
        chooseMessage.removeWhere((key, value) => value.id == data.id);
        pinMessageList.removeWhere((element) => element.id == data.id);
        mentionChatIdxList.removeWhere((element) => element.id == data.id);
      }
    }
  }

  onUpdateUnread(sender, type, data) {
    if (data is Chat) {
      if (data.chat_id == chat.chat_id &&
          unreadCount.value != chat.unread_count) {
        unreadCount.value = chat.unread_count;

        if (fromNotificationTap &&
            unreadCount.value > 0 &&
            combinedMessageList.isNotEmpty) {
          scrollMessage(chat.msg_idx, combinedMessageList.first.id);
        }
      }
      _onUpdateMentionListChange(sender, type, data);
    }
  }

  onMessageComing(sender, type, data) async {
    if (data is! List<Message>) {
      return;
    }

    if (data.first.chat_id != chat.id || data.isEmpty) {
      return;
    }

    if (endMessage == null || showScrollBottomBtn.value == false) {
      int fromIdx =
          (endMessage?.chat_idx ?? max(chat.hide_chat_msg_idx, chat.start_idx));
      if (data.first.chat_idx < fromIdx) {
        fromIdx = data.first.chat_idx;
      }
      int count = chat.msg_idx - fromIdx;
      if (data.last.chat_idx > chat.msg_idx) {
        count = data.last.chat_idx - fromIdx;
      }
      if (count > 100) {
        count = 100;
      }
      List<Message> msgList = data;
      if (data.length < count) {
        msgList = await objectMgr.chatMgr.loadMessageList(
          chat,
          count: count,
          fromIdx: fromIdx + 1,
          forward: 1,
        );
      }

      for (final m in msgList) {
        _addMoreNewMessageFromLock(m);
      }
    }
  }

  void _addMoreNewMessageFromLock(Message message) async {
    await uiMessageListLock.synchronized(() async {
      if (messageSet.contains(message.id) || message.isInvisibleMsg) {
        return;
      }
      messageSet.add(message.id);
      _addMoreNewMessageFrom(message);
      if (!objectMgr.userMgr.isMe(message.send_id)) {
        checkIncomingTranslationMessage(message);
      }
    });
  }

  _addMoreNewMessageFrom(Message message) async {
    int nextIndex = -1;
    int previousIndex = -1;
    if (objectMgr.userMgr.isMe(message.send_id)) {
      nextIndex = nextMessageList.indexWhere((e) => e.cmid == message.cmid);
      previousIndex =
          previousMessageList.indexWhere((e) => e.cmid == message.cmid);
    }
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
      if (message.isMediaType) {
        if (message.typ == messageTypeNewAlbum) {
          await cacheMediaMgr.getMessageGausImage(message);
        } else {
          await Future.any([
            cacheMediaMgr.getMessageGausImage(message),
            Future.delayed(const Duration(milliseconds: 1000)),
          ]);
        }
      }

      Message? preMsg;
      if (previousMessageList.isNotEmpty) {
        preMsg = previousMessageList.first;
      }
      if (nextMessageList.isNotEmpty) {
        preMsg = nextMessageList.last;
      }
      if (preMsg != null && !message.isSystemMsg) {
        int diffTime = message.send_time - preMsg.send_time;
        if (diffTime >= 120 * 1000 || preMsg.send_id != message.send_id) {
          message.isFirst = true;
        } else {
          preMsg.isLast = false;
          if (previousMessageList.isNotEmpty &&
              previousMessageList.first == preMsg) {
            previousMessageList.refresh();
          }
        }
      }

      message.isLast = true;
      bool addDateMessage = endMessage != null
          ? (FormatTime.iSameDay(message.create_time, endMessage!.create_time)
              ? false
              : true)
          : true;
      if (previousMessageList.length < prevMessageListThreshold) {
        if (addDateMessage) {
          previousMessageList.insert(0, getDateMessage(message));
        }
        previousMessageList.insert(0, message);
      } else {
        if (addDateMessage) {
          nextMessageList.add(getDateMessage(message));
        }
        nextMessageList.add(message);
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
    updateStartEndIndex();

    if (!popupEnabled &&
        ((objectMgr.userMgr.isMe(message.send_id) &&
                message.typ != messageTypePin &&
                message.typ != messageTypeUnPin) ||
            showScrollBottomBtn.value == false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        messageListController?.animateTo(
          messageListController?.position.minScrollExtent ?? 0.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      });
    }

    if (!objectMgr.userMgr.isMe(message.send_id) && message.isChatRoomVisible) {
      unreadCount.value = chat.unread_count;
    }
  }

  void _replaceEditMessageFromLock(Message message) async {
    await uiMessageListLock.synchronized(() async {
      _replaceEditMessageFrom(message);
    });
  }

  _replaceEditMessageFrom(Message message) async {
    int nextIndex = -1;
    int previousIndex = -1;

    nextIndex = nextMessageList.indexWhere(
      (e) => e.send_id == message.send_id && e.send_time == message.send_time,
    );
    previousIndex = previousMessageList.indexWhere(
      (e) => e.send_id == message.send_id && e.send_time == message.send_time,
    );

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
    }

    _updateEndIndex();
    updateStartEndIndex();

    setDownButtonVisible(false);
    unreadCount.value = 0;

    if (!objectMgr.userMgr.isMe(message.send_id) && message.isChatRoomVisible) {
      unreadCount.value = chat.unread_count;
    }
  }

  onMessageSend(sender, type, data) async {
    await uiMessageListLock.synchronized(() async {
      if (messageSet.contains(data.id) || data.isInvisibleMsg) {
        return;
      }
      messageSet.add(data.id);
      onMessageSendLock(sender, type, data);
    });
  }

  onMessageSendLock(sender, type, data) async {
    if (data.message_id == 0) {
      if (data.chat_id != chat.chat_id || _isExistSentMessage(data)) {
        return;
      }
      if (unreadBarMsg != null) {
        removeUnreadBar();
      }

      if (showScrollBottomBtn.value == true) {
        int fromIdx = (endMessage?.chat_idx ??
            max(chat.hide_chat_msg_idx, chat.start_idx));
        if (data.chat_idx < fromIdx) {
          fromIdx = data.chat_idx;
        }
        int count = chat.msg_idx - fromIdx;
        if (data.chat_idx > chat.msg_idx) {
          count = data.chat_idx - fromIdx;
        }
        final msgList = await objectMgr.chatMgr.loadMessageList(
          chat,
          count: count + 10,
          fromIdx: fromIdx,
          forward: 1,
        );
        for (final m in msgList) {
          if (messageSet.contains(m.id)) continue;
          messageSet.add(m.id);
          _addMoreNewMessageFrom(m);
          if (!objectMgr.userMgr.isMe(m.send_id)) {
            checkIncomingTranslationMessage(m);
          }
        }
      }
      Message? preMsg;
      if (previousMessageList.isNotEmpty) {
        preMsg = previousMessageList.first;
      }
      if (nextMessageList.isNotEmpty) {
        preMsg = nextMessageList.last;
      }
      if (preMsg != null && !data.isSystemMsg) {
        int diffTime = data.send_time - preMsg.send_time;
        if (diffTime >= 120 * 1000 || preMsg.send_id != data.send_id) {
          data.isFirst = true;
        } else {
          preMsg.isLast = false;
        }
      }
      data.isLast = true;

      bool addDateMessage = !FormatTime.iSameDay(
          data.create_time, endMessage == null ? 0 : endMessage!.create_time);
      if (previousMessageList.length < prevMessageListThreshold) {
        if (addDateMessage) {
          previousMessageList.insert(0, getDateMessage(data));
        }
        previousMessageList.insert(0, data);
      } else {
        if (previousMessageList.isNotEmpty &&
            previousMessageList.first == preMsg) {
          previousMessageList.refresh();
        }
        if (addDateMessage) {
          nextMessageList.add(getDateMessage(data));
        }
        nextMessageList.add(data);
      }
      updateStartEndIndex();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        messageListController?.animateTo(
          messageListController?.position.minScrollExtent ?? 0.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      });
    }
  }

  void removeMessage(Message sendMessage) {
    bool nextCheck = true;
    for (int i = 0; i < previousMessageList.length; i++) {
      if (previousMessageList[i].id == sendMessage.id) {
        previousMessageList.removeAt(i);
        if (sendMessage.isBlackListOrStranger) {
          while (i < previousMessageList.length &&
              (previousMessageList[i].typ == messageTypeInBlock ||
                  previousMessageList[i].typ == messageTypeNotFriend)) {
            previousMessageList.removeAt(i);
          }
        }
        nextCheck = false;
        break;
      }
    }

    if (nextCheck) {
      for (int i = 0; i < nextMessageList.length; i++) {
        if (nextMessageList[i].id == sendMessage.id) {
          nextMessageList.removeAt(i);
          if (sendMessage.isBlackListOrStranger) {
            while (i < nextMessageList.length &&
                (nextMessageList[i].typ == messageTypeInBlock ||
                    nextMessageList[i].typ == messageTypeNotFriend)) {
              nextMessageList.removeAt(i);
            }
          }
          break;
        }
      }
    }

    updateStartEndIndex();
  }

  void removeUnreadBar() {
    int prevUnreadBarIndex =
        previousMessageList.indexWhere((m) => m.typ == messageTypeUnreadBar);
    if (prevUnreadBarIndex != -1) {
      previousMessageList.removeAt(prevUnreadBarIndex);
      unreadBarMsg = null;
    }
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
            .remove(data.message_id);
      }
    }
  }

  _onUpdateMentionListChange(Object sender, Object type, Object? data) async {
    if (data is Chat) {
      mentionChatIdxList
          .removeWhere((message) => message.chat_idx <= data.read_chat_msg_idx);
      if (objectMgr.chatMgr.mentionMessageMap[data.chat_id] != null) {
        objectMgr.chatMgr.mentionMessageMap[data.chat_id]!.removeWhere(
            (key, message) => message.chat_idx <= data.read_chat_msg_idx);
      }
    }
  }

  _onAddMentionListChange(Object sender, Object type, Object? data) async {
    if (data is Message && data.chat_id == chat.id) {
      bool find = false;
      for (var element in mentionChatIdxList) {
        if (element.chat_idx == data.chat_idx) {
          find = true;
          continue;
        }
      }
      if (find) {
        return;
      }
      if (data.isMentionMessage(objectMgr.userMgr.mainUser.uid)) {
        mentionChatIdxList.add(data);
      }
    }
  }

  void onCancelFocus() {
    // prevent android check permission will dismiss everything
    if (isAskingPermission) return;
    removeShortcutImage();
    CustomInputController? inputController;
    if (Get.isRegistered<CustomInputController>(tag: chat.id.toString())) {
      inputController =
          Get.find<CustomInputController>(tag: chat.id.toString());
    }

    if (inputController != null) {
      inputController.inputState = 0;
      showMentionList.value = false;
      inputController.inputFocusNode.unfocus();
      inputController.update();
      showAttachmentView.value = false;
    }

    if (isSearching.value) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    pdebug(
      "onCancelFocus=========> ${FocusManager.instance.primaryFocus?.hasFocus} | ${inputController?.inputFocusNode.hasFocus}",
    );
    if (Platform.isIOS &&
        (FocusManager.instance.primaryFocus?.hasFocus ?? false)) {}

    showFaceView.value = false;
  }

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
      message.message_id == 0 ? message.send_time : message.message_id,
    )) {
      removeChooseMessage(
        message.message_id == 0 ? message.send_time : message.message_id,
      );
    } else {
      // 红包、转账、通话、失败、发送中，下面的 删除和举报 不进入多选
      if (!message.isDisableMultiSelect) {
        addChooseMessage(message, objectMgr.userMgr.mainUser);
      }
    }

    bool forward = true;
    int messageCannotForwardCounter = 0;
    int messageCannotDeleteCounter = 0;
    bool canAddToFav = true;
    chooseMessage.forEach((key, value) {
      if (!checkAddToFavourite(value) || value.isEncrypted) {
        canAddToFav = false;
      }

      if (!checkChatPermission(value) ||
          value.sendState == MESSAGE_SEND_ING ||
          value.sendState != MESSAGE_SEND_SUCCESS ||
          value.typ == messageTypeSendRed ||
          value.typ == messageTypeTransferMoneySuccess ||
          value.typ == messageTypeNote ||
          value.typ == messageTypeChatHistory ||
          value.typ == messageBusyCall ||
          value.typ == messageCancelCall ||
          value.typ == messageMissedCall ||
          value.typ == messageEndCall ||
          value.typ == messageRejectCall ||
          value.isEncrypted) {
        forward = false;
        messageCannotForwardCounter++;
        if (value.sendState == MESSAGE_SEND_ING) {
          messageCannotDeleteCounter++;
        }
      }
    });

    canDelete.value = messageCannotDeleteCounter == 0;

    if (chat.typ != chatTypeSaved && chat.isSpecialChat) {
      forward = false;
    }

    canForward.value = forward &&
        GroupPermissionMap.groupPermissionForwardMessages
            .isAllow(permission.value) &&
        messageCannotForwardCounter == 0;

    isEnableFavourite.value = canAddToFav;
  }

  void onChooseMoreCancel() {
    chooseMessage.clear();
    chooseMore.value = false;
    isEnableFavourite.value = true;
  }

  void onClearChooseMessage() {
    chooseMessage.clear();
  }

  bool checkAddToFavourite(Message message) {
    if (message.isSendOk) {
      switch (message.typ) {
        case messageTypeTransferMoneySuccess:
        case messageEndCall:
        case messageRejectCall:
        case messageCancelCall:
        case messageMissedCall:
        case messageBusyCall:
        case messageTypeEdit:
        case messageTypeFace:
        case messageTypeGif:
        case messageTypeRecommendFriend:
        case messageTypeSendRed:
        case messageTypeGroupLink:
        case messageTypeMarkdown:
        case messageTypeNote:
        case messageTypeChatHistory:
          return false;
        default:
          return true;
      }
    } else {
      return false;
    }
  }

  /// 进入详情页
  /// 单聊 -> id 为 对方 friend_id
  /// 群聊 -> id 为 群聊 chat_id
  Future<void> onEnterChatInfo(bool isSingle, Chat chat, int id,
      {bool isSpecialChat = false}) async {
    // playerService.stopPlayer();
    // playerService.resetPlayer();
    removeShortcutImage();
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
          final argument = {};
          if (id != 0) {
            argument['uid'] = user.uid;
          } else {
            if (objectMgr.loginMgr.isDesktop) argument['uid'] = 0;
            argument['chat'] = chat;
          }
          Get.toNamed(
            RouteName.chatInfo,
            arguments: argument,
            id: objectMgr.loginMgr.isDesktop ? 1 : null,
          )!
              .whenComplete(() => FocusNode().requestFocus());
        }
      } else {
        Get.toNamed(
          RouteName.groupChatInfo,
          arguments: {'groupId': chat.id},
          id: objectMgr.loginMgr.isDesktop ? 1 : null,
        )!
            .whenComplete(() => FocusNode().requestFocus());
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

  Future<void> searchMessageFromColdTable(String content, int chatId) async {
    List<String> tables = await objectMgr.localDB.getColdMessageTables(0, 0);
    for (int i = 0; i < tables.length; i++) {
      List<Message> messages = [];
      List<Map<String, dynamic>> rows = await objectMgr.localDB
          .searchMessage(content, tbname: tables[i], chat_id: chat.id);
      List<Message> messagesList = rows.map((e) => Message()..init(e)).toList();
      messages = objectMgr.chatMgr.searchMessageFromRows(content, messagesList);
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
      showMessageOnScreen(
        searchedIndexList.first.chat_idx,
        searchedIndexList.first.id,
        searchedIndexList.first.create_time,
      );
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

      await searchMessageFromColdTable(searchParam.value, chat.chat_id);
    });
  }

  void showMessageOnScreen(
    int chatIdx,
    int id,
    int createTime, {
    bool shouldDisappear = true,
    bool isMustFind = true,
  }) async {
    if (scrollMessage(chatIdx, id, shouldDisappear: shouldDisappear)) {
      return;
    }
    int endIdx = (endMessage != null) ? endMessage!.chat_idx : 0;
    int startIdx = (startMessage != null) ? startMessage!.chat_idx : 0;
    if (isMustFind && chatIdx >= startIdx && chatIdx <= endIdx) {
      imBottomToast(
        context,
        title: localized(unableToFindMessage),
      );
      return;
    }
    List<Message> messageList = await objectMgr.chatMgr.loadMessageList(
      chat,
      fromIdx: chatIdx,
      extra: 0,
      count: messagePageCount,
      fromTime: createTime,
    );
    bool isContinue = true;
    if (isMustFind) {
      var index = -1;
      if (id == 0) {
        index =
            messageList.indexWhere((element) => element.chat_idx == chatIdx);
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
      if (!noMoreNext) {
        await loadNextMessages(messageCount: messagePageCount);
      }
      scrollMessage(chatIdx, id, shouldDisappear: shouldDisappear);
      return;
    }
    imBottomToast(
      context,
      title: localized(unableToFindMessage),
      icon: ImBottomNotifType.warning,
    );
  }

  void locateToSpecificPosition(List<int> indexList) =>
      showMessageOnScreen(indexList.first, 0, 0);

  void previousSearch() {
    if (listIndex.value == 0) return;
    listIndex -= 1;
    Message? msg = searchedIndexList[listIndex.value];
    if (msg == null) return;
    showMessageOnScreen(msg.chat_idx, msg.id, msg.create_time);
  }

  void nextSearch() {
    if (listIndex.value == searchedIndexList.length - 1) return;
    listIndex += 1;
    Message? msg = searchedIndexList[listIndex.value];
    if (msg == null) return;
    showMessageOnScreen(msg.chat_idx, msg.id, msg.create_time);
  }

  void clearSearching() {
    isSearching(false);
    searchController.clear();
    searchParam.value = '';
    isListModeSearch.value = false;
    getIndexList();
  }

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
          .where(
            (element) => objectMgr.userMgr
                .getUserTitle(element)
                .toLowerCase()
                .contains(searchContactParam.toLowerCase()),
          )
          .toList();
    } else {
      friendList.value = objectMgr.userMgr.filterFriends;
    }
  }

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
    objectMgr.stickerMgr.onChatPopMenuCloseEvent(popupEnabled);
    Future.delayed(const Duration(milliseconds: 300), () {
      chatPopEntry?.remove();
      chatPopEntry = null;
    });
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
      if (!isSendTextVoice) {
        if (isSendTextStickerEmoji &&
            (isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 1;
        } else if (isSendTextStickerEmoji &&
            !(isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 3;
        } else if (isSendMedia ||
            isSendDocument ||
            isSendContacts ||
            isSendRedPacket) {
          inputType.value = 2;
        } else {
          inputType.value = 4;
        }
      } else {
        if (!isSendTextStickerEmoji &&
            (isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 5;
        } else if (isSendTextStickerEmoji &&
            !(isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 6;
        } else if (isSendTextStickerEmoji &&
            (isSendMedia ||
                isSendDocument ||
                isSendContacts ||
                isSendRedPacket)) {
          inputType.value = 0;
        } else {
          inputType.value = 7;
        }
      }
    } else {
      inputType.value = 0;
    }
  }

  Future<void> checkPasscodeStatus() async {
    bool? passwordStatus =
        objectMgr.localStorageMgr.read(LocalStorageMgr.SET_PASSWORD);
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
    final Offset offset = details.localPosition;
    RenderBox dropAreaBox =
        ((upperDropAreaKey.currentContext ?? lowerDropAreaKey.currentContext)
            ?.findRenderObject() as RenderBox);

    final dropAreaHeight = dropAreaBox.size.height;
    final dropAreaWidth = dropAreaBox.size.width;

    Rect upperDropArea = Rect.fromLTWH(30, 15, dropAreaWidth, dropAreaHeight);
    Rect lowerDropArea =
        Rect.fromLTWH(30, 30 + dropAreaHeight, dropAreaWidth, dropAreaHeight);

    if (upperDropArea.contains(offset)) {
      if (allImage || allVideo) {
        ChatHelp.desktopSendFile(details.files, chat.id, '', null);
      }
    }

    if (lowerDropArea.contains(offset)) {
      if (allImage || allVideo) {
        captionController.text = '';
        captionController.clear();
        desktopGeneralDialog(
          context,
          color: colorTextPlaceholder,
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
    messageListController?.dispose();
    messageListController = null;
    _shortcutDismissTimer?.cancel();
    audiosToPlay.checkChatControllerOnClose(this);

    CustomTextEditingController.mentionRange.clear();

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
      objectMgr.chatMgr.chatMessageMap[chat.id]!.removeWhere(
        (key, value) => value.message_id != 0,
      );
    }
    objectMgr.chatMgr.off(ChatMgr.eventUpdateUnread, onUpdateUnread);
    objectMgr.chatMgr.off(ChatMgr.eventMessageListComing, onMessageComing);
    objectMgr.chatMgr.off(ChatMgr.eventMessageSend, onMessageSend);
    objectMgr.chatMgr.off(ChatMgr.eventChatReload, onChatReload);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, onChatMessageAutoDelete);
    objectMgr.chatMgr
        .off(ChatMgr.eventAddMentionChange, _onAddMentionListChange);
    objectMgr.chatMgr
        .off(ChatMgr.eventDelMentionChange, _onDelMentionListChange);
    objectMgr.chatMgr.off(ChatMgr.eventSetPassword, _onSetPassword);
    objectMgr.chatMgr.off(ChatMgr.cancelKeyboardEvent, _cancelKeyBoardEvent);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, _onEditMessage);
    objectMgr.chatMgr.off(ChatMgr.eventDecryptChat, _onDecryptChat);
    objectMgr.chatMgr.off(ChatMgr.messageStopAllReading, _messageStopReading);
    if (chat.isTmpGroup) {
      objectMgr.myGroupMgr
          .off(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);
    }

    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void _onDecryptChat(Object sender, Object type, Object? data) {
    if (data is! List<Chat>) {
      return;
    }
    var filteredChat =
        data.firstWhereOrNull((element) => element.chat_id == chat.chat_id);
    if (filteredChat == null) return;
    if (!filteredChat.isActiveChatKeyValid) return;

    try {
      for (var message in previousMessageList) {
        if (message.isEncrypted) {
          MessageMgr.decodeMsg(
              message, filteredChat, objectMgr.userMgr.mainUser.uid);
        }
      }

      for (var message in nextMessageList) {
        if (message.isEncrypted) {
          MessageMgr.decodeMsg(
              message, filteredChat, objectMgr.userMgr.mainUser.uid);
        }
      }
    } catch (e) {
      pdebug("_onDecryptChat message base controller decrypt err: $e");
    }

    previousMessageList.refresh();
    nextMessageList.refresh();
  }

  void _messageStopReading(_, __, ___) {
    isReadingText = false;
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

  void translateMessage(Message message) async {
    resetPopupWindow();
    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      return;
    }
    String locale = chat.currentLocaleIncoming;
    int visualType = chat.visualTypeIncoming;
    bool isMe = objectMgr.userMgr.isMe(message.send_id);
    if (isMe) {
      locale = chat.currentLocaleOutgoing;
      visualType = chat.visualTypeOutgoing;
      if (chat.outgoing_idx == 0) {
        chat.outgoing_idx = chat.msg_idx;
        objectMgr.chatMgr.saveTranslationToChat(chat);
      }
    } else {
      if (chat.incoming_idx == 0) {
        chat.incoming_idx = chat.msg_idx;
        objectMgr.chatMgr.saveTranslationToChat(chat);
      }
    }
    await objectMgr.chatMgr.getMessageTranslation(
      message.messageContent,
      locale: locale == 'auto' ? getAutoLocale(chat: chat, isMe: isMe) : locale,
      message: message,
      visualType: visualType,
    );

    bool isNeedScroll = isNeedScrollToBottom(message);
    if (isNeedScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (Platform.isIOS) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        messageListController?.animateTo(
          messageListController?.position.minScrollExtent ?? 0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      });
    }
  }

  void convertTextToVoice(Message message, {bool isTranslation = false}) async {
    resetPopupWindow();
    objectMgr.chatMgr
        .event(objectMgr.chatMgr, ChatMgr.messageWaitingRead, data: message);
    isReadingText = true;
    String content = message.messageContent;
    String locale = '';
    TranslationModel? model = message.getTranslationModel();

    if (model != null && model.showTranslation) {
      if (model.visualType == TranslationModel.showTranslationOnly ||
          isTranslation) {
        content = model.getContent();
        locale = model.currentLocale;
      }
    }
    final VolumePlayerService playerService =
        VolumePlayerService.sharedInstance;
    await playerService.stopPlayer();
    playerService.resetPlayer();
    if (playerService.playbackKey != '') {
      playerService.removePlaybackDuration(playerService.playbackKey);
    }
    content = ChatHelp.formalizeMentionContent(content, message);

    File? voiceFile =
        await objectMgr.chatMgr.getTextToVoice(content, locale, message);
    if (voiceFile != null) {
      bool isDesktop = objectMgr.loginMgr.isDesktop;
      String playbackKey = '${message.message_id}_${voiceFile.path}';
      late DesktopAudioPlayer desktopAudioPlayer;
      if (isDesktop) {
        desktopAudioPlayer = DesktopAudioPlayer.create(
          messageId: message.message_id,
          chat: chat,
        );
      }
      playerService.currentPlayingFileName = playbackKey;
      playerService.currentMessage = message;
      playerService.currentPlayingFile = voiceFile.path;
      if (playerService.getPlaybackDuration('${message.message_id}_null') >
          0.0) {
        playerService.setPlaybackDuration(
          playbackKey,
          playerService.getPlaybackDuration('${message.message_id}_null'),
        );
        playerService.removePlaybackDuration('${message.message_id}_null');
      }
      objectMgr.chatMgr
          .event(objectMgr.chatMgr, ChatMgr.messagePlayingSound, data: message);
      isReadingText = true;
      if (isDesktop) {
        await desktopAudioPlayer.openPlayer(
          durationChanged: () {},
          onPlayerCompleted: () {
            objectMgr.chatMgr.event(
              objectMgr.chatMgr,
              ChatMgr.messageStopSound,
              data: message,
            );
          },
          onPlayerStateChanged: (state) {},
          filePath: voiceFile.path,
        );
      } else {
        await playerService.openPlayer(
          onFinish: () {
            objectMgr.chatMgr.event(
              objectMgr.chatMgr,
              ChatMgr.messageStopSound,
              data: message,
            );
            playerService.removePlaybackDuration(playbackKey);
          },
          onProgress: (_) {
            isAudioPinPlaying.value = true;
            playerService.playbackKey = playbackKey;
          },
        );
      }
    } else {
      isShowAudioPin.value = false;
      objectMgr.chatMgr
          .event(objectMgr.chatMgr, ChatMgr.messageWaitingRead, data: message);
      if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
        Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      } else {
        Toast.showToast(localized(unableToReadMsg));
      }
    }
  }

  showOriginalMessage(Message message) {
    resetPopupWindow();
    Message newMsg = message.hideTranslation();
    objectMgr.chatMgr.saveNewMessageContent(newMsg, "eventMessageTranslate");
  }

  checkIncomingTranslationMessage(Message message) async {
    if (message.isTranslatableType) {
      TranslationModel? model = message.getTranslationModel();
      if (model != null) {
        model.visualType = chat.visualTypeIncoming;

        if (chat.isAutoTranslateIncoming) {
          model.currentLocale = chat.currentLocaleIncoming;
        }

        if (!notBlank(model.getContent())) {
          String content = message.messageContent;
          if (!EmojiParser.hasOnlyEmojis(content)) {
            await objectMgr.chatMgr.getMessageTranslation(
              content,
              locale: model.currentLocale == 'auto'
                  ? getAutoLocale(chat: chat, isMe: false)
                  : model.currentLocale,
              message: message,
              visualType: model.visualType,
            );
          }
        } else {
          Message newMsg = message.addTranslation(
            model.currentLocale,
            model.translation[model.currentLocale] ?? "",
            model.visualType,
          );
          objectMgr.chatMgr
              .saveNewMessageContent(newMsg, "eventMessageTranslate");
        }
      } else {
        if (chat.isAutoTranslateIncoming) {
          if (message.typ == messageTypeVoice) {
            transcribe(message);
          } else {
            model = TranslationModel();
            model.visualType = chat.visualTypeIncoming;
            model.currentLocale = chat.currentLocaleIncoming;
            model.showTranslation = true;
            String content = message.messageContent;
            if (!EmojiParser.hasOnlyEmojis(content)) {
              await objectMgr.chatMgr.getMessageTranslation(
                content,
                locale: model.currentLocale == 'auto'
                    ? getAutoLocale(chat: chat, isMe: false)
                    : model.currentLocale,
                message: message,
                visualType: model.visualType,
              );
            }
          }
        }
      }
      bool isNeedScroll = isNeedScrollToBottom(message);
      if (isNeedScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (Platform.isIOS) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          messageListController?.animateTo(
            messageListController?.position.minScrollExtent ?? 0.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        });
      }
    }
  }

  Future<void> transcribe(Message message) async {
    resetPopupWindow();

    MessageVoice messageVoice = message.decodeContent(cl: MessageVoice.creator);
    String mediaPath = messageVoice.url;
    if (notBlank(mediaPath)) {
      sendConvertTextEvent(message, "", true);

      try {
        final TranscribeModel data =
            await getTranscribeText("en,zh,jp", mediaPath);
        if (data.transText != null && data.transText != "") {
          Message newMsg = message.addTranscribe(data.transText!);
          await objectMgr.chatMgr
              .saveNewMessageContent(newMsg, "eventUpdateTranscribe");
          _processTranscribeTranslate(newMsg);
        }
        sendConvertTextEvent(message, data.transText ?? "", false);
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
        sendConvertTextEvent(message, "", false);
      }
    }
  }

  hideTranscribe(Message msg) {
    resetPopupWindow();
    Message newMsg = msg.removeTranscribe();
    objectMgr.chatMgr.saveNewMessageContent(newMsg, "eventUpdateTranscribe");
  }

  _processTranscribeTranslate(Message msg) {
    if (objectMgr.userMgr.isMe(msg.send_id)) {
      if (chat.isAutoTranslateOutgoing) {
        translateMessage(msg);
      }
    } else {
      if (chat.isAutoTranslateIncoming) {
        translateMessage(msg);
      }
    }
  }

  void sendConvertTextEvent(
    Message message,
    String convertText,
    bool isConverting,
  ) {
    EventTranscribeModel eventData = EventTranscribeModel(
      messageId: message.id,
      text: convertText,
      isConverting: isConverting,
    );
    message.event(Message, Message.eventConvertText, data: eventData);
  }

  void openReadMoreTextEvent(Message message) {
    ReadMoreModel eventData = ReadMoreModel(
      messageId: message.message_id,
      isReadMore: false,
    );
    message.event(Message, Message.eventReadMoreText, data: eventData);
  }

  void showFriendRequestSheet() {
    resetPopupWindow();
    User? user = objectMgr.userMgr.getUserById(chat.friend_id);
    if (user != null) {
      showModalBottomSheet(
        context: context,
        barrierColor: colorOverlay40,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: FriendRequestConfirm(
              user: user,
              confirmCallback: (remark) {
                objectMgr.userMgr.addFriend(user, remark: remark);
              },
              cancelCallback: () => Navigator.of(context).pop(),
            ),
          );
        },
      );
    }
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

  bool isNeedScrollToBottom(Message message) {
    bool isNeedScroll = false;
    List<Message> list = nextMessageList.reversed.toList();
    for (int index = 0; index < list.length; index++) {
      Message m = list[index];
      if (m.message_id == message.message_id) {
        if (index == 0) {
          return true;
        }
      }
    }
    return isNeedScroll;
  }

  emojiReactLastMessageScrollToBottom(Message message) {
    bool isNeedScroll = isNeedScrollToBottom(message);
    if (isNeedScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        messageListController?.animateTo(
          messageListController?.position.minScrollExtent ?? 0.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      });
    }
  }

  void _onReactEmojiUpdate(Object sender, Object type, Object? data) {
    if (data is Message) {
      emojiReactLastMessageScrollToBottom(data);
    }
  }

  void _onEditMessage(sender, type, data) {
    if (data['id'] != chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      initPinMessages();
      if (data['message'] is Message) {
        if (!objectMgr.userMgr.isMe(data['message'].send_id)) {
          checkIncomingTranslationMessage(data['message']);
        }
      }
      _replaceEditMessageFromLock(data['message']);
    }
  }

  void _onGroupIsExpired(_, __, Object? data) {
    if (data != null && data is Map<String, dynamic> && data['id'] == chat.id) {
      if (data['isExpiring']) {
        startExpireCountDownTimer(data['timestamp']);
      } else {
        remainingTime.value = '';
        expireCountDownTimer?.cancel();
        expireCountDownTimer = null;
        isGroupExpireSoon.value = false;
      }
    }
  }

  startExpireCountDownTimer(int timestamp) {
    if (expireCountDownTimer != null) return;
    expireCountDownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      DateTime targetTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
      Duration leftTime = targetTime.difference(DateTime.now());
      if (leftTime.isNegative) {
        remainingTime.value = '00:00:00';
        expireCountDownTimer!.cancel();
        expireCountDownTimer = null;
        Group? group = objectMgr.myGroupMgr.getGroupById(chat.id);
        if (group != null) {
          objectMgr.chatMgr.clearMessages(group.uid);
          var chat = objectMgr.chatMgr.getChatById(group.uid);
          if (chat != null) {
            objectMgr.chatMgr.chatGroupDeleteProcess(chat);
          }
          Get.back();
        }
      } else {
        remainingTime.value = countDownDuration(leftTime);
      }
      isGroupExpireSoon.value = true;
    });
  }

  onTapExpiringBar() {
    Group? group = objectMgr.myGroupMgr.getGroupById(chat.id);
    Get.toNamed(
      RouteName.groupChatEdit,
      arguments: {
        'group': group,
        'groupId': chat.id,
        'permission': group?.permission,
        'highlightExpiring': true,
      },
    );
  }

  Future<void> onSelectUser(User user) async {
    isListModeSearch.value = false;
    isTextTypeSearch.value = true;
    List<String> tables = await objectMgr.localDB.getColdMessageTables(0, 0);
    searchController.text = '${localized(chatFrom)}: @${user.nickname}';
    for (int i = 0; i < tables.length; i++) {
      List<Message> messages = [];
      List<Map<String, dynamic>> rows = await objectMgr.localDB
          .searchUserMessage(user.id, tbname: tables[i], chat_id: chat.id);
      messages = objectMgr.chatMgr.searchGroupUserMessageFromRows(user, rows);
      messages.sort((a, b) => b.create_time - a.create_time);
      searchedIndexList.addAll(messages);
      messages.clear();
    }
  }

  positioningMessage(Message message, int index) {
    isListModeSearch.value = false;
    isTextTypeSearch.value = true;

    listIndex.value = index;
    Message? msg = searchedIndexList[listIndex.value];
    if (msg == null) return;
    showMessageOnScreen(msg.chat_idx, msg.id, msg.create_time);
  }

  Future<void> onDoubleTap({
    required Message message,
    required String text,
  }) async {
    Get.toNamed(
      RouteName.textSelectablePage,
      arguments: {
        'text': text,
        'chat': chat,
        "message": message,
      },
    );
  }

  fetchRecentAssets() async {
    if (isFetching) return;
    bool havePermission = false;
    isAskingPermission = true;
    try {
      havePermission = await checkPhotoPermission();
    } catch (e) {
      isAskingPermission = false;
    }
    Future.delayed(
        const Duration(milliseconds: 100), () => isAskingPermission = false);
    if (!havePermission) return;
    isFetching = true;

    final DateTime thirtySeconds =
        DateTime.now().subtract(const Duration(seconds: 30));

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );

    if (albums.isNotEmpty) {
      final List<AssetEntity> photos =
          await albums[0].getAssetListPaged(page: 0, size: 1);

      final recentPhotoEntity = photos.firstWhereOrNull((photo) {
        return photo.createDateTime.isAfter(thirtySeconds);
      });

      if (recentPhotoEntity != null &&
          (objectMgr.chatMgr.lastCheckedTime == null ||
              recentPhotoEntity.createDateTime
                  .isAfter(objectMgr.chatMgr.lastCheckedTime!))) {
        showShortcutImage.value = true;
        showShortcutAnimation.value = true;
        recentPhoto.value = recentPhotoEntity;
        objectMgr.chatMgr.lastCheckedTime = DateTime.now();
        startShortcutTimer();
      }
    }

    isFetching = false;
  }

  removeShortcutImage() {
    _shortcutDismissTimer?.cancel();
    showShortcutAnimation.value = false;
  }

  void startShortcutTimer() {
    _shortcutDismissTimer?.cancel();
    _remainingTime = 10; // Reset time

    _shortcutDismissTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
      } else {
        timer.cancel();
        removeShortcutImage();
      }
    });
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
      if (scStatus.value == SpecialContainerStatus.min.index) {
        return keyboardHeight.value - kSheetHeightMin;
      } else {
        return keyboardHeight.value;
      }
    }
    double kHeight = 0.0;
    if (Platform.isIOS) {
      kHeight = 336.w;
    } else {
      kHeight = 240.w;
    }
    if (scStatus.value == SpecialContainerStatus.min.index) {
      return kHeight - kSheetHeightMin;
    } else {
      return kHeight;
    }
  }
  if (scStatus.value == SpecialContainerStatus.min.index) {
    return keyboardHeight.value - kSheetHeightMin;
  } else {
    return keyboardHeight.value;
  }
}

double get getPanelFixHeight {
  double kHeight = 0.0;
  if (Platform.isIOS) {
    var sWidth = 1.sw;
    var sHeight = 1.sh;
    if (sWidth == 430 && sHeight == 932) {
      kHeight = 346;
    } else if (sWidth == 375 && sHeight == 667) {
      kHeight = 260;
    } else {
      kHeight = 336;
    }
  } else {
    kHeight = 294;
  }
  if (scStatus.value == SpecialContainerStatus.min.index) {
    return kHeight - kSheetHeightMin;
  } else {
    return kHeight;
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

mixin BaseChatControllerMixin {
  RxBool isListModeSearch = false.obs;

  RxBool isTextTypeSearch = true.obs;

  RxList<User> groupMemberList = RxList<User>();

  RxList<User> groupAllMemberList = RxList<User>();

  Future<void> onRefresh() async {}

  void switchChatSearchType({
    required bool isTextModeSearch,
    required bool isSingleChat,
    required Chat chat,
    String? searchParam,
  }) {
    isTextTypeSearch.value = false;
    String param = '${localized(chatFrom)}:';
    String str = "$param @";
    if (searchParam != null && searchParam.trim() != str) {
      String param = '${localized(chatFrom)}:';

      String str = searchParam.replaceAll(param, '').toLowerCase().trim();

      if (groupAllMemberList.isEmpty) {
        getAllGroupUsers(chat);
      }
      groupMemberList.clear();
      for (var element in groupAllMemberList) {
        String nickname = element.nickname.toLowerCase();
        if (nickname.contains(str)) {
          groupMemberList.add(element);
        }
      }

      if (groupMemberList.isEmpty && str.isNotEmpty) {
        groupMemberList.add(objectMgr.userMgr.mainUser);
      }
    } else {
      groupMemberList.clear();

      if (!isTextModeSearch) {
        if (!isSingleChat) {
          getAllGroupUsers(chat);
          groupMemberList.addAll(groupAllMemberList);
        }
      }
    }
  }

  void getAllGroupUsers(Chat chat) {
    groupAllMemberList.clear();
    Group? group = objectMgr.myGroupMgr.getGroupById(chat.id);
    if (group != null) {
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
      sortUsers(tempUserList);
      groupAllMemberList.addAll(tempUserList);
    }
  }
}
