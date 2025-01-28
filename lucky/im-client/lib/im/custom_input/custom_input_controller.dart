import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_session/audio_session.dart' as audioSession;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/component/media_selector_view.dart';
import 'package:jxim_client/im/custom_input/component/voice_record_button.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/task/task_selector_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/audio_recording_model/volume_model.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/audio_services/volume_record_service.dart';
import 'package:jxim_client/im/services/custom_text_editing_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/draft_model.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/fileUtils.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views/message/chat/widget/extent_my_text_selection_controls.dart';
import 'package:jxim_client/views_desktop/component/attach_file_dialog.dart';
import 'package:microphone_in_use/microphone_in_use.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as pp;
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:soundpool/soundpool.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:jxim_client/im/custom_input/game_custom_input_controller.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/net/aws_s3/file_uploader.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';

const String emptyNoSeeStr = "\u200B";

class CustomInputController extends GameCustomInputController {
  bool isGettingFile = false;
  final ScrollController scrollController = ScrollController();
  ///鍵盤切換的動畫控制
  late AnimationController inputAnimateController;
  late Animation<Offset> offset;

  /// 父层级 控制器
  late BaseChatController chatController;


  FocusNode inputFocusNode = FocusNode();
  ExtentMyTextSelectionControls? txtSelectControl;

  TextEditingController mediaPickerInputController = TextEditingController();

  /// 拷贝字
  String oldText = '';

  /// 输入状态 0.正常状态 1.输入状态 2.点击状态
  int inputState = 0;

  /// 输入状态 : 是否正在输入中
  bool internalInputState = false;

  /// "@" 用户列表
  RxList<MentionModel> mentionList = <MentionModel>[].obs;

  /// 自動刪除訊息的時間間格
  RxInt autoDeleteInterval = RxInt(0);

  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;
  RxList<AssetEntity> selectedAssetList = <AssetEntity>[].obs;
  RxList<File> fileList = <File>[].obs;

  /// 录音数据
  final VolumePlayerService playerService = VolumePlayerService.sharedInstance;

  // 限制录音时间
  int nowTime = 0;
  int endTime = 0;
  int limitTime = 0;
  bool onTapRelease = false;

  // 录制状态
  RxBool isRecording = RxBool(false);

  // 录制锁
  RxBool isLocked = RxBool(false);

  // 选项移动选择
  RxBool isLockedSelected = RxBool(false);
  RxBool isDeleteSelected = RxBool(false);

  OverlayEntry? recorderOverlayEntry;

  /// 用来区分是取消还是onPanEnd 手势
  bool isRecordingCancel = false;
  RxBool recordingIsPlaying = RxBool(false);

  XFile? circleVideo;
  int circleVideoLength = 0;

  Offset dragOffset = const Offset(0.0, 0.0);

  bool isVideoRecording = false;

  ///单聊制定的用户
  Rxn<User> user = Rxn<User>();

  final isDesktop = objectMgr.loginMgr.isDesktop;
  final isMobile = objectMgr.loginMgr.isMobile;
  bool isKeyPressed = false;

  final stickerDebounce = Debounce(const Duration(milliseconds: 600));
  final inputDebounce = Debounce(const Duration(milliseconds: 5000));

  Soundpool? _pool;
  SoundpoolOptions _soundPoolOptions = const SoundpoolOptions(
      streamType: StreamType.notification,
      maxStreams: 3,
      iosOptions: SoundpoolOptionsIos(
          audioSessionCategory: AudioSessionCategory.playAndRecord));
  int? sendMessageBubbleId;

  Chat? chat;

  CustomInputController();

  CustomInputController.desktop(Chat chat) {
    this.chat = chat;
  }

  /// 检测截图
  ScreenshotCallback? screenshotCallback;
  bool isScreenshotEnabled = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    initState();
    objectMgr.chatMgr
        .on(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.callMgr.on(CallMgr.eventIncomingCall, _onIncomingCall);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    if (isMobile) {
      final Map<String, dynamic> arguments = Get.arguments;
      if (arguments['chat'] != null) {
        chat = arguments['chat'];
      }
    }

    if (chat != null) {
      if (Get.isRegistered<SingleChatController>(tag: chat?.id.toString())) {
        chatController =
            Get.find<SingleChatController>(tag: chat?.id.toString());
        super.type = chatController.chat.typ == chatTypeSmallSecretary ? 4 : 1;
      } else {
        chatController =
            Get.find<GroupChatController>(tag: chat?.id.toString());
        super.type = 2;
      }
    }
    inputController = CustomTextEditingController(
      atList: mentionList,
    );

    txtSelectControl = ExtentMyTextSelectionControls();
    txtSelectControl?.handleNewline = () {
      objectMgr.sysOprateMgr.hideInputPop();
      // onNewLine();
    };
    txtSelectControl?.handlerPasteSend = (v) {
      // Toast.showAlert(
      //     context: Routes.navigatorKey.currentContext!,
      //     container: CustomChatImage(image: v, onSure: onSendPasteImg));
    };

    sendState.value = notBlank(objectMgr.chatMgr.selectedMessageMap[chat!.id]);

    chatId = chatController.chat.chat_id == 0
        ? chatController.chat.id
        : chatController.chat.chat_id;

    /// 获取输入草稿
    DraftModel? _draftModel =
        objectMgr.chatMgr.getChatDraft(chatController.chat.chat_id);

    /// 预输入草稿内容
    if (_draftModel != null && _draftModel.input.isNotEmpty) {
      inputController.text = _draftModel.input;
      sendState.value = true;
    }

    /// 监听焦点变化
    inputFocusNode.addListener(() {
      if (!inputFocusNode.hasFocus) {
        internalInputState = false;
        final targetId =
            chatController.chat.isGroup ? 0 : chatController.chat.friend_id;
        objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
        chatController.mainListFocusNode.requestFocus();
      }

      if (inputFocusNode.hasFocus) {
        if (chatController.showFaceView.value) {
          chatController.showFaceView.value = false;
        }
        if (chatController.showAttachmentView.value) {
          chatController.showAttachmentView.value = false;
        }
        KeyBoardObserver.instance.keyboardHeightNow = 0.0;
      }
    });

    /// 监听输入变化
    inputController.addListener(() {
      if (inputController.text.length >= 4096) {
        Toast.showToast(localized(errorMaxCharInput));
      }
      if (inputFocusNode.hasFocus) {
        String draft = '';

        if (_draftModel != null && _draftModel.input.isNotEmpty) {
          draft = _draftModel.input;
        }

        /// 输入框不为空 && inputState == false && 草稿内容和输入框内容不一致
        if (inputController.text.isNotEmpty &&
            !internalInputState &&
            draft != inputController.text) {
          internalInputState = true;
          final targetId =
              chatController.chat.isGroup ? 0 : chatController.chat.friend_id;

          /// 发送输入状态
          objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
          inputDebounce.call(() {
            internalInputState = false;
            objectMgr.chatMgr.chatInput(targetId, false, chatId);
          });
        } else if (inputController.text.isEmpty && internalInputState) {
          internalInputState = false;
          final targetId =
              chatController.chat.isGroup ? 0 : chatController.chat.friend_id;

          objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
          inputDebounce.dispose();
        }
      } else {
        internalInputState = false;
        final targetId =
            chatController.chat.isGroup ? 0 : chatController.chat.friend_id;

        objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
        inputDebounce.dispose();
      }

      /// 改变输入栏是否可发送状态
      sendState.value = inputController.text.trim().isNotEmpty ||
          notBlank(objectMgr.chatMgr.selectedMessageMap[chat!.id]) ||
          fileList.isNotEmpty ||
          selectedAssetList.isNotEmpty;

      if (super.type == 2) {
        _showAtAlert();
      }

      oldText = inputController.text;
    });

    autoDeleteInterval.value = chatController.chat.autoDeleteInterval;

    ///获取对方用户
    if (!chatController.chat.isGroup) {
      user.value =
          await objectMgr.userMgr.loadUserById(chatController.chat.friend_id);
    }

    setupScreenshotCallback();
    await SoundMode.ringerModeStatus;
  }

  void _onAutoDeleteIntervalChange(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (data.chat_id != chatController.chat.id) return;
      MessageInterval msgInterval =
          data.decodeContent(cl: MessageInterval.creator);
      autoDeleteInterval.value = msgInterval.interval;
    }
  }

  Future<void> _onUserUpdate(Object sender, Object type, Object? data) async {
    if (data is User && data.id == user.value?.uid) {
      user.value?.relationship = data.relationship;
      user.refresh();
    }
  }

  @override
  void onClose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.chatMgr
        .saveChatDraft(chatController.chat.chat_id, inputController.text);
    objectMgr.callMgr.off(CallMgr.eventIncomingCall, _onIncomingCall);
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    if (internalInputState) {
      final targetId =
          chatController.chat.isGroup ? 0 : chatController.chat.friend_id;
      objectMgr.chatMgr.chatInput(targetId, false, chatId);
    }

    if (isRecording.value) {
      toggleRecordingState(false, false);
      resetRecordingState();
    }

    releaseSoundPool();
    removeScreenshotCallback();
    super.onClose();
  }

  /// ================================ 事件监听回调 =============================

  /// =============================== 事件监听回调结束 ===========================

  /// =================================== 键盘操作 ==============================
  void _showAtAlert() {
    if (inputController.text.isEmpty) {
      CustomTextEditingController.mentionRange.clear();
      chatController.showMentionList.value = false;
    }

    checkShouldRemoveMentionList();

    if (inputController.selection.baseOffset < 0) return;

    if (inputController.text.isNotEmpty && chatController.chat.isGroup) {
      final int _offset = inputController.selection.baseOffset;

      if (inputController.text != oldText) {
        if (inputController.text.length - oldText.length < -1) {
          checkMentionListRange(
            _offset + (inputController.text.length - oldText.length).abs(),
            CustomTextEditingController.mentionRange,
          );

          int mentionIdx = -1;
          if (_offset < oldText.length &&
              CustomTextEditingController.mentionRange.isNotEmpty) {
            for (int i = 0;
                i < CustomTextEditingController.mentionRange.length;
                i++) {
              if (_offset >=
                      CustomTextEditingController.mentionRange[i].first &&
                  _offset < CustomTextEditingController.mentionRange[i].last) {
                mentionIdx = i;
                break;
              }
            }
            if (mentionIdx == -1) {
              deductMentionListIndex(
                _offset + (inputController.text.length - oldText.length).abs(),
                CustomTextEditingController.mentionRange,
                (inputController.text.length - oldText.length).abs(),
              );
            } else {
              CustomTextEditingController.mentionRange.removeAt(mentionIdx);
            }
          }
          oldText = inputController.text;
          return;
        }

        if (inputController.text.length == oldText.length) {
          for (int i = 0; i < inputController.text.length; i++) {
            if (inputController.text[i] != oldText[i]) return;
          }
        }

        if (inputController.text.length < oldText.length) {
          int mentionIdx = -1;
          if (_offset < oldText.length &&
              CustomTextEditingController.mentionRange.isNotEmpty) {
            for (int i = 0;
                i < CustomTextEditingController.mentionRange.length;
                i++) {
              if (_offset >=
                      CustomTextEditingController.mentionRange[i].first &&
                  _offset < CustomTextEditingController.mentionRange[i].last) {
                mentionIdx = i;
                break;
              }
            }
            if (mentionIdx == -1) {
              deductMentionListIndex(
                _offset,
                CustomTextEditingController.mentionRange,
                1,
              );
            }
          }

          if (mentionIdx != -1) {
            List<int> lastMentionRange =
                CustomTextEditingController.mentionRange.removeAt(mentionIdx);

            // check is in middle of the range
            checkMentionListRange(
                _offset, CustomTextEditingController.mentionRange);

            deductMentionListIndex(
              lastMentionRange.first,
              CustomTextEditingController.mentionRange,
              lastMentionRange.last - lastMentionRange.first,
            );

            String text =
                inputController.text.substring(0, lastMentionRange.first);
            if (inputController.text.length > lastMentionRange.last) {
              text += inputController.text.substring(lastMentionRange.last - 1);
            }
            inputController.text = text;
            inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: lastMentionRange.first),
            );
          }
          String word = getWordAtOffset(inputController.text, _offset);
          if (word.startsWith('@') && _offset != 0) {
            chatController.showMentionList.value = true;
          } else {
            chatController.showMentionList.value = false;
          }
          return;
        }

        if (_offset < oldText.length) {
          int diff =
              _offset - (inputController.text.length - oldText.length).abs();
          addMentionListIndex(
              diff < 0 ? 0 : diff,
              CustomTextEditingController.mentionRange,
              (inputController.text.length - oldText.length).abs());

          // check is in middle of the range
          checkMentionListRange(
              _offset, CustomTextEditingController.mentionRange);
        }

        String word = getWordAtOffset(inputController.text, _offset);
        if (word.startsWith('@')) {
          chatController.showMentionList.value = true;
        } else {
          chatController.showMentionList.value = false;
        }
      }
      oldText = inputController.text;
    }
  }

  ///添加 {{@用户}} 到输入框里
  void addMentionUser(User user) {
    final int _offset = inputController.selection.baseOffset;
    checkMentionListRange(_offset, CustomTextEditingController.mentionRange);

    mentionList.add(MentionModel(
      userName: user.nickname,
      userId: user.uid,
    ));

    String word = getWordAtOffset(inputController.text, _offset);
    int startPos = _offset - word.length;
    int endPos = startPos + word.length;

    if (startPos < 0) startPos = 0;
    if (endPos < 0 || endPos <= startPos) endPos = startPos + word.length;

    String _atStr = '@${user.nickname} ';

    deductMentionListIndex(
      _offset,
      CustomTextEditingController.mentionRange,
      word.length,
    );

    addMentionListIndex(
      startPos,
      CustomTextEditingController.mentionRange,
      _atStr.length,
    );

    bool isAddRange = false;
    for (int i = 0; i < CustomTextEditingController.mentionRange.length; i++) {
      if (_offset < CustomTextEditingController.mentionRange[i].first) {
        CustomTextEditingController.mentionRange
            .insert(i, [startPos, startPos + _atStr.length - 1]);
        isAddRange = true;
        break;
      }
    }

    if (!isAddRange) {
      CustomTextEditingController.mentionRange
          .add([startPos, startPos + _atStr.length - 1]);
    }

    if (inputController.text.isEmpty) {
      inputController.text = _atStr;
    } else {
      inputController.text = inputController.text.substring(0, startPos) +
          _atStr +
          inputController.text.substring(endPos);
    }

    inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: startPos + _atStr.length),
    );

    chatController.showMentionList.value = false;
  }

  void checkShouldRemoveMentionList() {
    List<int> shouldRemoveIdx = [];
    for (int i = 0; i < CustomTextEditingController.mentionRange.length; i++) {
      final List<int> range = CustomTextEditingController.mentionRange[i];
      if (range.first > inputController.text.length) {
        shouldRemoveIdx.add(i);
      }
    }

    for (int i = shouldRemoveIdx.length - 1; i >= 0; i--) {
      CustomTextEditingController.mentionRange.removeAt(shouldRemoveIdx[i]);
    }
  }

  void checkMentionListRange(int offset, List<List<int>> mentionRange) {
    final removeIdx = <int>[];
    for (int i = 0; i < mentionRange.length; i++) {
      final List<int> item = mentionRange[i];
      if (offset > item.first && offset <= item.last) {
        String nameText = oldText.substring(item.first + 1, item.last);
        mentionList.removeWhere((element) => element.userName == nameText);

        removeIdx.add(i);
      }
    }

    for (int i = removeIdx.length - 1; i >= 0; i--) {
      mentionRange.removeAt(removeIdx[i]);
    }
  }

  void addMentionListIndex(
      int offset, List<List<int>> mentionRange, int appendLength) {
    for (int i = 0; i < mentionRange.length; i++) {
      final List<int> range = mentionRange[i];
      if (offset < 0) continue;

      if (offset <= range.first || (offset - range.first).abs() <= 1) {
        range.first += appendLength;
        range.last += appendLength;
      }
    }
  }

  void deductMentionListIndex(
      int offset, List<List<int>> mentionRange, int deductLength) {
    for (int i = 0; i < mentionRange.length; i++) {
      final List<int> range = mentionRange[i];
      int rangeDiff = range.last - range.first;
      if (offset < 0) continue;

      if (offset <= range.first) {
        if (range.first - deductLength < 0) {
          range.first = 0;
          range.last = rangeDiff;
        } else {
          range.first -= deductLength;
          range.last -= deductLength;
        }
      }
    }
  }

  initSoundPool() async {
    _pool = Soundpool.fromOptions(options: _soundPoolOptions);
    sendMessageBubbleId = await rootBundle
        .load("assets/sound/sent_message.mp3")
        .then((ByteData soundData) {
      return _pool?.load(soundData);
    });
  }

  playSendMessageSound() async {
    /// 如果用户manual关闭发送信息声音
    bool status = objectMgr.localStorageMgr
            .read(LocalStorageMgr.MESSAGE_SOUND_NOTIFICATION) ??
        true;
    if (status) {
      final isAudioPlaying = await objectMgr.sysOprateMgr.isAudioPlaying();

      final ringerStatus = await SoundMode.ringerModeStatus;

      final isMute = [RingerModeStatus.silent, RingerModeStatus.vibrate]
          .contains(ringerStatus);

      final shouldPlay = isAudioPlaying == false && isMute == false;
      if (shouldPlay == true) {
        if (sendMessageBubbleId == null) {
          await initSoundPool();
        }
        await _pool?.play(sendMessageBubbleId!);
      }
    }
  }

  releaseSoundPool() async {
    sendMessageBubbleId = null;
    _pool?.release();
  }

  onForwardSaveMsg(int chatID) async {
    if (notBlank(objectMgr.chatMgr.selectedMessageMap[chatID])) {
      for (Message item in objectMgr.chatMgr.selectedMessageMap[chatID]!) {
        if ((item.typ <= messageTypeGroupChangeInfo &&
                item.typ >= messageTypeImage) ||
            item.typ == messageTypeRecommendFriend) {
          await objectMgr.chatMgr.sendForward(
            chatID,
            item,
            item.typ,
          );
        } else {
          var _contentStr = '';
          if (item.typ == messageTypeText ||
              item.typ == messageTypeReply ||
              item.typ == messageTypeReplyWithdraw) {
            MessageText _textMsg = item.decodeContent(cl: MessageText.creator);
            _contentStr = _textMsg.text;
          } else {
            _contentStr = ChatHelp.typShowMessage(chatController.chat, item);
          }
          await objectMgr.chatMgr.sendForward(
            chatID,
            item,
            messageTypeText,
            text: _contentStr,
          );
        }
      }
    }
    chatController.onChooseMoreCancel();
    objectMgr.chatMgr.selectedMessageMap[chatID]?.clear();
    objectMgr.chatMgr.selectedMessageMap.remove(chatID);

    update();
  }

  /// Chat Opera 操作 act
  @override
  Future<void> onSend(
    String? text, {
    bool isSendSticker = false,
    Sticker? sticker,
    BuildContext? context,
    bool isSendContact = false,
    User? user,
    List<AssetPreviewDetail> assets = const [],
    bool isOriginalImageSend = false,
    bool sendAsFile = false,
    bool isSendGif = false,
    Gifs? gifs,
  }) async {
    if (isSendSticker) {
      assert(isSendSticker && sticker != null, 'Sticker cannot be null');
    }

    if (isSendGif) {
      assert(isSendGif && gifs != null, 'Gifs cannot be null');
    }

    if (isSendContact) {
      assert(isSendContact && context != null && user != null,
          'User and Context cannot be null');
    }

    String copiedText = text ?? inputController.text;
    List<List<int>> range = CustomTextEditingController.mentionRange;

    if (copiedText.isNotEmpty &&
        inputController.text.isNotEmpty &&
        copiedText[0] != inputController.text[0] &&
        copiedText.length < inputController.text.length &&
        range.isNotEmpty) {
      final diff = inputController.text.length - copiedText.length;

      for (int i = 0; i < range.length; i++)
        deductMentionListIndex(
          0,
          CustomTextEditingController.mentionRange,
          diff,
        );
    }

    for (int i = range.length - 1; i >= 0; i--) {
      final List<int> item = range[i];
      if (item.first < copiedText.length && item.last <= copiedText.length) {
        String nameText = copiedText.substring(item.first + 1, item.last);
        MentionModel? model = mentionList
            .firstWhereOrNull((element) => element.userName == nameText);

        if (model != null) {
          copiedText = copiedText.replaceRange(item.first, item.last,
              '\u214F\u2983${model.userId}@jx\u2766\u2984');
        }
      }
    }

    /// 转发消息的发送
    /// 逐条转发
    if (objectMgr.chatMgr.groupSlowMode[chatId] != null) {
      if (!objectMgr.chatMgr.groupSlowMode[chatId]?['isEnable']) {
        Group group = objectMgr.chatMgr.groupSlowMode[chatId]?['group'];
        Message message = objectMgr.chatMgr.groupSlowMode[chatId]?['message'];
        DateTime createTime =
            DateTime.fromMillisecondsSinceEpoch(message.create_time * 1000);
        Duration duration = Duration(seconds: group.speak_interval) -
            DateTime.now().difference(createTime);
        Toast.showToastMessage(
            localized(inSlowMode, params: [getMinuteSecond(duration)]));
        return;
      }
    }

    try {
      if (notBlank(objectMgr.chatMgr.selectedMessageMap[chatId])) {
        for (Message item in objectMgr.chatMgr.selectedMessageMap[chatId]!) {
          if (item.typ == messageTypeImage ||
              item.typ == messageTypeVoice ||
              item.typ == messageTypeVideo ||
              item.typ == messageTypeReel ||
              item.typ == messageTypeFace ||
              item.typ == messageTypeGif ||
              item.typ == messageTypeRecommendFriend ||
              item.typ == messageTypeFile ||
              item.typ == messageTypeNewAlbum ||
              item.typ == messageTypeLocation) {
            final Message msgCopied = item.copyWith(null);
            await objectMgr.chatMgr.sendForward(
              chatController.chat.id,
              msgCopied,
              msgCopied.typ,
            );
          } else {
            var _contentStr = '';
            if (item.typ == messageTypeText ||
                item.typ == messageTypeReply ||
                item.typ == messageTypeReplyWithdraw) {
              MessageText _textMsg =
                  item.decodeContent(cl: MessageText.creator);
              _contentStr = _textMsg.text;
            } else {
              _contentStr = ChatHelp.typShowMessage(chatController.chat, item);
            }
            final Message msgCopied = item.copyWith(null);
            await objectMgr.chatMgr.sendForward(
              chatController.chat.id,
              msgCopied,
              messageTypeText,
              text: _contentStr,
            );
          }
        }
      }
    } catch (_) {
    } finally {
      chatController.onChooseMoreCancel();
      objectMgr.chatMgr.selectedMessageMap[chatId]?.clear();
      objectMgr.chatMgr.selectedMessageMap.remove(chatId);
      update();
    }

    if (isSendContact) {
      onSendContactCard(context!, user!);
      inputState = 0;
      chatController.onCancelFocus();
      clearText();
      sendState.value = false;
      return;
    }

    if (objectMgr.chatMgr.replyMessageMap.containsKey(chatId)) {
      replyData = ReplyModel().copyWith(
        id: objectMgr.chatMgr.replyMessageMap[chatId]!.id,
        messageId: objectMgr.chatMgr.replyMessageMap[chatId]!.messageId,
        chatIdx: objectMgr.chatMgr.replyMessageMap[chatId]!.chatIdx,
        nickName: objectMgr.chatMgr.replyMessageMap[chatId]!.nickName,
        typ: objectMgr.chatMgr.replyMessageMap[chatId]!.typ,
        userId: objectMgr.chatMgr.replyMessageMap[chatId]!.userId,
        text: objectMgr.chatMgr.replyMessageMap[chatId]!.text,
        url: objectMgr.chatMgr.replyMessageMap[chatId]!.url,
        filePath: objectMgr.chatMgr.replyMessageMap[chatId]!.filePath,
        atUser: objectMgr.chatMgr.replyMessageMap[chatId]!.atUser,
      );

      objectMgr.chatMgr.replyMessageMap.remove(chatId);
    }

    if (isSendSticker) {
      sendSticker(sticker!, reply: replyData);
      inputState = 0;
      // clearText();
      sendState.value = false;
      return;
    }

    if (isSendGif) {
      sendGif(gifs!, reply: replyData);
      inputState = 0;
      sendState.value = false;
      return;
    }

    /// 判断是否选择了媒体资源
    if (!sendAsFile &&
        ((assetPickerProvider != null &&
                assetPickerProvider!.selectedAssets.isNotEmpty) ||
            assets.isNotEmpty)) {
      onSendAsset(
        assets.isNotEmpty ? assets : assetPickerProvider!.selectedAssets,
        chatId,
        caption: notBlank(copiedText) ? copiedText : null,
        isOriginalImageSend: isOriginalImageSend,
        reply: replyData,
      );
      inputState = 0;
      chatController.onCancelFocus();
      clearText();
      sendState.value = false;
      return;
    }

    if (sendAsFile || fileList.isNotEmpty) {
      onSendFile(
        chatId,
        caption: notBlank(copiedText) ? copiedText : null,
        assets: assets,
        sendAsFile: sendAsFile,
        reply: replyData,
      );
      clearText();
      inputState = 0;
      Get.findAndDelete<FilePickerController>();
      sendState.value = false;
      update();
      return;
    }
    super.onSend(text,
        isSendSticker: isSendSticker,
        sticker: sticker,
        context: context,
        isSendContact: isSendContact,
        user: user,
        assets: assets,
        isOriginalImageSend: isOriginalImageSend,
        sendAsFile: sendAsFile);
    await playSendMessageSound();
  }

  void onSendVoice(VolumeModel vm) async {
    if (vm.path.isEmpty) {
      return;
    } else {
      ReplyModel? replyData;
      if (objectMgr.chatMgr.replyMessageMap.containsKey(chatId)) {
        replyData = ReplyModel().copyWith(
          id: objectMgr.chatMgr.replyMessageMap[chatId]!.id,
          messageId: objectMgr.chatMgr.replyMessageMap[chatId]!.messageId,
          chatIdx: objectMgr.chatMgr.replyMessageMap[chatId]!.chatIdx,
          nickName: objectMgr.chatMgr.replyMessageMap[chatId]!.nickName,
          typ: objectMgr.chatMgr.replyMessageMap[chatId]!.typ,
          userId: objectMgr.chatMgr.replyMessageMap[chatId]!.userId,
          text: objectMgr.chatMgr.replyMessageMap[chatId]!.text,
          url: objectMgr.chatMgr.replyMessageMap[chatId]!.url,
          filePath: objectMgr.chatMgr.replyMessageMap[chatId]!.filePath,
          atUser: objectMgr.chatMgr.replyMessageMap[chatId]!.atUser,
        );
        objectMgr.chatMgr.replyMessageMap.remove(chatId);
      }

      await objectMgr.chatMgr.sendVoice(
        chatId,
        vm.path,
        0,
        2,
        vm.second,
        notBlank(replyData) ? jsonEncode(replyData) : null,
        data: vm,
      );
      update();
      if (Platform.isIOS) {
        final audioManager = audioSession.AVAudioSession();
        await audioManager
            .setCategory(audioSession.AVAudioSessionCategory.playAndRecord);
        await audioManager.overrideOutputAudioPort(
          audioSession.AVAudioSessionPortOverride.speaker,
        );
        await Future.delayed(const Duration(milliseconds: 1000));
        await playSendMessageSound();
      } else {
        await playSendMessageSound();
      }
    }
  }

  void sendSticker(
    Sticker sticker, {
    ReplyModel? reply,
  }) async {
    objectMgr.chatMgr.sendStickers(
      chatID: chatId,
      name: sticker.name,
      data: sticker.url,
      reply: reply != null ? jsonEncode(reply) : null,
    );
    update();
    await playSendMessageSound();
    if (objectMgr.loginMgr.isDesktop) {
      Get.back();
    }
  }

  void sendGif(
    Gifs gifs, {
    ReplyModel? reply,
  }) async {
    objectMgr.chatMgr.sendGif(
      chatID: chatId,
      name: gifs.name,
      data: gifs.path,
      reply: reply != null ? jsonEncode(reply) : null,
    );
    update();
    await playSendMessageSound();
    if (objectMgr.loginMgr.isDesktop) {
      Get.back();
    }
  }

  @override
  void sendText(
    String text, {
    ReplyModel? reply,
  }) async {
    /// 匹配链接
    Iterable<RegExpMatch> matches = Regular.extractLink(inputController.text);

    final bool textWithLink;
    if (matches.isNotEmpty) {
      textWithLink = true;
    } else {
      textWithLink = false;
    }

    if (textWithLink && !chatController.linkEnable) {
      Toast.showToast(localized(errorBlockPermissionRestrict));

      //revert back
      inputController.text = inputController.text;
      sendState.value = true;
      return;
    }

    await objectMgr.chatMgr.sendText(
      chatId,
      text,
      textWithLink,
      reply: reply != null ? jsonEncode(reply) : null,
      atUser: jsonEncode(mentionList.map((e) => e.toJson()).toList()),
    );
  }

  @override
  void clearText() {
    mentionList.clear();
    CustomTextEditingController.mentionRange.clear();
    inputController.clear();
  }

  void onShowScreenShotsImg(BuildContext context) async {
    // if (Platform.isAndroid) {
    //   var _rep = await Permission.storage.isGranted;
    //   if (!_rep) {
    //     return;
    //   }
    // } else {
    //   var _rep = await Permission.photos.isGranted;
    //   if (!_rep) {
    //     return;
    //   }
    // }
    //
    // var list = await PhotoManager.getAssetPathList();
    // for (AssetPathEntity item in list) {
    //   if (item.name == "截屏" || item.name == "Screenshots") {
    //     // todo
    //     var assetsList = await item.getAssetListRange(start: 0, end: 1);
    //     //拿最近的
    //     if (assetsList.isNotEmpty) {
    //       var entity = assetsList[0];
    //       var diffTime = nowUnixTimeSecond() -
    //           entity.createDateTime.millisecondsSinceEpoch ~/ 1000;
    //       if (diffTime < 120 &&
    //           entity.id !=
    //               objectMgr.localStorageMgr
    //                   .read(LocalStorageMgr.SCREEN_SHOTS_SHOWID)) {
    //         objectMgr.localStorageMgr
    //             .write(LocalStorageMgr.SCREEN_SHOTS_SHOWID, entity.id);
    //         Toast.showAlert(
    //             alpha: 30,
    //             context: context,
    //             container: ChatImagePop(asset: entity, onSend: onSendVideo));
    //       }
    //     }
    //     break;
    //   }
    // }
  }

  /// 长按转发选项
  void onForwardMessage({
    bool fromChatInfo = false,
    bool fromMediaDetail = false,
  }) async {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ForwardContainer(
          chat: chatController.chat,
          forwardMsg: chatController.chooseMessage.values
              .map((e) => e.copyWith(null))
              .toList(),
        );
      },
    ).whenComplete(() {
      chatController.chooseMessage.clear();
      chatController.chooseMore.value = false;
    });
  }

  Future<void> deleteMessages(
    List<Message> messages,
    int chatId, {
    bool isAll = false,
  }) async {
    List<Message> remoteMessages = [];
    List<int> remoteMessageIds = [];
    List<Message> fakeMessages = [];
    // filter fake message
    messages.forEach((message) {
      if (message.message_id == 0) {
        fakeMessages.add(message);
      } else {
        remoteMessages.add(message);
        remoteMessageIds.add(message.message_id);
      }
    });

    if (fakeMessages.length > 0) {
      for (int i = 0; i < fakeMessages.length; i++) {
        objectMgr.chatMgr.localDelMessage(fakeMessages[i]);
      }
    }

    if (remoteMessages.length > 0) {
      chat_api.deleteMsg(
        chatId,
        remoteMessageIds,
        isAll: isAll,
      );

      remoteMessages.forEach((message) {
        objectMgr.chatMgr.localDelMessage(message);
      });
    }

    if (isMobile)
      Toast.showToast(
        localized(toastDeleteSuccess),
      );
    // Get.back();
  }

  void onChooseMessageDelete({
    required List<Message> messageList,
    bool isAll = false,
  }) {
    if (messageList.isEmpty) {
      Toast.showToast(localized(toastSelectMessage));
      return;
    }

    if (messageList.any((element) => element.isExpired == true)) {
      ImBottomToast(
        Get.context!,
        title: localized(actionCannotBePerformed),
        icon: ImBottomNotifType.warning,
        duration: 1,
        isStickBottom: false,
      );
      return;
    }

    unawaited(deleteMessages(messageList, chatId, isAll: isAll));

    chatController.onChooseMoreCancel();
  }

  /// 删除消息
  onDeleteMessage(
    BuildContext context,
    List<Message> messages, {
    bool isMore = false,
    bool isAll = false,
  }) async {
    if (!isMore && messages.length != 1) {
      return;
    }

    if (isDesktop) {
      await deleteMessages(messages, chatId, isAll: isAll);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: localized(popupDelete),
            content: Text(
              isAll
                  ? localized(chatInfoThisMessageWillBeDeletedForAllReceipts)
                  : localized(
                      chatInfoThisMessageWillBeDeletedFromYourMessageHistory),
              style: jxTextStyle.textDialogContent(),
              textAlign: TextAlign.center,
            ),
            confirmText: localized(buttonYes),
            cancelText: localized(buttonNo),
            confirmCallback: () async {
              if (isMore) {
                onChooseMessageDelete(messageList: messages, isAll: isAll);
              } else {
                await deleteMessages(messages, chatId, isAll: isAll);
              }
            },
          );
        },
      );
    }
  }

  void onReply(int sendId, Message message, Chat chat) async {
    final _replyModel = ReplyModel();
    Map<String, dynamic> replyData = jsonDecode(message.content);
    if (replyData.containsKey('reply')) {
      replyData.remove('reply');
    }

    final User? user = await objectMgr.userMgr.loadUserById(sendId);
    _replyModel.id = message.id;
    _replyModel.messageId = message.message_id;
    _replyModel.chatIdx = message.chat_idx;
    _replyModel.userId = message.isCalling ? replyData['inviter'] : sendId;
    _replyModel.nickName = user?.nickname ?? '';
    _replyModel.typ = message.isCalling ? messageTypeText : message.typ;

    switch (message.typ) {
      case messageTypeVideo:
      case messageTypeReel:
        _replyModel.url = replyData['cover'] ?? '';
        _replyModel.filePath = replyData['coverPath'] ?? '';
        _replyModel.text = ChatHelp.formalizeMentionContent(
          replyData['caption'] ?? replyData['text'] ?? '',
          message,
        );
        break;
      case messageTypeImage:
      case messageTypeLocation:
      case messageTypeFace:
      case messageTypeGif:
        _replyModel.url = replyData['url'] ?? '';
        _replyModel.filePath =
            replyData['coverPath'] ?? replyData['filePath'] ?? '';
        _replyModel.text = ChatHelp.formalizeMentionContent(
          replyData['caption'] ?? replyData['text'] ?? '',
          message,
        );
        break;
      case messageTypeNewAlbum:
        NewMessageMedia media = NewMessageMedia()..applyJson(replyData);
        _replyModel.url =
            (media.albumList?.first.mimeType?.contains('video') ?? false)
                ? media.albumList?.first.cover ?? ''
                : media.albumList?.first.url ?? '';
        _replyModel.filePath = media.albumList?.first.coverPath ?? '';
        _replyModel.text = ChatHelp.formalizeMentionContent(
          media.caption,
          message,
        );
        break;

      default:
        _replyModel.text = ChatHelp.formalizeMentionContent(
          replyData['text'] ?? '',
          message,
        );
        break;
    }

    if (message.isCalling) {
      replyData['text'] = ChatHelp.callMsgContent(message);
    }

    objectMgr.chatMgr.replyMessageMap[chat.id] = _replyModel;
    objectMgr.chatMgr.selectedMessageMap.remove(chat.id);
    // if (isDesktop)
    Future.delayed(const Duration(milliseconds: 100), () {
      inputFocusNode.requestFocus();
    });
    update();

    isVoiceMode.value = false;
    chatController.resetPopupWindow();
  }

  /**
   * 新逻辑
   */

  // ============================= 录音视频 =====================================
  openVideoScreen(bool value) {
    var viewController;
    if (Get.isRegistered<SingleChatController>()) {
      viewController = Get.find<SingleChatController>(tag: chatId.toString());
    } else {
      viewController = Get.find<GroupChatController>(tag: chatId.toString());
    }
    viewController.showVideoScreen(value);
  }

  void toggleVoiceMode() {
    if (!chatController.chat.isSecretary) {
      isVoiceMode.value = !isVoiceMode.value;
      if (isVoiceMode.value) {
        chatController.onCancelFocus();
      } else {
        inputFocusNode.requestFocus();
      }
    } else {
      Toast.showToast(localized(noVoiceAllowed));
    }
  }

  void startRecording(BuildContext context) async {
    onTapRelease = false;
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      /// 正在通话中
      Toast.showToast(localized(toastEndCall));
      return;
    }
    if (Platform.isIOS || Platform.isAndroid) {
      bool inUse = await MicrophoneInUse.isMicrophoneInUse();
      if (inUse) {
        Toast.showToast(localized(toastEndCall));
        return;
      }
    }

    playerService.stopPlayer();
    playerService.resetPlayer();

    var status =
        await Permissions.request([Permission.microphone], context: context);
    if (status) {
      /// 开始计算时间
      nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (!onTapRelease) {
        onTapRelease = false;
        inputFocusNode.unfocus();
        isLockedSelected.value = false;
        isDeleteSelected.value = false;
        recorderOverlayEntry = OverlayEntry(
          builder: (context) {
            return Obx(
              () => GestureDetector(
                onTap: isLocked.value
                    ? null
                    : () => toggleRecordingState(false, false),
                behavior: HitTestBehavior.translucent,
                child: VoiceRecordButton(
                  isRecording: isRecording.value,
                  onRecordingStateChange: toggleRecordingState,
                  controller: this,
                  isLocked: isLocked.value,
                  isLockedSelected: isLockedSelected.value,
                  isDeleteSelected: isDeleteSelected.value,
                  onEnd: resetRecordingState,
                ),
              ),
            );
          },
        );

        Overlay.of(context).insert(recorderOverlayEntry!);
      }
    }
  }

  void updateLongPressRecording(
      BuildContext context, LongPressMoveUpdateDetails detail) {
    final dragUpdateOffset = detail.globalPosition;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double bottomLine = screenHeight - (200 - (screenWidth / 6) + 16);

    bool leftXPositionRange =
        dragUpdateOffset.dx > 48 && dragUpdateOffset.dx < 48 + 72;
    bool rightXPositionRange = dragUpdateOffset.dx > screenWidth - 72 - 48 &&
        dragUpdateOffset.dx < screenWidth - 48;
    bool yPositionRange = dragUpdateOffset.dy < bottomLine &&
        dragUpdateOffset.dy > bottomLine - 72;

    if (leftXPositionRange && yPositionRange) {
      // 删除
      isDeleteSelected.value = true;
      isLockedSelected.value = false;
    } else if (rightXPositionRange && yPositionRange) {
      // 锁定
      isLockedSelected.value = true;
      isDeleteSelected.value = false;
    } else {
      isLockedSelected.value = false;
      isDeleteSelected.value = false;
    }
  }

  void endRecording(bool shouldSend) {
    Future.delayed(const Duration(milliseconds: 160), () {
      onTapRelease = true;
      if (isLockedSelected.value && isRecording.value) {
        isLocked.value = true;
        isLockedSelected.value = false;
        isDeleteSelected.value = false;
        WakelockPlus.enable();
      } else {
        toggleRecordingState(false, shouldSend);
      }
    });
  }

  void toggleRecordingState(bool record, bool shouldSend) {
    if (!shouldSend) {
      isDeleteSelected.value = true;
    }
    isRecording.value = record;
  }

  void showBottomPopup(
    BuildContext context, {
    required String tag,
    required MediaOption mediaOption,
  }) async {
    final controller = Get.find<CustomInputController>(tag: tag);
    bool permissionStatus;
    try {
      if (mediaOption == MediaOption.gallery ||
          mediaOption == MediaOption.document) {
        await controller.onPrepareMediaPicker(
          maxAssets: mediaOption == MediaOption.document ? 10 : null,
        );
        permissionStatus = true;
      } else {
        permissionStatus = false;
      }
      controller.inputFocusNode.unfocus();
    } on StateError {
      permissionStatus = false;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return MediaSelectorView(
          tag,
          permissionStatus,
          mediaOption: mediaOption,
        );
      },
    ).then((value) {
      if (value != null &&
          value['fromViewer'] != null &&
          value['assets'] != null &&
          value['assets'].isNotEmpty) {
        onSendAsset(value['assets'], chatId);
      }
    }).whenComplete(() {
      assetPickerProvider?.removeListener(onAssetPickerChanged);
      assetPickerProvider?.selectedAssets.clear();
      sendState.value = false;
      Get.findAndDelete<FilePickerController>();
      Get.findAndDelete<RedPacketController>();
      Get.findAndDelete<LocationController>();

      Future.delayed(const Duration(milliseconds: 200), () {
        chatController.clearContactSearching();
        Get.findAndDelete<TaskSelectorController>();
      });
    });
  }

  void resetRecordingState() {
    if (chatController.isVoice.value) {
      if (nowTime - limitTime < 1) {
        return;
      }

      limitTime = nowTime;
      endTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (endTime - nowTime < 1) {
        Toast.showToast(localized(toastShort));
      }
    }

    // 重置状态
    recorderOverlayEntry?.remove();
    recorderOverlayEntry = null;
    Future.delayed(const Duration(milliseconds: 50), () {
      isLocked.value = false;
      isLockedSelected.value = false;
      isDeleteSelected.value = false;
      isRecording.value = false;
      VolumeRecordService.sharedInstance.stopRecord();
    });
  }

  void receiveCircleVideoData(XFile file, int videoLength) {
    objectMgr.chatMgr.send(
        chatController.chat.chat_id,
        messageTypeLiveVideo,
        jsonEncode({
          'url': '',
          'size': 0,
          'flag': 2,
          'uuid': '',
          'width': 720,
          'height': 720,
          'second': videoLength,
          'cover': 0,
        }),
        data: File(file.path));

    onAudioRecordingCancel();
  }

  void onAudioRecordingCancel() {
    sendState.value = false;
  }

  /// ============================ 工具类函数 ===================================

  Future<void> onPrepareMediaPicker({int? maxAssets}) async {
    ps = await const AssetPickerDelegate().permissionCheck();

    if (assetPickerProvider != null) {
      assetPickerProvider!.removeListener(onAssetPickerChanged);
    }

    pickerConfig = AssetPickerConfig(
      requestType: RequestType.common,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      shouldRevertGrid: false,
      gridThumbnailSize: ThumbnailSize.square(
        (Config().messageMin).toInt(),
      ),
      maxAssets: maxAssets != null
          ? maxAssets
          : notBlank(objectMgr.chatMgr.replyMessageMap[chatId])
              ? 1
              : defaultMaxAssetsCount,
      textDelegate: AppLocalizations.of(chatController.context)!
              .locale
              .languageCode
              .contains('en')
          ? const EnglishAssetPickerTextDelegate()
          : const AssetPickerTextDelegate(),
    );
    assetPickerProvider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig!.maxAssets,
      pageSize: pickerConfig!.pageSize,
      pathThumbnailSize: pickerConfig!.pathThumbnailSize,
      selectedAssets: pickerConfig!.selectedAssets,
      requestType: pickerConfig!.requestType,
      sortPathDelegate: pickerConfig!.sortPathDelegate,
      filterOptions: pickerConfig!.filterOptions,
    );

    assetPickerProvider!.addListener(onAssetPickerChanged);
  }

  onAssetPickerChanged() {
    if (selectedAssetList.length !=
        assetPickerProvider!.selectedAssets.length) {
      selectedAssetList.value = assetPickerProvider!.selectedAssets;
    }

    if (assetPickerProvider!.selectedAssets.isNotEmpty || fileList.length > 0) {
      sendState.value = true;
    } else {
      sendState.value = false;
    }
  }

  /// 拍照
  onPhoto(BuildContext context) async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    chatController.playerService.stopPlayer();
    chatController.playerService.resetPlayer();
    releaseSoundPool();

    if (Platform.isAndroid) {
      var b = await Permissions.request([Permission.storage], context: context);
      if (!b) {
        return;
      }
    } else {
      var b = await Permissions.request([Permission.photos], context: context);
      if (!b) {
        return;
      }
    }
    var c = await Permissions.request([Permission.camera], context: context);
    if (!c) {
      return;
    }
    var d =
        await Permissions.request([Permission.microphone], context: context);
    if (!d) {
      return;
    }

    onPrepareMediaPicker();

    // final AssetEntity? entity = await CameraPicker.pickFromCamera(
    //   context,
    //   pickerConfig: CameraPickerConfig(
    //     enableRecording: true,
    //     enableAudio: true,
    //     maximumRecordingDuration: const Duration(seconds: 600),
    //     enablePullToZoomInRecord: false,
    //     theme: CameraPicker.themeData(accentColor),
    //     resolutionPreset: ResolutionPreset.veryHigh,
    //     textDelegate:
    //         cameraPickerTextDelegateFromLocale(objectMgr.langMgr.currLocale),
    //   ),
    // );
    final Map<String, dynamic>? res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => CamerawesomePage(
                  enableRecording: true,
                  maximumRecordingDuration: const Duration(seconds: 600),
                )));

    if (res == null) {
      return;
    }

    final AssetEntity? entity = res["result"];
    if (entity == null) {
      return;
    }

    Get.toNamed(RouteName.mediaPreviewView,
        preventDuplicates: false,
        arguments: {
          'isEdit': true,
          'entity': entity,
          'provider': assetPickerProvider,
          'pConfig': pickerConfig,
          'caption': inputController.text,
        })?.then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          assetPickerProvider?.selectedAssets.clear();
          sendState.value = false;
          return;
        }

        onSend(
          result?['caption'],
          assets: result != null
              ? (result['assets'] ?? <AssetPreviewDetail>[])
              : <AssetPreviewDetail>[],
          isOriginalImageSend:
              result != null ? result['originalSelect'] : false,
        ).then((_) {
          assetPickerProvider?.selectedAssets.clear();
        });
        return;
      }

      assetPickerProvider?.selectedAssets.clear();
      sendState.value = false;
      return;
    });
  }

  //发送图片或视频信息
  /// assets can be two types: [AssetEntity] or [AssetPreviewDetail]
  void onSendAsset(
    List<dynamic> assets,
    int chatID, {
    String? caption,
    bool isOriginalImageSend = false,
    ReplyModel? reply,
  }) async {
    if (assets.isEmpty) {
      return;
    }

    List<dynamic> assetsCopy = List.from(assets);
    if (assetsCopy.length > ChatHelp.imageNumLimit) {
      List<List<dynamic>> list =
          ChatHelp.splitList<dynamic>(assetsCopy, ChatHelp.imageNumLimit);
      for (List<dynamic> aList in list) {
        ChatHelp.onSplitImageOrVideo(
          assets: aList,
          caption: caption,
          chat: chatController.chat,
          isOriginalImageSend: isOriginalImageSend,
          reply: reply != null ? jsonEncode(reply) : null,
        );
        Future.delayed(const Duration(milliseconds: 10));
      }
      return;
    } else if (assetsCopy.length > 1) {
      ChatHelp.onSplitImageOrVideo(
        assets: assetsCopy,
        caption: caption,
        chat: chatController.chat,
        isOriginalImageSend: isOriginalImageSend,
        reply: reply != null ? jsonEncode(reply) : null,
      );
    } else {
      if (assetsCopy.first is AssetPreviewDetail) {
        final AssetPreviewDetail asset = assetsCopy.first;
        if (asset.entity.type == AssetType.video) {
          onSendSingleVideo(
            asset.entity,
            caption,
            isOriginalImageSend: isOriginalImageSend,
            reply: reply,
          );
        } else {
          if (asset.editedFile != null) {
            ChatHelp.sendImageFile(
              asset.editedFile!,
              chat!,
              width: asset.editedWidth ?? 0,
              height: asset.editedHeight ?? 0,
              caption: caption,
              isOriginalImageSend: isOriginalImageSend,
              reply: reply != null ? jsonEncode(reply) : null,
            );
          } else {
            onSendSingleImage(
              asset.entity,
              caption,
              isOriginalImageSend: isOriginalImageSend,
              reply: reply,
            );
          }
        }
      } else {
        if (assetsCopy.first.type == AssetType.video) {
          onSendSingleVideo(
            assetsCopy.first,
            caption,
            isOriginalImageSend: isOriginalImageSend,
            reply: reply,
          );
        } else {
          onSendSingleImage(
            assetsCopy.first,
            caption,
            isOriginalImageSend: isOriginalImageSend,
            reply: reply,
          );
        }
      }
    }

    await playSendMessageSound();
  }

  Future<void> onSendSingleVideo(
    AssetEntity asset,
    String? caption, {
    bool isOriginalImageSend = false,
    ReplyModel? reply,
  }) async {
    assetPickerProvider?.selectedAssets = [];
    await ChatHelp.sendVideoAsset(
      asset,
      chatController.chat,
      caption,
      reply: reply != null ? jsonEncode(reply) : null,
      isOriginalImageSend: isOriginalImageSend,
    );

    update();
  }

  Future<void> onSendSingleImage(
    AssetEntity asset,
    String? caption, {
    bool isOriginalImageSend = false,
    ReplyModel? reply,
  }) async {
    assetPickerProvider?.selectedAssets = [];
    await ChatHelp.sendImageAsset(
      asset,
      chatController.chat,
      caption: caption,
      reply: reply != null ? jsonEncode(reply) : null,
      isOriginalImageSend: isOriginalImageSend,
    );

    update();
  }

  onSendFile(
    int chatID, {
    String? caption,
    List<AssetPreviewDetail> assets = const [],
    bool sendAsFile = false,
    ReplyModel? reply,
  }) async {
    List<File> duplicateFile = [];
    List<String> pathList = [];
    final List<File> pathListCopy = List<File>.from(fileList);

    if (assets.isNotEmpty) {
      for (final asset in assets) {
        if (asset.editedFile != null) {
          pathListCopy.add(asset.editedFile!);
        } else {
          final File? file = await asset.entity.originFile;
          if (file != null) {
            pathListCopy.add(file);
          }
        }
      }
    } else if (assetPickerProvider!.selectedAssets.isNotEmpty) {
      List<AssetEntity> entitiesCopy =
          List.from(assetPickerProvider!.selectedAssets);
      for (final asset in entitiesCopy) {
        final File? file = await asset.originFile;
        if (file != null) {
          pathListCopy.add(file);
        }
      }
    }

    if (FileUploader.shared.uploadFileMap.length > 0) {
      FileUploader.shared.uploadFileMap.forEach((key, value) {
        pathList.add(value.originalPath!);
      });
    }

    for (final element in pathListCopy) {
      if (pathList.contains(element.path)) {
        duplicateFile.add(element);
      } else {
        objectMgr.chatMgr.sendFile(
          data: element,
          chatID: chatID,
          length: element.lengthSync(),
          file_name: pp.basename(element.path),
          suffix: pp.extension(element.path),
          caption: caption ?? '',
          reply: reply != null ? jsonEncode(reply) : null,
        );
        //prevent same send time
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (duplicateFile.length > 0) {
      Toast.showToast(
          '${duplicateFile.map((e) => pp.basename(e.path)).toList()} ${localized(errorSelectedFileSend)}',
          duration: const Duration(seconds: 2));
    }

    fileList.clear();
    update();
    await playSendMessageSound();
  }

  //設定自動刪除訊息的時間區間
  setAutoDeleteMsgInterval(int seconds) {
    chatController.chat.autoDeleteInterval = seconds;
    autoDeleteInterval.value = chatController.chat.autoDeleteInterval;
  }

  Future<void> pasteImage(BuildContext context) async {
    final bytes = await Pasteboard.image;
    final filePaths = await Pasteboard.files();

    if (bytes != null && filePaths.isEmpty) {
      final XFile? image = await saveImageToXFile(bytes);
      if (image != null) {
        String fileExtension = getFileExtension(image.path);
        if (imageExtension.contains(fileExtension)) {
          showAttachFileDialog(context, [image]);
        }
        return;
      }
    }

    if (filePaths.isNotEmpty) {
      List<XFile> fileList = [];
      for (final path in filePaths) {
        if (!Directory(path).existsSync()) {
          final XFile image = XFile(path);
          if (File(path).existsSync()) {
            fileList.add(image);
          } else {
            return;
          }
        } else {
          return;
        }
      }
      final XFile image = XFile(filePaths[0]);
      String fileExtension = getFileExtension(image.path);
      if (imageExtension.contains(fileExtension)) {
        showAttachFileDialog(context, [image]);
        inputController.clear();
      } else if (videoExtension.contains(fileExtension)) {
        showAttachFileDialog(context, fileList, FileType.video);
        inputController.clear();
      } else {
        showAttachFileDialog(context, fileList, FileType.document);
        inputController.clear();
      }
      return;
    }
  }

  void showAttachFileDialog(BuildContext context, List<XFile> files,
      [FileType fileType = FileType.image]) {
    DesktopGeneralDialog(
      context,
      widgetChild: AttachFileDialog(
        title: fileType == FileType.image
            ? 'Image'
            : fileType == FileType.video
                ? 'Video'
                : 'File',
        file: files,
        chatId: chatId, // Assuming chatId is defined somewhere in your code
        fileType: fileType,
      ),
    );
  }

  // 资源路径多语言翻译
  String getPathName(AssetPathEntity? pathEntity) {
    switch (pathEntity?.name) {
      // 最近
      case "最近项目":
      case "Recent":
      case "recent":
        return localized(recent);
      //截屏
      case "截屏":
      case "Screenshots":
      case "ScreenShots":
      case "screenshots":
        return localized(screenshots);
      //电影
      case "电影":
      case "视频":
      case "Movies":
      case "movies":
        return localized(movies);
      //文件夹
      case "文件":
      case "文件夹":
      case "Documents":
      case "documents":
        return localized(documents);
      //拍照
      case "相机":
      case "Camera":
      case "camera":
        return localized(camera);
      //图片
      case "图片":
      case "Pictures":
      case "pictures":
        return localized(picture);
      //截屏记录
      case "455968004":
        return localized(screenRecording);
      //下载
      case "下载":
      case "Downloads":
      case "downloads":
      case "Download":
      case "download":
        return localized(downloads);
      //实况照片
      case "实况照片":
      case "Live Photos":
        return localized(livePhotos);
      //实况照片
      case "个人收藏":
      case "Favourites":
      case "favourites":
        return localized(favourites);
      default:
        return pathEntity?.name ?? '';
    }
  }

  ///长按贴纸的列表
  Widget StickerOptionTile(
    String title,
    Icon icon,
    BorderRadius border, {
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: border,
        ),
        child: Padding(
          padding: EdgeInsets.all(15.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: MFontWeight.bold5.value,
                  color: Colors.black,
                ),
              ),
              icon,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onSendContactCard(BuildContext context, User user) async {
    objectMgr.chatMgr.sendRecommendFriend(
      chatController.chat.chat_id,
      user.id,
      user.nickname,
      user.id,
      user.countryCode,
      user.contact,
    );
    await playSendMessageSound();
    chatController.clearContactSearching();
    chatController.onCancelFocus();
    Get.back();
  }

  void addEmoji(String emoji) {
    inputController.text = inputController.text + emoji;
    objectMgr.stickerMgr.updateRecentEmoji(emoji);
  }

  onOpenFace() {
    chatController.showAttachmentView.value = false;

    /// 已经打开表情窗口 并且 键盘没有出现
    if (chatController.showFaceView.value) {
      inputState = 1;
      chatController.showFaceView.value = false;
      assetPickerProvider?.selectedAssets = [];
      inputFocusNode.requestFocus();

      inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: inputController.text.length));
    } else {
      chatController.showFaceView.value = true;

      /// 移除输入法焦点
      if (inputFocusNode.hasFocus) {
        inputState = 1;
      } else {
        inputState = 2;
      }
      inputFocusNode.unfocus();
    }
    isVoiceMode.value = false;
    update(['emoji_tab'].toList());
    update();
    chatController.update();
  }

  void onMore(BuildContext context) async {
    /// {{更多}} 选项已经开启 并且 键盘没有出现
    setAttachmentOption();
    onShowScreenShotsImg(context);
    chatController.showFaceView.value = false;
    chatController.showMentionList.value = false;
    chatController.showAttachmentView.value =
        !chatController.showAttachmentView.value;

    if (inputFocusNode.hasFocus) {
      inputState = 1;
    } else {
      inputState = 2;
    }
    inputFocusNode.unfocus();
  }

  setupScreenshotCallback() {
    if (screenshotCallback == null) {
      screenshotCallback = ScreenshotCallback();
    }
    screenshotCallback?.addListener(() async {
      if (chatController.isScreenshotEnabled &&
          chatController.appState == AppLifecycleState.resumed) {
        chat_api.onScreenshot(chatId);
      }
    });
  }

  removeScreenshotCallback() {
    screenshotCallback?.dispose();
    screenshotCallback = null;
  }

  void setAttachmentOption() {
    if (chatController.chat.isGroup) {
      Group? group = objectMgr.myGroupMgr.getGroupById(chatController.chat.id);
      if (group?.owner != objectMgr.userMgr.mainUser.uid) {
        if (!GroupPermissionMap.groupPermissionSendMedia
            .isAllow(chatController.permission.value)) {
          chatController.attachmentOptions
              .remove(chatController.attachmentPictureOption);
          chatController.attachmentOptions
              .remove(chatController.attachmentCameraOption);
        } else {
          if (!chatController.attachmentOptions
              .contains(chatController.attachmentPictureOption)) {
            chatController.attachmentOptions
                .add(chatController.attachmentPictureOption);
          }
          if (!chatController.attachmentOptions
              .contains(chatController.attachmentCameraOption)) {
            chatController.attachmentOptions
                .add(chatController.attachmentCameraOption);
          }
        }
        if (!GroupPermissionMap.groupPermissionSendDocument
            .isAllow(chatController.permission.value)) {
          chatController.attachmentOptions
              .remove(chatController.attachmentFileOption);
        } else {
          if (!chatController.attachmentOptions
              .contains(chatController.attachmentFileOption)) {
            chatController.attachmentOptions
                .add(chatController.attachmentFileOption);
          }
        }
        if (!GroupPermissionMap.groupPermissionSendContacts
            .isAllow(chatController.permission.value)) {
          chatController.attachmentOptions
              .remove(chatController.attachmentContactOption);
        } else {
          if (!chatController.attachmentOptions
              .contains(chatController.attachmentContactOption)) {
            chatController.attachmentOptions
                .add(chatController.attachmentContactOption);
          }
        }
        if (!GroupPermissionMap.groupPermissionSendRedPacket
            .isAllow(chatController.permission.value)) {
          chatController.attachmentOptions
              .remove(chatController.attachmentRedPacketOption);
        } else {
          if (!chatController.attachmentOptions
              .contains(chatController.attachmentRedPacketOption)) {
            chatController.attachmentOptions
                .add(chatController.attachmentRedPacketOption);
          }
        }
      }
    }
  }

  _onIncomingCall(_, __, ___) {
    resetRecordingState();
  }

  int get type => super.type;

  set type(int type) {
    super.type = type;
  }
}
