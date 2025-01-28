import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TaskSelectorController extends GetxController {
  final TextEditingController titleController = TextEditingController();
  final ItemScrollController itemScrollController = ItemScrollController();
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();

  final _debouncer = Debounce(const Duration(milliseconds: 300));

  final isTitleValid = false.obs;

  final subTasks = <SubTask>[SubTask(), SubTask()].obs;

  List<User> oriMemberList = [];

  final memberList = <User>[].obs;

  final isSearching = false.obs;

  final isValidSend = false.obs;

  final isSubmitting = false.obs;

  SubTask? selectedSubTask;

  TaskSelectorController(this.chat);

  final Chat chat;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<GroupChatController>(tag: chat.id.toString())) {
      GroupChatController grpChatCtr =
          Get.find<GroupChatController>(tag: chat.id.toString());
      initData(grpChatCtr.groupMembers);
    }
  }

  initData(List<Map<String, dynamic>> groupMembers) {
    for (final userData in groupMembers) {
      User user = User();
      user.uid = userData['user_id'];
      user.username = userData["user_name"];
      user.nickname = user.username;
      user.lastOnline = userData["last_online"];
      user.profilePicture = userData["icon"];
      oriMemberList.add(user);
    }

    memberList.assignAll(oriMemberList);
  }

  void titleValid(String title) {
    bool hasForeSpace = Regular.foreWithSpace(title);
    final textLength = getMessageLength(title);

    if (textLength < 1 || textLength > 30 || hasForeSpace) {
      isTitleValid.value = false;
    } else {
      isTitleValid.value = true;
    }

    updateSendValidState();
  }

  void updateSendValidState() {
    bool isValid = isTitleValid.value;
    if (isValid) {
      for (int i = 0; i < subTasks.length; i++) {
        if (i < subTasks.length - 1) {
          final SubTask subtask = subTasks[i];
          if (!notBlank(subtask.content) || subtask.uid <= 0) {
            isValid = false;
            break;
          }
        }
      }
    }
    isValidSend.value = isValid;
  }

  void addTask() {
    if (subTasks.length < 50) {
      subTasks.add(SubTask());
      updateSendValidState();
    }
  }

  void removeTask(SubTask subTask) {
    subTasks.remove(subTask);
    updateSendValidState();
  }

  void sendTask(Chat chat) async {
    if (!isValidSend.value) return;

    TaskContent task = TaskContent.creator();
    task.chatId = chat.id;
    task.groupName = chat.name;
    task.creatorUid = objectMgr.userMgr.mainUser.uid;
    task.userName = objectMgr.userMgr.mainUser.nickname;
    task.title = titleController.text;
    task.subtasks = subTasks.sublist(0, subTasks.length - 1);

    isSubmitting.value = true;
    try {
      TaskContent? resTask = await objectMgr.taskMgr.send(task);
      if (resTask != null) {
        task = resTask;
      }
    } catch (e) {
      pdebug("sendTask Failed: $e");
    }
    isSubmitting.value = false;
  }

  void showUserPicker(BuildContext context, SubTask subTask) {
    selectedSubTask = subTask;
    showModalBottomSheet(
      context: context,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            color: colorWhite,
            constraints: const BoxConstraints(minHeight: double.maxFinite),
            child: Obx(() {
              return Column(
                children: [
                  _headerView(context),
                  if (memberList.isEmpty) _emptyView(),
                  if (memberList.isNotEmpty)
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ListView.separated(
                          itemCount: memberList.length,
                          itemBuilder: (BuildContext context, int index) {
                            final User user = memberList[index];
                            return _buildFriendListItem(context, user);
                          },
                          separatorBuilder: (_, __) => SizedBox(
                            height: 1.0.h,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildFriendListItem(BuildContext context, User user) {
    return GestureDetector(
      onTap: () {
        onCellClicked(user);
        resetSearch();
        Get.back();
      },
      child: Container(
        key: ValueKey(user.uid),
        padding: EdgeInsets.symmetric(
          horizontal: 20.0.w,
          vertical: 12.0.w,
        ),
        decoration: BoxDecoration(
          border: jxDimension.borderPrimaryColor(),
        ),
        child: Row(
          children: <Widget>[
            CustomAvatar.user(
              user,
              size: 40,
              headMin: Config().headMin,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  NicknameText(
                    uid: user.uid,
                    fontSize: MFontSize.size16.value,
                    fontWeight: MFontWeight.bold5.value,
                    isTappable: false,
                  ),
                  Text(
                    UserUtils.onlineStatus(user.lastOnline),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colorGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onCellClicked(User user) async {
    if (selectedSubTask != null) {
      selectedSubTask!.userObv.value = user;
      selectedSubTask!.uid = user.uid;
      updateSendValidState();
    }
  }

  void onSearchChange(String value) {
    _debouncer.call(() {
      if (notBlank(value)) {
        List<User> memberFiltered = oriMemberList
            .where(
              (user) => objectMgr.userMgr
                  .getUserTitle(user)
                  .toLowerCase()
                  .contains(value.toLowerCase()),
            )
            .toList();
        memberList.assignAll(memberFiltered);
      } else {
        memberList.assignAll(oriMemberList);
      }
    });
  }

  Widget _headerView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorTextPrimary.withOpacity(0.06),
            blurRadius: 0.0.w,
            offset: const Offset(0.0, -1.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      resetSearch();
                    },
                    child: Text(
                      localized(buttonBack),
                      style: jxTextStyle.textStyle17(color: themeColor),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    localized(taskAssignee),
                    style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
                  ),
                ),
              ],
            ),
          ),

          /// Search bar
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: SearchingAppBar(
              onTap: () => isSearching(true),
              onChanged: onSearchChange,
              onCancelTap: () {
                resetSearch();
              },
              isSearchingMode: isSearching.value,
              isAutoFocus: false,
              focusNode: searchFocus,
              controller: searchController,
              suffixIcon: Visibility(
                visible: isSearching.value,
                child: GestureDetector(
                  onTap: () {
                    resetSearch();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SvgPicture.asset(
                      'assets/svgs/clearIcon.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        SvgPicture.asset(
          'assets/svgs/contactEmptyStateIcon.svg',
          width: 148,
          height: 148,
        ),
        const SizedBox(height: 16),
        Text(
          localized(noResults),
          style: jxTextStyle.textStyleBold16(),
        ),
        const SizedBox(height: 4),
        Text(
          localized(noMatchingContactsWereFound),
          style: jxTextStyle.textStyle16(color: colorTextSecondary),
        ),
      ],
    );
  }

  void resetSearch() async {
    isSearching.value = false;
    searchController.clear();
    searchFocus.unfocus();
    memberList.assignAll(oriMemberList);
  }

  @override
  void onClose() {
    subTasks.assignAll([SubTask(), SubTask()]);
    selectedSubTask = null;
    isValidSend.value = false;
    titleController.clear();
    resetSearch();
    super.onClose();
  }
}
