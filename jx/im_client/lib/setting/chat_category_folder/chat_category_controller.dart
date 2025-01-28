import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im_common;
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/data/db_chat_category.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/setting/chat_category_folder/create/chat_category_create.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';

class ChatCategoryController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // 文件夹列表
  final RxList<ChatCategory> categoryList = <ChatCategory>[].obs;

  final RxList<ChatCategory> cacheCategoryList = <ChatCategory>[].obs;

  late final AnimationController editAnimController;

  final RxBool isEditing = false.obs;

  final RxInt dragIndex = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    editAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    categoryList.assignAll(objectMgr.chatMgr.chatCategoryList);
    categoryList.sort((a, b) => a.isAllChatRoom ? -999 : a.seq - b.seq);

    objectMgr.chatMgr.on(ChatMgr.eventChatCategoryChanged, _onCategoryChanged);
  }

  @override
  void onClose() {
    editAnimController.dispose();

    objectMgr.chatMgr.off(ChatMgr.eventChatCategoryChanged, _onCategoryChanged);
    super.onClose();
  }

  void _onCategoryChanged(_, __, ___) {
    categoryList.assignAll(objectMgr.chatMgr.chatCategoryList);
    categoryList.sort((a, b) => a.isAllChatRoom ? -999 : a.seq - b.seq);
  }

  void toggleEdit() {
    if (isEditing.value) {
      // on done press
      if (cacheCategoryList.length != categoryList.length) {
        // list not equal, must update

        for (int i = 0; i < categoryList.length; i++) {
          // reset seq number
          categoryList[i].seq = i + 1;
        }

        objectMgr.chatMgr.replaceChatCategory(categoryList);
        cacheCategoryList.clear();

        isEditing.value = !isEditing.value;
        return;
      }

      bool isSame = true;
      for (int i = 0; i < cacheCategoryList.length; i++) {
        final oldCategory = cacheCategoryList[i];
        final newCategory = categoryList[i];

        if (oldCategory.id != newCategory.id) {
          isSame = false;
        }

        newCategory.seq = i + 1;
      }

      if (!isSame) {
        // 1. update local chat category
        objectMgr.chatMgr.replaceChatCategory(categoryList);

        // 2. invoke update-store
        updateStore(
          DBChatCategory.tableName,
          jsonEncode(categoryList),
        );
        cacheCategoryList.clear();

        isEditing.value = !isEditing.value;
        return;
      }
    } else {
      cacheCategoryList.assignAll(categoryList.toList());
    }

    isEditing.value = !isEditing.value;
  }

  void onChatCategoryPress(BuildContext context, {ChatCategory? category}) {
    if (category != null && category.isAllChatRoom) return;
    if (category != null && isEditing.value) return;

    if (categoryList.length >= 21 && category == null) {
      im_common.ImBottomToast(
        context,
        title: localized(chatCategoryCreateExceedLimit, params: ["20"]),
        icon: im_common.ImBottomNotifType.warning,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: false,
      builder: (ctx) => ChatCategoryCreate(category: category),
    ).then(
      (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }

  void onDeleteChatCategory(BuildContext context, ChatCategory category) {
    showCustomBottomAlertDialog(
      context,
      subtitle: localized(chatCategoryDeleteHintTitle),
      confirmText: localized(buttonDelete),
      cancelText: localized(buttonCancel),
      cancelTextColor: themeColor,
      onConfirmListener: () => _confirmDeleteChatCategory(category),
      // onCancelListener: Get.back,
    );
  }

  void _confirmDeleteChatCategory(ChatCategory category) async {
    // 1. update local chat category
    final status = await objectMgr.chatMgr.deleteChatCategory(
      [category],
      updateRemote: true,
    );

    if (status) {
      categoryList.remove(category);

      cacheCategoryList.clear();

      if (categoryList.length < 2) {
        isEditing.value = !isEditing.value;
      }
    }
  }

  /// Drag reorderable callback
  void onReorderStart(int index) {
    assert(index > 1, 'reorder index must greater than 1');
    HapticFeedback.mediumImpact();
    dragIndex.value = index - 1;
  }

  void onReorderEnd(int index) {
    dragIndex.value = -1;
    HapticFeedback.mediumImpact();
  }

  void onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = categoryList.removeAt(oldIndex - 1);
    if (newIndex <= 1) {
      categoryList.insert(1, item);
    } else {
      categoryList.insert(newIndex - 1, item);
    }
  }
}
