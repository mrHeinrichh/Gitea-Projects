import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import '../../../utils/theme/text_styles.dart';

class MentionView extends StatefulWidget {
  final List<Map<String, dynamic>> groupMembers;
  final Chat chat;

  const MentionView({
    super.key,
    required this.groupMembers,
    required this.chat,
  });

  @override
  State<MentionView> createState() => _MentionViewState();
}

class _MentionViewState extends State<MentionView> {
  List<int> adminList = <int>[];
  final originalGroupMembers = <User>[].obs;
  final filteredGroupMembers = <User>[].obs;

  GroupChatController get groupController =>
      Get.find<GroupChatController>(tag: widget.chat.id.toString());

  CustomInputController get controller =>
      Get.find<CustomInputController>(tag: widget.chat.id.toString());

  ValueNotifier<bool> fullScreen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    adminList =
        groupController.group.value!.admins.map<int>((e) => e as int).toList();
    originalGroupMembers.assignAll(sortMemberList(widget.groupMembers
        .map<User>((e) => User.fromGroupMember(e))
        .toList()));
    updateNicknames(originalGroupMembers);

    controller.inputController.addListener(onAtTextChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onAtTextChange();
    });
  }

  @override
  void dispose() {
    controller.inputController.removeListener(onAtTextChange);
    super.dispose();
  }

  void onAtTextChange() {
    if (controller.inputController.selection.baseOffset < 0) return;
    String word = getWordAtOffset(controller.inputController.text,
        controller.inputController.selection.baseOffset);
    if (word.startsWith('@')) {
      word = word.substring(1);
    }

    filterMentionList(word);
  }

  void onMentionTap(User user) => controller.addMentionUser(user);

  void filterMentionList(String word) {
    List<User> groupMemberList = originalGroupMembers
        .where((element) =>
            !objectMgr.userMgr.isMe(element.uid) &&
            element.deletedAt == 0 &&
            (word.isEmpty ||
                containsInOrder(
                    element.nickname.toLowerCase(), word.toLowerCase())))
        .toList();

    updateNicknames(groupMemberList);

    filteredGroupMembers.assignAll(sortMemberList(groupMemberList));
  }

  void updateNicknames(List<User> userList) {
    for (User user in userList) {
      String name = objectMgr.userMgr
          .getUserTitle(objectMgr.userMgr.getUserById(user.uid));
      if (name.isNotEmpty) {
        user.nickname = name;
      }
    }
  }

  bool containsInOrder(String firstString, String secondString) {
    int firstIndex = 0;
    int secondIndex = 0;

    while (
        firstIndex < firstString.length && secondIndex < secondString.length) {
      if (firstString[firstIndex] == secondString[secondIndex]) {
        // If the characters match, move to the next character in both strings
        secondIndex++;
      }
      // Always move to the next character in the first string
      firstIndex++;
    }

    // If we've reached the end of the second string, it means all characters were found in order
    return secondIndex == secondString.length;
  }

  List<User> sortMemberList(List<User> memberList) {
    if (memberList.isEmpty) return [];

    List<User> tempList = [];
    User? me = memberList
        .firstWhereOrNull((element) => objectMgr.userMgr.isMe(element.uid));
    if (me != null) {
      tempList.insert(
          0,
          memberList
              .firstWhere((element) => objectMgr.userMgr.isMe(element.uid)));
    }

    /// 检测 群主是否为当前账号
    if (!groupController.isOwner && memberList.isNotEmpty) {
      User? owner = memberList.firstWhereOrNull(
          (user) => user.uid == groupController.group.value?.owner);
      if (owner != null) {
        tempList.add(owner);
      }
    }

    /// 排序 管理员并添加
    List<User> adminTempList = memberList
        .where((User e) =>
            adminList.contains(e.uid) && !objectMgr.userMgr.isMe(e.uid))
        .toList();

    adminTempList.sort((User a, User b) {
      return a.lastOnline < b.lastOnline ? 1 : -1;
    });
    tempList.addAll(adminTempList);

    /// 排序普通成员 并添加
    List<User> lastOnlineUserList = memberList
        .where((User e) =>
            !adminList.contains(e.uid) &&
            e.uid != groupController.group.value?.owner &&
            !objectMgr.userMgr.isMe(e.uid))
        .toList();

    lastOnlineUserList.sort((User a, User b) {
      return a.lastOnline < b.lastOnline ? 1 : -1;
    });
    tempList.addAll(lastOnlineUserList);

    return tempList;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        double totalHeight = MediaQuery.of(context).size.height -
            (kToolbarHeight +
                kToolbarHeight +
                MediaQuery.of(context).padding.top);
        double minPercentage;
        double maxPercentage;
        if (filteredGroupMembers.length > 3) {
          int minHeight = 48 * 5;
          int maxHeight = 48 * (filteredGroupMembers.length + 7);
          if (controller.inputFocusNode.hasFocus) {
            minHeight += keyboardHeight.toInt();
            maxHeight += keyboardHeight.toInt();
          }
          minPercentage = minHeight / totalHeight;
          maxPercentage = maxHeight / totalHeight;
        } else {
          int minHeight = 48 * filteredGroupMembers.length;
          minPercentage = minHeight / totalHeight;
          if (controller.inputFocusNode.hasFocus) {
            if (minPercentage < 0.45) minPercentage = 0.45;
          }

          if (minPercentage < 0.25) minPercentage = 0.25;

          maxPercentage = minPercentage;
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.bottomCenter,
          child: filteredGroupMembers.isEmpty
              ? const SizedBox()
              : NotificationListener<DraggableScrollableNotification>(
                  onNotification:
                      (DraggableScrollableNotification notification) {
                    if (notification.extent == min(maxPercentage, 1.0)) {
                      fullScreen.value = true;
                    } else {
                      fullScreen.value = false;
                    }
                    return true;
                  },
                  child: DraggableScrollableSheet(
                    initialChildSize: min(minPercentage, maxPercentage),
                    minChildSize: minPercentage,
                    maxChildSize: min(maxPercentage, 1.0),
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: fullScreen,
                        builder: (
                          BuildContext context,
                          bool value,
                          Widget? child,
                        ) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(
                                    fullScreen.value ? 0.0 : 20.0),
                              ),
                            ),
                            child: child,
                          );
                        },
                        child: ListView.builder(
                          controller: scrollController,
                          prototypeItem: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 40.0,
                                  height: 40.0,
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                const Expanded(
                                  child: Text(
                                    "Example",
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                ),
                                Text(
                                  'Owner',
                                  style: TextStyle(
                                    color: JXColors.secondaryTextBlack,
                                    fontWeight: MFontWeight.bold5.value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemCount: filteredGroupMembers.length,
                          itemBuilder: (BuildContext context, int index) {
                            final User user = filteredGroupMembers[index];

                            bool isOwner =
                                user.uid == groupController.group.value?.owner;
                            bool isAdmin = groupController.group.value?.admins
                                    .contains(user.uid) ??
                                false;

                            return GestureDetector(
                              key: ValueKey(user.uid),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onMentionTap(user),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: <Widget>[
                                    CustomAvatar(
                                      uid: user.uid,
                                      size: 30.0,
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: NicknameText(
                                        uid: user.uid,
                                        fontSize: 16.0,
                                        isTappable: false,
                                      ),
                                    ),
                                    if (isOwner)
                                      Text(
                                        localized(groupOwner),
                                        style: TextStyle(
                                          color: JXColors.secondaryTextBlack,
                                          fontWeight: MFontWeight.bold5.value,
                                        ),
                                      ),
                                    if (isAdmin)
                                      Text(
                                        localized(groupAdmin),
                                        style: TextStyle(
                                          color: JXColors.secondaryTextBlack,
                                          fontWeight: MFontWeight.bold5.value,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
