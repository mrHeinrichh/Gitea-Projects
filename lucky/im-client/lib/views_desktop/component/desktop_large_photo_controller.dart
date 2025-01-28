import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:get/get.dart';
import '../../home/chat/controllers/chat_list_controller.dart';
import '../../im/chat_info/tool_option_model.dart';
import '../../im/custom_input/custom_input_controller.dart';
import '../../main.dart';
import '../../object/chat/chat.dart';
import '../../object/chat/message.dart';
import '../../object/user.dart';
import '../../routes.dart';

class DesktopLargePhotoController extends GetxController {
  late final Player player = Player();
  late final VideoController videoController = VideoController(player);

  late CustomInputController inputController;

  RxBool onHover = false.obs;
  RxInt index = 0.obs;
  String caption = '';
  Rxn<File> asset = Rxn<File>();
  RxString path = ''.obs;
  RxInt messageTyp = (-1).obs;
  RxDouble scaleSize = 100.0.obs;
  List<Message> messageList = [];
  Message? selectedMessage;
  TransformationController transformController = TransformationController();

  final currentIndex = 0.obs;
  List<Map<String, dynamic>> assetList = [];

  DesktopLargePhotoController();

  DesktopLargePhotoController.desktop(
      List<Map<String, dynamic>> assetList, int currentIndex) {
    this.assetList = assetList;
    this.currentIndex.value = currentIndex;
  }

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      messageList..sort((a, b) => b.create_time - a.create_time);
      messageList =
          messageList.where((element) => element.deleted != 1).toList();
      index.value = messageList.indexWhere(
          (element) => element.message_id == selectedMessage?.message_id);
      // getMessageData();
    });
  }

  String getSourcePath(var data) {
    if (data is Map<String, dynamic>) {
      return data['asset'];
    }
    return data;
  }

  void onTapSecondMenu(ToolOptionModel option, Message message) {
    switch (option.optionType) {
      case 'deleteForEveryone':
        Get.back();
        inputController.onDeleteMessage(
          inputController.chatController.context,
          [message],
          isAll: true,
        );
        break;
      case 'deleteForMe':
        Get.back();
        inputController.onDeleteMessage(
          inputController.chatController.context,
          [message],
          isAll: false,
        );
        break;
      default:
        break;
    }
  }

  ///TODO: fix forward
  Future<void> onForwarding<T>(T param, List<Message> messages) async {
    final ChatListController chatController;
    if (Get.isRegistered<ChatListController>())
      chatController = Get.find<ChatListController>();
    else
      return;
    await Future.delayed(const Duration(milliseconds: 50), () async {
      if (T == User) {
        ///若是用户的话，就需要获取聊天室
        final Chat? chat =
            await objectMgr.chatMgr.getChatByFriendId((param as User).uid);
        if (chat != null) {
          Routes.toChatDesktop(chat: chat);
        }
        // chatController.desktopSwitchChat(
        //   chat,
        //   isMessageForward: true,
        //   forwardedMessage: messages,
        // );
        else
          return;
      } else if (T == Chat) {
        ///若是聊天室的话，直接转换
        // chatController.desktopSwitchChat(
        //   param as Chat,
        //   isMessageForward: true,
        //   forwardedMessage: messages,
        // );
      }
    }).whenComplete(() => Get.back());
  }

  void keyStrokeChecking(RawKeyEvent event) {
    if (event is RawKeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index.value < messageList.length - 1) {
        index += 1;
        // getMessageData();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (index.value > 0) {
        index -= 1;
        // getMessageData();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      // Get.back();
    }
  }

  @override
  void onClose() {
    RawKeyboard.instance.removeListener(keyStrokeChecking);
    super.onClose();
  }
}
