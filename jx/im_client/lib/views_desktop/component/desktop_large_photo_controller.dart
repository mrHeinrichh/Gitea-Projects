import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';

class DesktopLargePhotoController extends GetxController {
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

  DesktopLargePhotoController.desktop(this.assetList, int currentIndex) {
    this.currentIndex.value = currentIndex;
  }

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      messageList.sort((a, b) => b.create_time - a.create_time);
      messageList =
          messageList.where((element) => element.deleted != 1).toList();
      index.value = messageList.indexWhere(
        (element) => element.message_id == selectedMessage?.message_id,
      );
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

  Future<void> onForwarding<T>(T param, List<Message> messages) async {
    if (Get.isRegistered<ChatListController>()) {
    } else {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 50), () async {
      if (T == User) {
        final Chat? chat =
            await objectMgr.chatMgr.getChatByFriendId((param as User).uid);
        if (chat != null) {
          Routes.toChat(chat: chat);
        } else {
          return;
        }
      } else if (T == Chat) {}
    }).whenComplete(() => Get.back());
  }

  void keyStrokeChecking(RawKeyEvent event) {
    if (event is RawKeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index.value < messageList.length - 1) {
        index += 1;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (index.value > 0) {
        index -= 1;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {}
  }

  @override
  void onClose() {
    RawKeyboard.instance.removeListener(keyStrokeChecking);
    super.onClose();
  }
}
