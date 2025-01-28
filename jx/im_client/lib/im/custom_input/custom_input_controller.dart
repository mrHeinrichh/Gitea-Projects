import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/component/media_selector_view.dart';
import 'package:jxim_client/im/custom_input/component/voice_record_button.dart';
import 'package:jxim_client/im/custom_input/custom_input_auto_delete_mixin.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/task/task_selector_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/audio_recording_model/volume_model.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/audio_services/volume_record_service.dart';
import 'package:jxim_client/im/services/custom_text_editing_controller.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/draft_model.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/object/sticker_gifs_entity.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/clip_board_util.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/file_utils.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/link_analyzer/link_analyzer.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/sound_helper.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/unescape_util.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/utils/wake_lock_utils.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/attach_file_dialog.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as pp;
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

const String emptyNoSeeStr = "\u200B";

const MethodChannel methodChannel = MethodChannel('desktopAction');

class CustomInputController extends GetxController
    with GetTickerProviderStateMixin, CustomInputAutoDeleteMixin {
  bool isGettingFile = false;
  final ScrollController scrollController = ScrollController();

  int type = -1;

  RxBool hasImageInClipBoardInIOS = RxBool(false);

  late int chatId;

  late BaseChatController chatController;

  late CustomTextEditingController inputController;

  FocusNode inputFocusNode = FocusNode();

  TextEditingController mediaPickerInputController = TextEditingController();

  String oldText = '';

  int inputState = 0;

  ChatInputState internalInputState = ChatInputState.noTyping;

  RxBool sendState = RxBool(false);

  RxList<MentionModel> mentionList = <MentionModel>[].obs;

  RxInt autoDeleteInterval = RxInt(0);

  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;
  RxList<AssetEntity> selectedAssetList = <AssetEntity>[].obs;
  Map<String, String> compressedSelectedAsset = <String, String>{};
  RxList<File> fileList = <File>[].obs;

  final VolumePlayerService playerService = VolumePlayerService.sharedInstance;

  int nowTime = 0;
  int endTime = 0;
  int limitTime = 0;
  bool onTapRelease = false;

  RxBool isVoiceMode = RxBool(false);

  RxBool isRecording = RxBool(false);

  RxBool isLocked = RxBool(false);

  RxBool isLockedSelected = RxBool(false);
  RxBool isDeleteSelected = RxBool(false);

  OverlayEntry? recorderOverlayEntry;

  bool isRecordingCancel = false;
  RxBool recordingIsPlaying = RxBool(false);

  Offset dragOffset = const Offset(0.0, 0.0);

  Rxn<User> user = Rxn<User>();

  final isDesktop = objectMgr.loginMgr.isDesktop;
  final isMobile = objectMgr.loginMgr.isMobile;

  final stickerDebounce = Debounce(const Duration(milliseconds: 600));
  final inputDebounce = Debounce(const Duration(milliseconds: 5000));

  Chat? chat;

  CustomInputController();

  CustomInputController.desktop(Chat this.chat);

  ScreenshotCallback? screenshotCallback;
  bool isScreenshotEnabled = false;

  final showTranslateBar = false.obs;
  final isTranslating = false.obs;
  final translatedText = ''.obs;
  final translateLocale = 'EN'.obs;
  final isSending = false.obs;
  Timer? _typingDebounce;

  RxBool isLongPressVoiceRecordBtn = RxBool(false);

  /// 链接
  final linkSearchingDebounce = Debounce(const Duration(milliseconds: 500));
  CancelToken? linkSearchCancelToken;
  bool ignoreLinkPreview = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    objectMgr.chatMgr
        .on(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.callMgr.on(CallMgr.eventIncomingCall, _onIncomingCall);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
    objectMgr.chatMgr.on(ChatMgr.eventChatIsTyping, _onChatTypingUpdate);

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
        type = chatController.chat.typ == chatTypeSmallSecretary ? 4 : 1;
      } else {
        chatController =
            Get.find<GroupChatController>(tag: chat?.id.toString());
        type = 2;
      }
      translateLocale.value = getAutoLocale(chat: chat);
    }

    inputController = CustomTextEditingController(
      atList: mentionList,
    );

    sendState.value = notBlank(objectMgr.chatMgr.selectedMessageMap[chat!.id]);

    chatId = chatController.chat.chat_id == 0
        ? chatController.chat.id
        : chatController.chat.chat_id;

    DraftModel? draftModel =
        objectMgr.chatMgr.getChatDraft(chatController.chat.chat_id);

    if (draftModel != null && draftModel.input.isNotEmpty) {
      inputController.text = draftModel.input;

      sendState.value = true;
    }

    inputFocusNode.addListener(() {
      if (!inputFocusNode.hasFocus && !internalInputState.isSendingMedia)
      {
        internalInputState = ChatInputState.noTyping;

        final targetId = chatController.chat.isGroup ? 0 : chatController.chat.friend_id;
        objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
        chatController.mainListFocusNode.requestFocus();
      }

      if (inputFocusNode.hasFocus)
      {
        chatController.removeShortcutImage();
        if (chatController.showFaceView.value) {
          chatController.showFaceView.value = false;
        }
        if (chatController.showAttachmentView.value) {
          chatController.showAttachmentView.value = false;
        }
        KeyBoardObserver.instance.keyboardHeightNow = 0.0;
      }

      if (!inputFocusNode.hasFocus) ignoreLinkPreview = false;
    });

    inputController.addListener(() {
      chatController.removeShortcutImage();
      if (inputController.text.length >= 4096) {
        Toast.showToast(localized(errorMaxCharInput));
      }
      if (inputFocusNode.hasFocus) {
        String draft = '';
        if (_typingDebounce?.isActive ?? false) _typingDebounce?.cancel();
        if (chat!.isAutoTranslateOutgoing) {
          _typingDebounce = Timer(const Duration(milliseconds: 500), () {
            _translateUserText(inputController.text);
          });
        }

        if (draftModel != null && draftModel.input.isNotEmpty) {
          draft = draftModel.input;
        }

        if (objectMgr.loginMgr.isDesktop) {
          // 保存草稿
          objectMgr.chatMgr.saveChatDraft(
            chatController.chat.chat_id,
            inputController.text,
          );
        }

        if (inputController.text.isNotEmpty &&
            !internalInputState.isSendingMedia &&
            draft != inputController.text) {
          internalInputState = ChatInputState.typing;
          final targetId =
              chatController.chat.isGroup ? 0 : chatController.chat.friend_id;

          objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
          inputDebounce.call(() {
            internalInputState = ChatInputState.noTyping;
            objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
          });
          if (chat!.isAutoTranslateOutgoing &&
              !EmojiParser.hasOnlyEmojis(inputController.text)) {
            showTranslateBar.value = true;
          }
        } else if (inputController.text.isEmpty &&
            !internalInputState.isSendingMedia) {
          _typingDebounce?.cancel();
          showTranslateBar.value = false;
          translatedText.value = '';
          internalInputState = ChatInputState.noTyping;
          final targetId =
              chatController.chat.isGroup ? 0 : chatController.chat.friend_id;

          objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
          inputDebounce.dispose();
        }
      } else {
        if (inputController.text.isEmpty) {
          _typingDebounce?.cancel();
          showTranslateBar.value = false;
          translatedText.value = '';
        }

        if (!internalInputState.isSendingMedia) {
          internalInputState = ChatInputState.noTyping;
          final targetId =
              chatController.chat.isGroup ? 0 : chatController.chat.friend_id;

          objectMgr.chatMgr.chatInput(targetId, internalInputState, chatId);
          inputDebounce.dispose();
        }
      }

      sendState.value = inputController.text.trim().isNotEmpty ||
          notBlank(objectMgr.chatMgr.selectedMessageMap[chat!.id]) ||
          fileList.isNotEmpty ||
          selectedAssetList.isNotEmpty;

      _onMatchLink();

      if (type == 2) {
        _showAtAlert();
      }

      oldText = inputController.text;

      if (objectMgr.loginMgr.isDesktop) {
        objectMgr.chatMgr.reflectDraftStringInstant(
          chatId,
          inputController.text,
        );
      }
    });

    _addListenerMediaPickerInputController();

    autoDeleteInterval.value = chatController.chat.autoDeleteInterval;

    if (!chatController.chat.isGroup) {
      user.value = await objectMgr.userMgr.loadUserById(chatController.chat.friend_id);
    }

    setupScreenshotCallback();
    if (!objectMgr.loginMgr.isDesktop) {
      await SoundMode.ringerModeStatus;
    }

    // 监听原生端的焦点变化事件
    if (objectMgr.loginMgr.isDesktop) {
      methodChannel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'appFocusChanged') {
          bool isAppActive = call.arguments;
          if (!isAppActive && inputFocusNode.hasFocus) {
            inputFocusNode.unfocus(); // 失去焦点时取消TextFormField的聚焦
          }
        }
      });
    }
  }

  _addListenerMediaPickerInputController() {
    mediaPickerInputController.addListener(() {
      if (_typingDebounce?.isActive ?? false) _typingDebounce?.cancel();
      if (chat!.isAutoTranslateOutgoing) {
        _typingDebounce = Timer(const Duration(milliseconds: 500), () {
          _translateUserText(mediaPickerInputController.text);
        });

        if (mediaPickerInputController.text.isNotEmpty) {
          if (!EmojiParser.hasOnlyEmojis(mediaPickerInputController.text)) {
            showTranslateBar.value = true;
          }
        } else {
          _typingDebounce?.cancel();
          showTranslateBar.value = false;
          translatedText.value = '';
        }
      }
    });
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

  Timer? _timer;

  _translateUserText(String text) async {
    if (EmojiParser.hasOnlyEmojis(text)) return;
    if (!await serversUriMgr.checkIsConnected()) return;
    if (connectivityMgr.connectivityResult == ConnectivityResult.none) return;
    bool doneAnimation = false;
    isTranslating.value = true;
    _timer = Timer(const Duration(milliseconds: 995), () {
      if (doneAnimation) {
        isTranslating.value = false;
      }
    });

    Map<String, String> res = await objectMgr.chatMgr.getMessageTranslation(
      text,
      locale: translateLocale.value,
    );
    if (res['translation'] != '') {
      translatedText.value = UnescapeUtil.encodedString(res['translation']!);
    } else {
      translatedText.value = '';
    }
    if (_timer!.isActive) {
      doneAnimation = true;
    } else {
      isTranslating.value = false;
    }
  }

  _onChatReplace(_, __, data) {
    if (data is Chat && chat!.chat_id == data.chat_id) {
      chat = data;
      if (!chat!.isAutoTranslateOutgoing) {
        showTranslateBar.value = false;
        isTranslating.value = false;
        translatedText.value = '';
        if (_typingDebounce?.isActive ?? false) _typingDebounce?.cancel();
      }
      translateLocale.value = getAutoLocale(chat: chat);
      _translateUserText(inputController.text);
    }
  }

  _onChatTypingUpdate(_, __, data) {
    if (data is! ChatInput || data.chatId != chatId) return;

    internalInputState = data.state;
  }

  @override
  void onClose() {
    objectMgr.chatMgr
        .saveChatDraft(chatController.chat.chat_id, inputController.text);

    if (!internalInputState.isSendingMedia) {
      final targetId =
          chatController.chat.isGroup ? 0 : chatController.chat.friend_id;
      objectMgr.chatMgr.chatInput(targetId, ChatInputState.noTyping, chatId);
    }

    if (isRecording.value) {
      recorderOverlayEntry?.remove();
      recorderOverlayEntry = null;
      toggleRecordingState(false, false);
      resetRecordingState();
    }

    removeScreenshotCallback();
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);
    objectMgr.callMgr.off(CallMgr.eventIncomingCall, _onIncomingCall);
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventChatTranslateUpdate, _onChatReplace);
    objectMgr.chatMgr.off(ChatMgr.eventChatIsTyping, _onChatTypingUpdate);
    super.onClose();
  }

  void _showAtAlert() {
    if (inputController.text.isEmpty) {
      CustomTextEditingController.mentionRange.clear();
      chatController.showMentionList.value = false;
    }

    checkShouldRemoveMentionList();

    if (inputController.selection.baseOffset < 0) return;

    if (inputController.text.isNotEmpty && chatController.chat.isGroup) {
      final int offset = inputController.selection.baseOffset;

      if (inputController.text != oldText) {
        if (inputController.text.length - oldText.length < -1) {
          checkMentionListRange(
            offset + (inputController.text.length - oldText.length).abs(),
            CustomTextEditingController.mentionRange,
          );

          int mentionIdx = -1;
          if (offset < oldText.length &&
              CustomTextEditingController.mentionRange.isNotEmpty) {
            for (int i = 0;
                i < CustomTextEditingController.mentionRange.length;
                i++) {
              if (offset >= CustomTextEditingController.mentionRange[i].first &&
                  offset < CustomTextEditingController.mentionRange[i].last) {
                mentionIdx = i;
                break;
              }
            }
            if (mentionIdx == -1) {
              deductMentionListIndex(
                offset + (inputController.text.length - oldText.length).abs(),
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
            if (inputController.text[i] != oldText[i]) {
              if (inputController.text[i].startsWith(String.fromCharCode(64)) ||
                  inputController.text[i]
                      .startsWith(String.fromCharCode(65312))) {
                continue;
              }
              return;
            }
          }
        }

        if (inputController.text.length < oldText.length) {
          int mentionIdx = -1;
          if (offset < oldText.length &&
              CustomTextEditingController.mentionRange.isNotEmpty) {
            for (int i = 0;
                i < CustomTextEditingController.mentionRange.length;
                i++) {
              if (offset >= CustomTextEditingController.mentionRange[i].first &&
                  offset < CustomTextEditingController.mentionRange[i].last) {
                mentionIdx = i;
                break;
              }
            }
            if (mentionIdx == -1) {
              deductMentionListIndex(
                offset,
                CustomTextEditingController.mentionRange,
                1,
              );
            }
          }

          if (mentionIdx != -1) {
            List<int> lastMentionRange =
                CustomTextEditingController.mentionRange.removeAt(mentionIdx);
            mentionList.removeAt(mentionIdx);

            checkMentionListRange(
              offset,
              CustomTextEditingController.mentionRange,
            );

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
          String word = getWordAtOffset(inputController.text, offset);
          if ((word.startsWith(String.fromCharCode(64)) ||
                  word.startsWith(String.fromCharCode(65312))) &&
              offset != 0) {
            chatController.showMentionList.value = true;
          } else {
            chatController.showMentionList.value = false;
          }
          return;
        }

        if (offset < oldText.length) {
          int diff =
              offset - (inputController.text.length - oldText.length).abs();
          addMentionListIndex(
            diff < 0 ? 0 : diff,
            CustomTextEditingController.mentionRange,
            (inputController.text.length - oldText.length).abs(),
          );

          checkMentionListRange(
            offset,
            CustomTextEditingController.mentionRange,
          );
        }

        String word = getWordAtOffset(inputController.text, offset);
        if (word.startsWith(String.fromCharCode(64)) ||
            word.startsWith(String.fromCharCode(65312))) {
          chatController.showMentionList.value = true;
        } else {
          chatController.showMentionList.value = false;
        }
      }
      oldText = inputController.text;
    }
  }

  // return base offset
  int prepopulateMentionUser(User user,
      {bool isAll = false, int newOffset = 0}) {
    mentionList.add(
      MentionModel(
        userName: user.nickname,
        userId: user.uid,
        role: isAll ? Role.all : Role.none,
      ),
    );

    final startIdx = inputController.text.indexOf(
      user.nickname,
      newOffset,
    );
    if (startIdx != -1) {
      CustomTextEditingController.mentionRange
          .add([startIdx - 1, startIdx + user.nickname.length]);
    }

    return startIdx + user.nickname.length;
  }

  void addMentionUser(
    User user, {
    bool isAll = false,
  }) {
    final int offset = inputController.selection.baseOffset;
    checkMentionListRange(offset, CustomTextEditingController.mentionRange);
    String? nickname;
    if (!isAll) {
      User? localUser = objectMgr.userMgr.getUserById(user.uid);
      nickname = objectMgr.userMgr.getUserTitle(
        localUser ?? user,
        groupId: chat!.id,
      );
    }

    mentionList.add(
      MentionModel(
        userName: nickname ?? user.nickname,
        userId: user.uid,
        role: isAll ? Role.all : Role.none,
      ),
    );

    String word = getWordAtOffset(inputController.text, offset);
    int startPos = offset - word.length;
    int endPos = startPos + word.length;

    if (startPos < 0) startPos = 0;
    if (endPos < 0 || endPos <= startPos) endPos = startPos + word.length;

    String atStr = '@$nickname ';

    if (isAll) {
      atStr = '@${localized(mentionAll)} ';
    }

    deductMentionListIndex(
      offset,
      CustomTextEditingController.mentionRange,
      word.length,
    );

    addMentionListIndex(
      startPos,
      CustomTextEditingController.mentionRange,
      atStr.length,
    );

    bool isAddRange = false;
    for (int i = 0; i < CustomTextEditingController.mentionRange.length; i++) {
      if (offset < CustomTextEditingController.mentionRange[i].first) {
        CustomTextEditingController.mentionRange
            .insert(i, [startPos, startPos + atStr.length - 1]);
        isAddRange = true;
        break;
      }
    }

    if (!isAddRange) {
      CustomTextEditingController.mentionRange
          .add([startPos, startPos + atStr.length - 1]);
    }

    if (inputController.text.isEmpty) {
      inputController.text = atStr;
    } else {
      inputController.text = inputController.text.substring(0, startPos) +
          atStr +
          inputController.text.substring(endPos);
    }

    inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: startPos + atStr.length),
    );

    chatController.showMentionList.value = false;
  }

  void onAppendMentionUser(User user) {
    int offset = inputController.selection.baseOffset;
    if (offset <= 0) offset = 0;
    String nickname = objectMgr.userMgr.getUserTitle(user, groupId: chat!.id);

    mentionList.add(
      MentionModel(
        userName: nickname,
        userId: user.uid,
        role: Role.none,
      ),
    );

    String atStr = '@$nickname ';

    CustomTextEditingController.mentionRange
        .add([offset, offset + atStr.length - 1]);

    inputController.text = inputController.text + atStr;

    inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: offset + atStr.length),
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
    int offset,
    List<List<int>> mentionRange,
    int appendLength,
  ) {
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
    int offset,
    List<List<int>> mentionRange,
    int deductLength,
  ) {
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

  void _onMatchLink() {
    if (ignoreLinkPreview) return;

    String text = inputController.text;
    if (oldText == text) return;
    if (text.isEmpty) {
      objectMgr.chatMgr.linkPreviewData.remove(chatId);
      update();
      return;
    }

    if (text.startsWith('H')) {
      text = text[0].toLowerCase() + text.substring(1);
    }
    final temp = Regular.extractLink(text);
    final List<String> linkList = [];
    if (temp.isNotEmpty) {
      linkList.assignAll(temp.map((match) => match.group(0)!).toList());
    }
    if (linkList.isEmpty ||
        ShareLinkUtil.isMatchShareLink(text) ||
        (assetPickerProvider != null &&
            assetPickerProvider!.selectedAssets.isNotEmpty) ||
        fileList.isNotEmpty) {
      if (linkSearchCancelToken != null) {
        linkSearchCancelToken!.cancel('Cancel By User');
        linkSearchCancelToken = null;
      }

      objectMgr.chatMgr.linkPreviewData.remove(chatId);
      update();
      return;
    }

    assert(linkList.isNotEmpty,
        "Match Link must have value. Please check [ShareLinkUtil.extractLinkFromText] method to identify Regex matching pattern.");

    const uutalkDomain = 'uutalk';
    const heytalkDomain = 'heytalk';
    const uliaoDomain = 'uliao';

    String? firstMatchedLink = linkList.firstWhereOrNull((link) =>
        !link.contains(uutalkDomain) &&
        !link.contains(heytalkDomain) &&
        !link.contains(uliaoDomain));

    if (firstMatchedLink == null) return;

    bool shouldLoadMetadata = false;
    if (objectMgr.chatMgr.linkPreviewData[chatId] == null) {
      objectMgr.chatMgr.linkPreviewData[chatId] = Metadata()
        ..url = firstMatchedLink;
      update();
      shouldLoadMetadata = true;
    }

    if (linkSearchCancelToken != null) {
      linkSearchCancelToken!.cancel('Cancel By User');
      linkSearchCancelToken = null;
    }

    linkSearchCancelToken = CancelToken();

    // 1. Compare linkList first item with MetaData variable
    linkSearchingDebounce.call(() {
      if (((objectMgr.chatMgr.linkPreviewData[chatId] != null &&
                  objectMgr.chatMgr.linkPreviewData[chatId]!.url ==
                      firstMatchedLink) &&
              !shouldLoadMetadata) ||
          (linkSearchCancelToken == null ||
              linkSearchCancelToken!.isCancelled)) {
        return;
      }

      objectMgr.chatMgr.linkPreviewData[chatId] = Metadata()
        ..url = firstMatchedLink;

      update();

      LinkAnalyzer.getInfoClientSide(
        firstMatchedLink,
        cancelToken: linkSearchCancelToken,
      ).then((metadata) async {
        if (!objectMgr.chatMgr.linkPreviewData.containsKey(chatId) ||
            (linkSearchCancelToken == null ||
                linkSearchCancelToken!.isCancelled)) return;

        if (metadata != null) {
          if (notBlank(metadata.image) && metadata.image!.startsWith('http')) {
            downloadMgrV2.download(metadata.image!);
            // downloadMgr.downloadFile(metadata.image!);
          } else {
            metadata.image = null;
          }

          if (metadata.hasData) {
            objectMgr.chatMgr.linkPreviewData[chatId] = metadata;
            update();
            return;
          }
        }
      }).whenComplete(() => linkSearchCancelToken = null);
    });
  }

  void updateLinkPreviewData(Metadata metadata) {
    if (!objectMgr.chatMgr.linkPreviewData.containsKey(chatId)) return;

    objectMgr.chatMgr.linkPreviewData[chatId] = metadata.parse();
  }

  playSendMessageSound() async {
    final canPlay = await SoundHelper().canPlaySendMessage();
    if (canPlay) {
      objectMgr.soundMgr.playSound(SoundTrackType.SoundTypeSendMessage.value);
    }
  }

  onForwardSaveMsg(
    int chatID, {
    String? caption,
    String? selectableText,
  }) async {
    if (notBlank(objectMgr.chatMgr.selectedMessageMap[chatID])) {
      for (Message item in objectMgr.chatMgr.selectedMessageMap[chatID]!) {
        if ((item.typ <= messageTypeGroupChangeInfo &&
                item.typ >= messageTypeImage) ||
            item.typ == messageTypeRecommendFriend) {
          if (caption?.isNotEmpty == true) {
            item = createMessageWithImageCaption(item, caption!);
          }
          await objectMgr.chatMgr.sendForward(
            chatID,
            item,
            item.typ,
          );
        } else {
          var contentStr = '';
          if (selectableText == null) {
            if (item.typ == messageTypeText ||
                item.typ == messageTypeReply ||
                item.typ == messageTypeReplyWithdraw) {
              MessageText textMsg = item.decodeContent(cl: MessageText.creator);
              contentStr = textMsg.text;
            } else {
              contentStr = ChatHelp.typShowMessage(chatController.chat, item);
            }
          } else {
            contentStr = selectableText;
          }

          await objectMgr.chatMgr.sendForward(
            chatID,
            item,
            messageTypeText,
            text: contentStr,
          );
        }
      }
    }
    chatController.onChooseMoreCancel();
    objectMgr.chatMgr.selectedMessageMap[chatID]?.clear();
    objectMgr.chatMgr.selectedMessageMap.remove(chatID);

    update();
  }

  Future<void> onSend(
    String? text, {
    bool isSendSticker = false,
    Sticker? sticker,
    BuildContext? context,
    bool isSendContact = false,
    User? user,
    List<AssetPreviewDetail> assets = const [],
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
      assert(
        isSendContact && context != null && user != null,
        'User and Context cannot be null',
      );
    }

    String copiedText = getMentionText(text ?? inputController.text);

    if (objectMgr.chatMgr.groupSlowMode[chatId] != null) {
      if (!objectMgr.chatMgr.groupSlowMode[chatId]?['isEnable']) {
        Group group = objectMgr.chatMgr.groupSlowMode[chatId]?['group'];
        Message message = objectMgr.chatMgr.groupSlowMode[chatId]?['message'];
        DateTime createTime =
            DateTime.fromMillisecondsSinceEpoch(message.create_time * 1000);
        Duration duration = Duration(seconds: group.speakInterval) -
            DateTime.now().difference(createTime);
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(inSlowMode, params: [getMinuteSecond(duration)]),
        );
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
            var contentStr = '';
            if (item.typ == messageTypeText ||
                item.typ == messageTypeReply ||
                item.typ == messageTypeReplyWithdraw) {
              MessageText textMsg = item.decodeContent(cl: MessageText.creator);
              contentStr = textMsg.text;
            } else {
              contentStr = ChatHelp.typShowMessage(chatController.chat, item);
            }
            final Message msgCopied = item.copyWith(null);
            await objectMgr.chatMgr.sendForward(
              chatController.chat.id,
              msgCopied,
              messageTypeText,
              text: contentStr,
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

    if (ShareLinkUtil.isMatchShareLink(text ?? '')) {
      final dataMap = ShareLinkUtil.collectDataFromUrl(text ?? '');
      if (dataMap.isNotEmpty) {
        assert(chat != null, 'Chat cannot be null');

        final uid = dataMap['uid'];
        if (uid == null) return;

        final user = objectMgr.userMgr.getUserById(uid);
        assert(user != null, 'User cannot be null');

        if (!ShareLinkUtil.isGroupShareLink(text ?? '')) {
          final link = ShareLinkUtil.generateFriendShareLink(user!.id);
          onSendFriendLink(user, link);
        } else {
          assert(text != null, 'text cannot be null');
          final gid = dataMap['gid'];
          if (gid == null) return;
          final group = await objectMgr.myGroupMgr.loadGroupById(gid);
          assert(group != null, 'Group cannot be null');
          onSendGroupLink(user!, group!, text!);
        }
        inputState = 0;
        chatController.onCancelFocus();
        clearText();
        sendState.value = false;
        return;
      }
    }

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

    if (isSendSticker) {
      sendSticker(sticker!, reply: replyData);
      inputState = 0;

      sendState.value = false;
      if (isDesktop) Get.back();
      return;
    }

    if (isSendGif) {
      sendGif(gifs!, reply: replyData);
      inputState = 0;
      sendState.value = false;
      if (isDesktop) Get.back();
      return;
    }

    TranslationModel? translationModel;
    if (chat!.isAutoTranslateOutgoing &&
        !EmojiParser.hasOnlyEmojis(copiedText) &&
        connectivityMgr.connectivityResult != ConnectivityResult.none) {
      isTranslating.value = true;
      isSending.value = true;
      Map<String, String> res = await objectMgr.chatMgr.getMessageTranslation(
        copiedText,
        locale: translateLocale.value,
      );
      if (res['translation'] != '') {
        translatedText.value = UnescapeUtil.encodedString(res['translation']!);
        translationModel = TranslationModel();
        translationModel.showTranslation = true;
        translationModel.currentLocale = translateLocale.value;
        translationModel.translation = {
          translateLocale.value: translatedText.value,
        };
        translationModel.visualType = chat!.visualTypeOutgoing;
      }
      isTranslating.value = false;
      showTranslateBar.value = false;
      translatedText.value = '';
    }

    if (!sendAsFile &&
        ((assetPickerProvider != null &&
                assetPickerProvider!.selectedAssets.isNotEmpty) ||
            assets.isNotEmpty)) {
      onSendAsset(
        assets.isNotEmpty ? assets : assetPickerProvider!.selectedAssets,
        chatId,
        caption: notBlank(copiedText) ? copiedText : null,
        reply: replyData,
        translation: translationModel,
        atUser: jsonEncode(mentionList.map((e) => e.toJson()).toList()),
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
        translation: translationModel,
      );
      clearText();
      inputState = 0;
      Get.findAndDelete<FilePickerController>();
      sendState.value = false;
      update();
      return;
    }

    if ((objectMgr.chatMgr.linkPreviewData[chatId] != null &&
            objectMgr.chatMgr.linkPreviewData[chatId]!.hasData) ||
        Regular.extractLink(copiedText).isNotEmpty) {
      sendState.value = false;
      _sendLinkText(
        copiedText,
        reply: replyData,
        translation: translationModel,
        linkPreviewData:
            (objectMgr.chatMgr.linkPreviewData[chatId]?.hasData ?? false)
                ? objectMgr.chatMgr.linkPreviewData[chatId]!.parse()
                : null,
      );
      linkSearchCancelToken?.cancel('User cancel');
      linkSearchCancelToken = null;
      inputState = 0;
      clearText();
      objectMgr.chatMgr.linkPreviewData.remove(chatId);
      update();
      return;
    }

    if (notBlank(copiedText)) {
      sendState.value = false;
      _sendText(copiedText, reply: replyData, translation: translationModel);
      update();
    }
    sendState.value = false;
    clearText();
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
      TranslationModel? translationModel;
      if (showTranslateBar.value && notBlank(translatedText.value)) {
        translationModel = TranslationModel();
        translationModel.showTranslation = true;
        translationModel.currentLocale = translateLocale.value;
        translationModel.translation = {
          translateLocale.value: translatedText.value,
        };
        translationModel.visualType = chat!.visualTypeOutgoing;
      }
      showTranslateBar.value = false;
      translatedText.value = '';
      await objectMgr.chatMgr.sendVoice(
        chatId,
        vm.path,
        0,
        2,
        vm.second,
        notBlank(replyData) ? jsonEncode(replyData) : null,
        translationModel != null ? jsonEncode(translationModel) : null,
        data: vm,
      );
      update();

      await playSendMessageSound();

      // VolumeRecordService.sharedInstance.notifyOthersDeactivation();
    }
  }

  void sendSticker(
    Sticker sticker, {
    ReplyModel? reply,
  }) async {
    objectMgr.chatMgr.sendStickers(
      chatID: chatId,
      sticker: sticker,
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
    // 打个补丁，修复最近使用Gif脏数据导致消息列表滚动鬼畜
    if (gifs.width == 0 || gifs.height == 0) {
      gifs = await adjustGifDimensionByGif(gifs);
    }

    objectMgr.chatMgr.sendGif(
      chatID: chatId,
      name: gifs.name,
      data: gifs.path,
      width: gifs.width.toInt(),
      height: gifs.height.toInt(),
      reply: reply != null ? jsonEncode(reply) : null,
    );
    update();
    await playSendMessageSound();
    if (objectMgr.loginMgr.isDesktop) {
      Get.back();
    }
  }

  void _sendLinkText(
    String text, {
    ReplyModel? reply,
    TranslationModel? translation,
    Metadata? linkPreviewData,
  }) async {
    if (!chatController.linkEnable) {
      Toast.showToast(localized(errorBlockPermissionRestrict));

      inputController.text = inputController.text;
      sendState.value = true;
      return;
    }

    if (linkPreviewData == null) {
      final temp = Regular.extractLink(text);
      final List<String> matchedLink = [];
      if (temp.isNotEmpty) {
        matchedLink.assignAll(temp.map((match) => match.group(0)!).toList());
        String title = matchedLink.first;
        if (!title.startsWith('http')) {
          title = 'http://$title';
        }
        linkPreviewData = Metadata()..url = title;
      }
    }

    await objectMgr.chatMgr.sendLinkText(
      chatId,
      text.replaceAll(RegExp(r'\u200B'), ''),
      linkPreviewData: linkPreviewData,
      reply: reply != null ? jsonEncode(reply) : null,
      atUser: jsonEncode(mentionList.map((e) => e.toJson()).toList()),
      translation: translation != null ? jsonEncode(translation) : null,
    );
    await playSendMessageSound();
  }

  void _sendText(
    String text, {
    ReplyModel? reply,
    TranslationModel? translation,
  }) async {
    await objectMgr.chatMgr.sendText(
      chatId,
      text.replaceAll(RegExp(r'\u200B'), ''),
      reply: reply != null ? jsonEncode(reply) : null,
      atUser: jsonEncode(mentionList.map((e) => e.toJson()).toList()),
      translation: translation != null ? jsonEncode(translation) : null,
    );
  }

  Future<void> onSendEditMessage(String text) async {
    if (notBlank(objectMgr.chatMgr.editMessageMap[chatId])) {
      try {
        Message? editMessage =
            objectMgr.chatMgr.editMessageMap[chatId]?.copyWith(null);
        final linkPreviewData = objectMgr.chatMgr.linkPreviewData[chatId];
        objectMgr.chatMgr.editMessageMap.remove(chatId);
        clearText();
        update();

        if (editMessage != null) {
          String sendText = getMentionText(
            text,
            atUserHistory: mentionList,
          );
          final messageContent = jsonDecode(editMessage.content);

          if (sendText ==
              (messageContent['caption'] ?? messageContent['text'])) {
            return;
          }

          TranslationModel? translationModel =
              editMessage.getTranslationModel();
          if ((chat!.isAutoTranslateOutgoing ||
                  (translationModel != null &&
                      translationModel.showTranslation)) &&
              !EmojiParser.hasOnlyEmojis(sendText) &&
              connectivityMgr.connectivityResult != ConnectivityResult.none) {
            Map<String, String> res =
                await objectMgr.chatMgr.getMessageTranslation(
              sendText,
              locale: translateLocale.value,
            );
            if (res['translation'] != '') {
              translatedText.value =
                  UnescapeUtil.encodedString(res['translation']!);
              translationModel = TranslationModel();
              translationModel.showTranslation = true;
              translationModel.currentLocale = translateLocale.value;
              translationModel.translation = {
                translateLocale.value: translatedText.value,
              };
              translationModel.visualType = chat!.visualTypeOutgoing;
            }

            showTranslateBar.value = false;
            translatedText.value = '';

            messageContent['translation'] = jsonEncode(translationModel);
          }

          if (messageContent.containsKey('text')) {
            messageContent['text'] = sendText;
          } else if (messageContent.containsKey('caption')) {
            messageContent['caption'] = sendText;
          }

          if (messageContent.containsKey('link_metadata') &&
              linkPreviewData != null &&
              linkPreviewData.hasData) {
            messageContent['link_metadata'] = linkPreviewData;

            if (linkPreviewData.image?.isNotEmpty ?? false) {
              await _onEditMessageLinkUpload(
                messageContent,
                linkPreviewData,
              );
            }
          } else {
            messageContent.remove('link_metadata');
          }

          chat_api.editMsg(
            chatId,
            editMessage.chat_idx,
            editMessage.message_id,
            jsonEncode(messageContent),
            jsonEncode(mentionList.map((e) => e.toJson()).toList()),
            chat!.typ,
            (chat!.flag & ChatEncryptionFlag.encrypted.value),
            chat!.activeChatKey,
            chat!.activeKeyRound,
            chat!.isGroup,
            chat!.friend_id,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _onEditMessageLinkUpload(
    Map<String, dynamic> content,
    Metadata metadata,
  ) async {
    final String width, height;

    final imagePath = downloadMgr.getSavePath(metadata.image!);
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      metadata.image = null;
      metadata.imageWidth = null;
      metadata.imageHeight = null;
      content['link_metadata'] = metadata;
      return;
    }

    if (metadata.imageWidth == null || metadata.imageHeight == null) {
      final (w, h) = await imageMgr.getImageSize(metadata.image!);

      width = w.toString();
      height = h.toString();
    } else {
      width = metadata.imageWidth!;
      height = metadata.imageHeight!;
    }

    metadata.imageWidth = width;
    metadata.imageHeight = height;

    if (width.isEmpty || height.isEmpty) {
      metadata.image = null;
      metadata.imageWidth = null;
      metadata.imageHeight = null;
    } else {
      final imagePath = await imageMgr.upload(
        imageFile.path,
        int.parse(width),
        int.parse(height),
        cancelToken: CancelToken(),
        onGaussianComplete: (String gausPath) =>
            content['link_image_src_gaussian'] = gausPath,
      );

      content['link_image_src'] = imagePath;
    }
  }

  void clearText() {
    mentionList.clear();
    CustomTextEditingController.mentionRange.clear();
    inputController.clear();
    showTranslateBar.value = false;
    translatedText.value = '';
    isSending.value = false;
  }

  String getMentionText(
    String copiedText, {
    List<MentionModel>? atUserHistory,
  }) {
    if (notBlank(atUserHistory)) {
      for (int i = 0; i < atUserHistory!.length; i++) {
        MentionModel model = atUserHistory[i];
        copiedText = copiedText.replaceFirst(
          '@${model.userName}',
          '\u214F\u2983${model.userId}@jx\u2766\u2984',
        );
      }
      return copiedText;
    }

    List<List<int>> range = CustomTextEditingController.mentionRange;

    if (copiedText.isNotEmpty &&
        inputController.text.isNotEmpty &&
        copiedText[0] != inputController.text[0] &&
        copiedText.length < inputController.text.length &&
        range.isNotEmpty) {
      final diff = inputController.text.length - copiedText.length;

      for (int i = 0; i < range.length; i++) {
        deductMentionListIndex(
          0,
          range,
          diff,
        );
      }
    }

    for (int i = range.length - 1; i >= 0; i--) {
      final List<int> item = range[i];
      if (item.first < copiedText.length && item.last <= copiedText.length) {
        String nameText = copiedText.substring(item.first + 1, item.last);
        MentionModel? model = mentionList
            .firstWhereOrNull((element) => element.userName == nameText);

        if (model != null) {
          copiedText = copiedText.replaceRange(
            item.first,
            item.last,
            '\u214F\u2983${model.userId}@jx\u2766\u2984',
          );
        }
      }
    }
    return copiedText;
  }

  Future<void> onForwardMessage({
    bool fromChatInfo = false,
    bool fromMediaDetail = false,
    String? selectableText,
    BuildContext? context,
  }) async {
    if (objectMgr.loginMgr.isDesktop) {
      desktopGeneralDialog(
        Get.context!,
        widgetChild: ForwardContainer(
          chat: chatController.chat,
          selectableText: selectableText,
          forwardMsg: chatController.chooseMessage.values
              .map((e) => e.copyWith(null))
              .toList()
            ..sort((a, b) => a.chat_idx.compareTo(b.chat_idx)),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context ?? Get.context!,
        isDismissible: true,
        isScrollControlled: true,
        barrierColor: colorOverlay40,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return ForwardContainer(
            chat: chatController.chat,
            selectableText: selectableText,
            forwardMsg: chatController.chooseMessage.values
                .map((e) => e.copyWith(null))
                .toList()
              ..sort((a, b) => a.chat_idx.compareTo(b.chat_idx)),
          );
        },
      ).whenComplete(() {
        chatController.chooseMessage.clear();
        chatController.chooseMore.value = false;
      });
    }
  }

  Future<void> deleteMessages(
    List<Message> messages,
    int chatId, {
    bool isAll = false,
    bool isFromChatRoom = false,
  }) async {
    List<Message> remoteMessages = [];
    List<int> remoteMessageIds = [];
    List<Message> fakeMessages = [];
    List<Message> floatingPIPCheckMessages = [];

    for (var message in messages) {
      if (message.typ == messageTypeNewAlbum ||
          message.typ == messageTypeReel ||
          message.typ == messageTypeVideo) {
        floatingPIPCheckMessages.add(message);
      }

      if (message.message_id == 0) {
        fakeMessages.add(message);
      } else {
        remoteMessages.add(message);
        remoteMessageIds.add(message.message_id);
      }
    }

    if (floatingPIPCheckMessages.isNotEmpty) {
      objectMgr.tencentVideoMgr
          .checkForFloatingPIPClosure(floatingPIPCheckMessages);
    }

    if (fakeMessages.isNotEmpty) {
      for (int i = 0; i < fakeMessages.length; i++) {
        objectMgr.chatMgr.localDelMessage(fakeMessages[i]);
      }
    }

    if (remoteMessages.isNotEmpty) {
      chat_api.deleteMsg(
        chatId,
        remoteMessageIds,
        isAll: isAll,
      );

      for (var message in remoteMessages) {
        objectMgr.chatMgr.localDelMessage(message);
      }
    }

    if (isMobile) {
      if (isFromChatRoom) {
        Get.back();
        imBottomToast(
          Get.context!,
          title: localized(toastDeleteMessageSuccess),
          icon: ImBottomNotifType.delete,
        );
      } else {
        imBottomToast(
          Get.context!,
          title: localized(toastDeleteMessageSuccess),
          icon: ImBottomNotifType.delete,
        );
      }
    } else {
      imBottomToast(
        Get.context!,
        icon: ImBottomNotifType.custom,
        customIcon: const CustomImage(
          'assets/svgs/delete2_icon.svg',
          size: 18,
        ),
        title: localized(deletedSuccess),
      );
    }
  }

  Future<void> cancelMessages(
    List<Message> messages,
    int chatId, {
    bool isAll = false,
  }) async {
    List<Message> remoteMessages = [];
    List<int> remoteMessageIds = [];
    List<Message> fakeMessages = [];

    for (var message in messages) {
      if (message.message_id == 0) {
        message.sendState = MESSAGE_SEND_FAIL;
        fakeMessages.add(message);
      } else {
        remoteMessages.add(message);
        remoteMessageIds.add(message.message_id);
      }
    }

    if (fakeMessages.isNotEmpty) {
      for (int i = 0; i < fakeMessages.length; i++) {
        objectMgr.chatMgr.localDelMessage(fakeMessages[i]);
      }
    }

    if (remoteMessages.isNotEmpty) {
      chat_api.deleteMsg(
        chatId,
        remoteMessageIds,
        isAll: isAll,
      );

      for (var message in remoteMessages) {
        objectMgr.chatMgr.localDelMessage(message);
      }
    }

    if (isMobile) {
      imBottomToast(
        Get.context!,
        title: localized(toastCancelSuccess),
        icon: ImBottomNotifType.success,
      );
    }
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
      imBottomToast(
        Get.context!,
        title: localized(actionCannotBePerformed),
        icon: ImBottomNotifType.warning,
        duration: 1,
      );
      return;
    }

    unawaited(deleteMessages(messageList, chatId, isAll: isAll));

    chatController.onChooseMoreCancel();
  }

  onCancelSendingMessage(
    BuildContext context,
    List<Message> messages, {
    bool isMore = false,
    bool isAll = false,
  }) async {
    if (!isMore && messages.length != 1) {
      return;
    }

    if (isDesktop) {
      await cancelMessages(messages, chatId, isAll: isAll);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: localized(chatOptionsCancelSend),
            content: Text(
              isAll
                  ? localized(chatInfoThisMessageWillBeCanceledForAllReceipts)
                  : localized(
                      chatInfoThisMessageWillBeDeletedFromYourMessageHistory,
                    ),
              style: jxTextStyle.textDialogContent(),
              textAlign: TextAlign.center,
            ),
            confirmText: localized(buttonYes),
            cancelText: localized(buttonNo),
            confirmCallback: () async {
              if (isMore) {
                onChooseMessageDelete(messageList: messages, isAll: isAll);
              } else {
                bool canCancel = true;
                for (Message message in messages) {
                  if (message.sendState == MESSAGE_SEND_SUCCESS) {
                    canCancel = false;
                    break;
                  }
                }
                if (canCancel) {
                  await cancelMessages(messages, chatId, isAll: isAll);
                }
              }
            },
          );
        },
      );
    }
  }

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
      chatController.onChooseMoreCancel();
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
                      chatInfoThisMessageWillBeDeletedFromYourMessageHistory,
                    ),
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
    Map<String, dynamic> replyData = jsonDecode(message.content);
    final replyModel = await getReplyModel(sendId, message, replyData);
    objectMgr.chatMgr.replyMessageMap[chat.id] = replyModel;
    objectMgr.chatMgr.editMessageMap.remove(chat.id);
    objectMgr.chatMgr.selectedMessageMap.remove(chat.id);
    Future.delayed(const Duration(milliseconds: 100), () {
      inputFocusNode.requestFocus();
    });
    update();

    isVoiceMode.value = false;
    // inputController.text = '';
    chatController.isSearching.value = false;
    chatController.resetPopupWindow();
  }

  void onEdit(int sendId, Message message, Chat chat) async {
    Map<String, dynamic> replyData = jsonDecode(message.content);
    final replyModel = await getReplyModel(sendId, message, replyData);

    objectMgr.chatMgr.editMessageMap[chat.id] = Message().copyWith(message);

    objectMgr.chatMgr.replyMessageMap.remove(chat.id);
    objectMgr.chatMgr.selectedMessageMap.remove(chat.id);

    Future.delayed(const Duration(milliseconds: 100), () {
      inputFocusNode.requestFocus();
    });
    update();
    isVoiceMode.value = false;
    inputController.text = ChatHelp.formalizeMentionContent(
      replyModel.text,
      message,
    );

    if (message.atUser.isNotEmpty) {
      final List<String> aliasNameList = [];
      for (final mention in message.atUser) {
        final user = objectMgr.userMgr.getUserById(mention.userId);
        if (user?.id == 0) {
          user?.nickname = localized(mentionAll);
        }
        if (chatController is GroupChatController) {
          final aliasName = objectMgr.userMgr.getUserTitle(
            user,
            groupId: (chatController as GroupChatController).group.value?.id,
          );
          aliasNameList.add(aliasName);

          final oriName = objectMgr.userMgr.getUserTitle(user);

          if (aliasName.isNotEmpty) {
            inputController.text = inputController.text.replaceFirst(
              oriName,
              aliasName,
            );
          }
        }
      }

      CustomTextEditingController.mentionRange.clear();
      mentionList.clear();
      int accumulatedOffset = 0;
      for (int i = 0; i < message.atUser.length; i++) {
        final mention = message.atUser[i];
        final aliasName = aliasNameList[i];

        final user = User()
          ..uid = mention.userId
          ..username = aliasName.isNotEmpty ? aliasName : mention.userName
          ..nickname = aliasName.isNotEmpty ? aliasName : mention.userName;

        accumulatedOffset += prepopulateMentionUser(
          user,
          isAll: user.uid == 0,
          newOffset: accumulatedOffset,
        );
      }
    }

    chatController.resetPopupWindow();
  }

  Future<ReplyModel> getReplyModel(
    int sendId,
    Message message,
    Map<String, dynamic> replyData,
  ) async {
    final replyModel = ReplyModel();
    if (replyData.containsKey('reply')) {
      replyData.remove('reply');
    }

    final User? user = await objectMgr.userMgr.loadUserById(sendId);
    replyModel.id = message.id;
    replyModel.messageId = message.message_id;
    replyModel.chatIdx = message.chat_idx;
    replyModel.userId = message.isCalling ? replyData['inviter'] : sendId;

    replyModel.cmid = message.cmid;

    replyModel.nickName = user?.nickname ?? '';
    replyModel.typ = message.isCalling ? messageTypeText : message.typ;

    replyModel.atUser = message.atUser;

    switch (message.typ) {
      case messageTypeVideo:
      case messageTypeReel:
        replyModel.url = replyData['cover'] ?? '';
        replyModel.urlGaus = replyData['gausPath'] ?? '';
        replyModel.filePath = replyData['coverPath'] ?? '';
        replyModel.text = replyData['caption'] ?? replyData['text'] ?? '';
        break;
      case messageTypeImage:
      case messageTypeLocation:
      case messageTypeFace:
      case messageTypeGif:
      case messageTypeFile:
        replyModel.url = replyData['url'] ?? '';
        replyModel.urlGaus = replyData['gausPath'] ?? '';
        replyModel.filePath =
            replyData['coverPath'] ?? replyData['filePath'] ?? '';
        replyModel.text = replyData['caption'] ?? replyData['text'] ?? '';
        break;
      case messageTypeNewAlbum:
        NewMessageMedia media = NewMessageMedia()..applyJson(replyData);
        replyModel.url =
            (media.albumList?.first.mimeType?.contains('video') ?? false)
                ? media.albumList?.first.cover ?? ''
                : media.albumList?.first.url ?? '';
        replyModel.urlGaus = media.albumList?.first.gausPath ?? '';
        replyModel.filePath = media.albumList?.first.coverPath ?? '';
        replyModel.text = media.caption;
        break;

      case messageTypeLink:
        final MessageLink msgContent = MessageLink()..applyJson(replyData);
        replyModel.url = msgContent.linkImageSrc;
        replyModel.urlGaus = msgContent.linkImageSrcGaussian;
        replyModel.text = msgContent.text;
        break;

      default:
        replyModel.text = replyData['text'] ?? '';
        break;
    }

    if (message.isCalling) {
      replyData['text'] = ChatHelp.callMsgContent(message);
    }

    return replyModel;
  }

  /// 新逻辑

  openVideoScreen(bool value) {
    if (Get.isRegistered<SingleChatController>()) {
      SingleChatController viewController =
          Get.find<SingleChatController>(tag: chatId.toString());
      viewController.showVideoScreen(value);
    } else {
      GroupChatController viewController =
          Get.find<GroupChatController>(tag: chatId.toString());
      viewController.showVideoScreen(value);
    }
  }

  void toggleVoiceMode() {
    chatController.removeShortcutImage();
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
    recorderOverlayEntry?.remove();
    recorderOverlayEntry = null;
    onTapRelease = false;
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCall));
      return;
    }
    if (Platform.isIOS || Platform.isAndroid) {
      bool inUse = await objectMgr.sysOprateMgr.isMicrophoneInUse();
      if (inUse) {
        Toast.showToast(localized(toastEndCall));
        return;
      }
    }

    playerService.pausePlayer();

    var status = await Permissions.request([Permission.microphone]);
    if (status) {
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
    BuildContext context,
    LongPressMoveUpdateDetails detail,
  ) {
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
      isDeleteSelected.value = true;
      isLockedSelected.value = false;
    } else if (rightXPositionRange && yPositionRange) {
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
        WakeLockUtils.enable();
      } else {
        toggleRecordingState(false, shouldSend);
      }
    });
  }

  void toggleRecordingState(bool record, bool shouldSend) {
    if (record == true) {
      objectMgr.tencentVideoMgr.pauseAllControllers();
    }
    if (!shouldSend) {
      isDeleteSelected.value = true;
      vibrate();
    }
    isRecording.value = record;
  }

  void showBottomPopup(
    BuildContext context, {
    required String tag,
    required MediaOption mediaOption,
  }) async {
    final controller = Get.find<CustomInputController>(tag: tag);
    bool permissionStatus = false;
    try {
      if (mediaOption == MediaOption.gallery ||
          mediaOption == MediaOption.document) {
        permissionStatus = await controller.onPrepareMediaPicker(
            maxAssets: mediaOption == MediaOption.document ? 10 : null,
            showToast: false);
      }
      controller.inputFocusNode.unfocus();
    } on StateError {
      permissionStatus = false;
    }

    showModalBottomSheet(
      context: context,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height - 22,
          child: MediaSelectorView(
            tag,
            permissionStatus,
            mediaOption: mediaOption,
          ),
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

  void onAudioRecordingCancel() {
    sendState.value = false;
  }

  Future<bool> onPrepareMediaPicker(
      {int? maxAssets, bool showToast = true}) async {
    ps = await requestAssetPickerPermission(showToast: showToast);
    if (ps == PermissionState.denied) return false;

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
      maxAssets: maxAssets ??
          (notBlank(objectMgr.chatMgr.replyMessageMap[chatId])
              ? 1
              : defaultMaxAssetsCount),
      textDelegate: Get.locale!.languageCode.contains('en')
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
    return true;
  }

  onAssetPickerChanged() async {
    if (assetPickerProvider!.selectedAssets.isNotEmpty || fileList.isNotEmpty) {
      sendState.value = true;
    } else {
      sendState.value = false;
    }

    if (selectedAssetList.length !=
        assetPickerProvider!.selectedAssets.length) {
      // 移除 被移除的Asset的压缩Map
      if (selectedAssetList.length >=
          assetPickerProvider!.selectedAssets.length) {
        final Set<String> diffListId = selectedAssetList
            .map((e) => e.id)
            .toSet()
            .difference(
                assetPickerProvider!.selectedAssets.map((e) => e.id).toSet());

        if (diffListId.isNotEmpty) {
          compressedSelectedAsset.removeWhere((key, value) {
            if (diffListId.contains(key)) {
              File(value).delete();
              return true;
            }
            return false;
          });
        }
      } else {
        // 提前压缩 , 找出没在Map压缩过的Asset进行压缩
        final Set<String> diffListId = assetPickerProvider!.selectedAssets
            .map((e) => e.id)
            .toSet()
            .difference(selectedAssetList.map((e) => e.id).toSet());

        if (diffListId.isNotEmpty) {
          final entity = assetPickerProvider!.selectedAssets
              .firstWhereOrNull((element) => element.id == diffListId.first);

          if (entity != null) _preCompressAsset(entity);
        }
      }

      selectedAssetList.value = assetPickerProvider!.selectedAssets;
    }
  }

  void _preCompressAsset(AssetEntity entity) async {
    if (entity.type != AssetType.image) return;

    final file = await entity.originFile;
    if (file == null) return;

    // 获取压缩以后的上传尺寸
    Size fileSize = getResolutionSize(
      entity.orientatedWidth,
      entity.orientatedHeight,
      MediaResolution.image_standard.minSize,
    );

    final compressedImage = await imageMgr.compressImage(
      file.path,
      fileSize.width.toInt(),
      fileSize.height.toInt(),
    );

    if (compressedImage == null) return;

    compressedSelectedAsset[entity.id] = compressedImage;
  }

  onPhoto(BuildContext context) async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    chatController.playerService.pausePlayer();
    // chatController.playerService.resetPlayer();

    // 这里需要三个权限， 相机，麦克风和储存
    var c = await Permissions.request(
        [Permission.camera, Permission.microphone],
        subTitle: localized(callAccessDetail));
    if (!c) return;

    var e = await onPrepareMediaPicker();
    if (!e) return;

    AssetEntity? entity;
    if (await isUseImCamera) {
      entity = await CamerawesomePage.openImCamera(
          enableRecording: true,
          maximumRecordingDuration: const Duration(seconds: 600),
          manualCloseOnSuccess: true,
          isMirrorFrontCamera: isMirrorFrontCamera);
      if (entity == null) {
        return;
      }
      // newly added photo does not count
      objectMgr.chatMgr.lastCheckedTime = DateTime.now();
      gotoMediaPreviewView(entity, context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => CamerawesomePage(
            enableRecording: true,
            maximumRecordingDuration: const Duration(seconds: 600),
            onResult: (Map<String, dynamic> map) {
              if (map == null) {
                return;
              }
              entity = map["result"];
              if (entity == null) {
                return;
              }
              gotoMediaPreviewView(entity!, context, isFromPhoto: true);
            },
          ),
        ),
      );
    }
  }

  void gotoMediaPreviewView(
    AssetEntity? entity,
    BuildContext context, {
    bool isFromPhoto = false,
  }) async {
    Get.toNamed(
      RouteName.mediaPreviewView,
      preventDuplicates: false,
      arguments: {
        'isEdit': true,
        'entity': entity,
        'provider': assetPickerProvider,
        'pConfig': pickerConfig,
        'caption': inputController.text,
        'chat': chat,
        "isFromPhoto": isFromPhoto,
        'backAction': () async {
          if (await isUseImCamera) onPhoto(context);
        },
      },
    )?.then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          assetPickerProvider?.selectedAssets.clear();
          sendState.value = false;
          return;
        }

        if (result['translation'] != null) {
          translatedText.value = result['translation'];
        }

        onSend(
          result?['caption'],
          assets: result != null
              ? (result['assets'] ?? <AssetPreviewDetail>[])
              : <AssetPreviewDetail>[],
        ).then((_) {
          assetPickerProvider?.selectedAssets.clear();
        });
        return;
      } else {}

      assetPickerProvider?.selectedAssets.clear();
      sendState.value = false;
      return;
    });
  }

  void onSendAsset(
    List<dynamic> assets,
    int chatID, {
    String? caption,
    ReplyModel? reply,
    TranslationModel? translation,
    String? atUser,
  }) async {
    if (assets.isEmpty) {
      return;
    }

    List<dynamic> assetsCopy = List.from(assets);

    List<dynamic> exceedLimitAssets = [];
    if (assetsCopy.length > 1) {
      for (int i = 0; i < List.from(assetsCopy).length; i++) {
        final asset = assetsCopy[i];

        final int duration;
        final int fileLength;
        if (asset is AssetEntity) {
          if (asset.type == AssetType.image) {
            // 如果发现已经压缩过图片了, 把assetsCopy[i] 转换成AssetPreviewDetail, 把压缩过的文件存入到editedFile里
            if (compressedSelectedAsset.containsKey(asset.id)) {
              assetsCopy[i] = AssetPreviewDetail(
                id: asset.id,
                index: i,
                entity: asset,
                caption: '',
              )
                ..editedFile = File(compressedSelectedAsset[asset.id]!)
                ..editedHeight = asset.orientatedHeight
                ..editedWidth = asset.orientatedWidth
                ..isCompressed = true;
            }

            continue;
          }

          duration = asset.duration;
          final file = await asset.originFile;
          fileLength = file?.lengthSync() ?? 0;
        } else if (asset is AssetPreviewDetail) {
          if (asset.entity.type == AssetType.image) {
            if (asset.imageResolution == MediaResolution.image_high) {
              asset.editedFile = null;
              asset.editedWidth = null;
              asset.editedHeight = null;
              asset.isCompressed = false;
            }
            continue;
          }

          fileLength = asset.editedFile?.lengthSync() ??
              (await asset.entity.originFile)!.lengthSync();
          duration = asset.entity.duration;
        } else {
          duration = 0;
          fileLength = asset.lengthSync();
        }

        if (duration > 30 * 60 || fileLength > 1 * 1024 * 1024 * 1024) {
          assetsCopy.removeAt(i);
          exceedLimitAssets.add(asset);
        }
      }
    }

    if (assetsCopy.length > ChatHelp.imageNumLimit) {
      List<List<dynamic>> list =
          ChatHelp.splitList<dynamic>(assetsCopy, ChatHelp.imageNumLimit);
      for (int i = 0; i < list.length; i++) {
        Future.delayed(
          Duration(milliseconds: 30 * i),
          () => ChatHelp.onSplitImageOrVideo(
            assets: list[i],
            caption: caption,
            chat: chatController.chat,
            reply: reply != null ? jsonEncode(reply) : null,
            translation: translation != null ? jsonEncode(translation) : '',
            atUser: atUser ?? '',
          ),
        );
      }

      if (exceedLimitAssets.isNotEmpty) {
        for (final asset in exceedLimitAssets) {
          _onSendFile(
            asset,
            chatID,
            caption: caption,
            reply: reply,
            translation: translation != null ? jsonEncode(translation) : '',
          );

          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      return;
    } else if (assetsCopy.length > 1) {
      ChatHelp.onSplitImageOrVideo(
        assets: assetsCopy,
        caption: caption,
        chat: chatController.chat,
        reply: reply != null ? jsonEncode(reply) : null,
        translation: translation != null ? jsonEncode(translation) : '',
        atUser: atUser ?? '',
      );

      if (exceedLimitAssets.isNotEmpty) {
        for (final asset in exceedLimitAssets) {
          await _onSendFile(
            asset,
            chatID,
            caption: caption,
            reply: reply,
            translation: translation != null ? jsonEncode(translation) : '',
          );
        }
      }
    } else {
      if (assetsCopy.first is AssetPreviewDetail) {
        final AssetPreviewDetail asset = assetsCopy.first;
        if (asset.entity.type == AssetType.video) {
          onSendSingleVideo(
            asset.entity,
            caption,
            resolution: asset.videoResolution,
            reply: reply,
            translation: translation != null ? jsonEncode(translation) : '',
            atUser: atUser ?? '',
          );
        } else {
          if (asset.editedFile != null) {
            ChatHelp.sendImageFile(
              asset.editedFile!,
              chat!,
              width: asset.editedWidth ?? 0,
              height: asset.editedHeight ?? 0,
              caption: caption,
              resolution: asset.imageResolution,
              reply: reply != null ? jsonEncode(reply) : null,
              translation: translation != null ? jsonEncode(translation) : '',
              atUser: atUser ?? '',
            );
          } else {
            onSendSingleImage(
              asset.entity,
              caption,
              resolution: asset.imageResolution,
              reply: reply,
              translation: translation != null ? jsonEncode(translation) : '',
              atUser: atUser ?? '',
            );
          }
        }
      } else {
        if (assetsCopy.first.type == AssetType.video) {
          onSendSingleVideo(
            assetsCopy.first,
            caption,
            reply: reply,
            translation: translation != null ? jsonEncode(translation) : '',
            atUser: atUser ?? '',
          );
        } else {
          onSendSingleImage(
            assetsCopy.first,
            caption,
            reply: reply,
            translation: translation != null ? jsonEncode(translation) : '',
            atUser: atUser ?? '',
          );
        }
      }
    }

    await playSendMessageSound();
  }

  Future<void> onSendSingleVideo(
    AssetEntity asset,
    String? caption, {
    MediaResolution resolution = MediaResolution.video_standard,
    ReplyModel? reply,
    String atUser = '',
    String? translation,
  }) async {
    assetPickerProvider?.selectedAssets = [];

    final status = await checkShouldSendAsFile(
      asset,
      caption,
      reply: reply,
      resolution: resolution,
      translation: translation,
    );

    if (status) return;

    await ChatHelp.sendVideoAsset(
      asset,
      chatController.chat,
      caption,
      resolution: resolution,
      reply: reply != null ? jsonEncode(reply) : null,
      translation: translation,
    );

    update();
  }

  Future<void> onSendSingleImage(
    AssetEntity asset,
    String? caption, {
    ReplyModel? reply,
    MediaResolution resolution = MediaResolution.image_standard,
    String? translation,
    String atUser = '',
  }) async {
    assetPickerProvider?.selectedAssets = [];

    ChatHelp.sendImageAsset(
      asset,
      chatController.chat,
      caption: caption,
      resolution: resolution,
      reply: reply != null ? jsonEncode(reply) : null,
      translation: translation,
      atUser: atUser,
    );

    update();
  }

  Future<bool> checkShouldSendAsFile(
    dynamic asset,
    String? caption, {
    int? duration,
    ReplyModel? reply,
    MediaResolution resolution = MediaResolution.image_standard,
    String? translation,
  }) async {
    final int duration0;
    final int fileLength;
    if (asset is AssetEntity) {
      duration0 = duration ?? asset.duration;
      final file = await asset.originFile;
      fileLength = file?.lengthSync() ?? 0;
    } else {
      duration0 = duration ?? 0;
      fileLength = asset.lengthSync();
    }

    if (duration0 > 30 * 60) {
      _onSendFile(
        asset,
        chat?.id,
        caption: caption,
        reply: reply,
        translation: translation,
      );
      update();
      return true;
    }

    if (fileLength > 1 * 1024 * 1024 * 1024) {
      _onSendFile(
        asset,
        chat?.id,
        caption: caption,
        reply: reply,
        translation: translation,
      );
      update();
      return true;
    }

    return false;
  }

  onSendFile(
    int chatID, {
    String? caption,
    List<AssetPreviewDetail> assets = const [],
    bool sendAsFile = false,
    ReplyModel? reply,
    TranslationModel? translation,
  }) async {
    List<File> duplicateFile = [];
    final List<dynamic> pathListCopy = List.from(fileList);

    if (assets.isNotEmpty) {
      pathListCopy.addAll(List.from(assets));
    } else if (assetPickerProvider!.selectedAssets.isNotEmpty) {
      pathListCopy.addAll(List.from(assetPickerProvider!.selectedAssets));
    }

    for (final element in pathListCopy) {
      try {
        _onSendFile(
          element,
          chatID,
          caption: caption,
          reply: reply,
          translation: translation != null ? jsonEncode(translation) : '',
        );

        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        duplicateFile.add(element);
      }
    }

    if (duplicateFile.isNotEmpty) {
      Toast.showToast(
          '${duplicateFile.map((e) => pp.basename(e.path)).toList()} ${localized(errorSelectedFileSend)}');
    }

    fileList.clear();
    update();
    await playSendMessageSound();
  }

  Future<void> _onSendFile(
    dynamic element,
    int chatID, {
    String? caption,
    ReplyModel? reply,
    String? translation,
  }) async {
    int length = 0;
    File file;
    int? width;
    int? height;
    String? assetId;
    if (element is AssetPreviewDetail) {
      length = element.editedFile != null
          ? element.editedFile!.lengthSync()
          : (await element.entity.originFile)?.lengthSync() ?? 0;

      file = element.editedFile ?? (await element.entity.originFile)!;
      width = element.editedWidth ?? element.entity.orientatedWidth;
      height = element.editedHeight ?? element.entity.orientatedHeight;
      assetId = element.entity.id;
    } else if (element is AssetEntity) {
      length = (await element.originFile)?.lengthSync() ?? 0;
      file = (await element.originFile)!;
      width = element.orientatedWidth;
      height = element.orientatedHeight;
      assetId = element.id;
    } else {
      length = element.lengthSync();
      file = element;
    }

    objectMgr.chatMgr.sendFile(
      data: file,
      length: length,
      chatID: chatID,
      fileName: pp.basename(file.path),
      suffix: pp.extension(file.path),
      width: width,
      height: height,
      caption: caption ?? '',
      reply: reply != null ? jsonEncode(reply) : null,
      translation: translation ?? '',
      assetId: assetId,
    );
  }

  setAutoDeleteMsgInterval(int seconds) {
    chatController.chat.autoDeleteInterval = seconds;
    autoDeleteInterval.value = chatController.chat.autoDeleteInterval;
  }

  Future<void> pasteImage(BuildContext context) async {
    final bytes = await Pasteboard.image;
    final filePaths = await Pasteboard.files();

    if (bytes != null && filePaths.isEmpty) {
      final XFile image = await saveImageToXFile(bytes);
      String fileExtension = getFileExtension(image.path);
      if (imageExtension.contains(fileExtension)) {
        showAttachFileDialog(context, [image]);
      }
      return;
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

  void showAttachFileDialog(
    BuildContext context,
    List<XFile> files, [
    FileType fileType = FileType.image,
  ]) {
    desktopGeneralDialog(
      context,
      widgetChild: AttachFileDialog(
        title: fileType == FileType.image
            ? 'Image'
            : fileType == FileType.video
                ? 'Video'
                : 'File',
        file: files,
        chatId: chatId,
        fileType: fileType,
      ),
    );
  }

  Widget stickerOptionTile(
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

  Future<void> onSendFriendLink(User user, String shortLink) async {
    objectMgr.chatMgr.sendFriendLink(
      chatController.chat.chat_id,
      user.id,
      user.nickname,
      user.profileBio,
      shortLink,
    );
    await playSendMessageSound();
  }

  Future<void> onSendGroupLink(User user, Group group, String shortLink) async {
    objectMgr.chatMgr.sendGroupLink(
      chatController.chat.chat_id,
      user.id,
      user.nickname,
      group.id,
      group.name,
      group.profile,
      shortLink,
    );
    await playSendMessageSound();
  }

  void addEmoji(String emoji) {
    inputController.text = inputController.text + emoji;

    objectMgr.stickerMgr.updateRecentEmoji(emoji);
  }

  onOpenFace() {
    chatController.removeShortcutImage();
    chatController.showAttachmentView.value = false;

    if (chatController.showFaceView.value) {
      inputState = 1;
      chatController.showFaceView.value = false;
      assetPickerProvider?.selectedAssets = [];
      inputFocusNode.requestFocus();

      inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: inputController.text.length),
      );
    } else {
      chatController.showFaceView.value = true;

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
    setAttachmentOption();
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
    chatController.fetchRecentAssets();
  }

  setupScreenshotCallback() {
    screenshotCallback ??= ScreenshotCallback();
    screenshotCallback?.addListener(() async {
      if (chatController.isScreenshotEnabled &&
          chatController.appState == AppLifecycleState.resumed &&
          (Get.currentRoute.contains('chat/private_chat') ||
              Get.currentRoute.contains('chat/group_chat'))) {
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
    } else if (chatController.chat.isSecretary) {
      chatController.attachmentOptions.clear();
      chatController.attachmentOptions
          .add(chatController.attachmentPictureOption);
      chatController.attachmentOptions
          .add(chatController.attachmentCameraOption);
    }
  }

  _onIncomingCall(_, __, ___) {
    resetRecordingState();
  }

  void onSendButtonClick(String text) {
    if (!sendState.value) {
      return;
    }

    if (isSending.value) return;

    if (notBlank(objectMgr.chatMgr.editMessageMap[chatId])) {
      onSendEditMessage(inputController.text.trim());
    } else {
      onSend(inputController.text.trim());
    }
  }

  void switchChatSearchType({required bool isTextModeSearch}) {
    BaseChatController controller;
    bool isSingleChat;
    if (Get.isRegistered<SingleChatController>()) {
      controller = Get.find<SingleChatController>(tag: chatId.toString());
      isSingleChat = true;
    } else {
      isSingleChat = false;
      controller = Get.find<GroupChatController>(tag: chatId.toString());
    }
    controller.switchChatSearchType(
      isTextModeSearch: isTextModeSearch,
      isSingleChat: isSingleChat,
      chat: controller.chat,
    );
    if (!isTextModeSearch) {
      controller.searchController.text = '${localized(chatFrom)}: ';
    } else {
      controller.searchController.clear();
      controller.searchController.text = '';
    }
  }

  void switchChatListMode() {
    chatController.isListModeSearch.value =
        !chatController.isListModeSearch.value;
    chatController.onCancelFocus();
  }

  Future<void> checkIOSClipboard() async {
    if (Platform.isIOS) {
      // 检查是否符合展示Paste的条件
      List<List<String>> imageDataList =
          await ClipboardUtil.getClipboardImages();
      hasImageInClipBoardInIOS.value = imageDataList.isNotEmpty;
      update();
    }
  }

  Future<void> clickPastImage() async {
    Get.toNamed(RouteName.mediaPreSendView,
        preventDuplicates: false,
        arguments: {
          "contentText": "",
          "chatId": chatId,
        });
  }
}
