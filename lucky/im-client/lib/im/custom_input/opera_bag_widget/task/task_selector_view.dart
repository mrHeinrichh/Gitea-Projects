import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/component/media_selector_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'task_selector_controller.dart';

class TaskSelectorView extends StatelessWidget {
  const TaskSelectorView({Key? key, required this.chat}) : super(key: key);
  final Chat chat;

  TaskSelectorController get controller => Get.find<TaskSelectorController>();

  @override
  Widget build(BuildContext context) {
    Get.put(TaskSelectorController(chat));

    return GetBuilder(
      global: true,
      init: controller,
      builder: (logic) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Column(
            children: <Widget>[
              _buildTopBar(context),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.w),
          topRight: Radius.circular(12.w),
        ),
        boxShadow: <BoxShadow>[
          const BoxShadow(
            color: JXColors.bgTertiaryColor,
            offset: Offset(0.0, -1.0),
          ),
        ],
      ),
      child: SizedBox(
        height: 60,
        child: Stack(
          children: [
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: GestureDetector(
            //     onTap: () => Navigator.of(context).pop(),
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16),
            //       child: Text(
            //         localized(cancel),
            //         style: jxTextStyle.textStyle16(color: accentColor),
            //       ),
            //     ),
            //   ),
            // ),
            cancelWidget(context),
            Center(
              child: Text(
                localized(tasks),
                style:
                    jxTextStyle.appTitleStyle(color: JXColors.primaryTextBlack),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  controller.sendTask(controller.chat);
                  Get.back();
                },
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(
                      () => controller.isSubmitting.value
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            )
                          : Text(
                              localized(send),
                              style: jxTextStyle.textStyle16(
                                  color: controller.isValidSend.value
                                      ? accentColor
                                      : JXColors.black32),
                            ),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: JXColors.bgTertiaryColor,
              blurRadius: 0.0.w,
              offset: const Offset(0.0, -1.0),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(),
              const SizedBox(height: 20),
              _buildTaskList(),
            ],
          ),
        ));
  }

  Widget _buildTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localized(taskTitle),
          style: TextStyle(
              fontSize: 14.0,
              fontWeight: MFontWeight.bold5.value,
              color: JXColors.iconSecondaryColor),
        ),
        const SizedBox(height: 8),
        TextFormField(
          contextMenuBuilder: textMenuBar,
          controller: controller.titleController,
          style: jxTextStyle.textStyle17().copyWith(decorationThickness: 0),
          cursorColor: accentColor,
          decoration: InputDecoration(
            hintText: localized(taskFillTitle),
            hintStyle: jxTextStyle.textStyle16(
              color: JXColors.black32,
            ),
            filled: true,
            fillColor: JXColors.lightShade,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 16,
            ).w,
            isDense: true,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(10.w),
            ),
          ),
          onChanged: (text) {
            controller.titleValid(text);
          },
        )
      ],
    );
  }

  Widget _buildTaskList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localized(taskList),
          style: TextStyle(
              fontSize: 14.0,
              fontWeight: MFontWeight.bold5.value,
              color: JXColors.iconSecondaryColor),
        ),
        const SizedBox(height: 8),
        Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: JXColors.lightShade,
            ),
            child: SlidableAutoCloseBehavior(
              child: Obx(
                () => ListView.separated(
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.subTasks.length,
                  itemBuilder: (context, index) {
                    SubTask subTask = controller.subTasks[index];
                    bool showNextBtn = index == controller.subTasks.length - 1;
                    return showNextBtn
                        ? _buildNextBtn()
                        : Slidable(
                            key: Key(index.toString()),
                            closeOnScroll: true,
                            endActionPane: ActionPane(
                              extentRatio: 0.2,
                              motion: const DrawerMotion(),
                              children: [
                                CustomSlidableAction(
                                  onPressed: (context) {
                                    controller.removeTask(subTask);
                                  },
                                  backgroundColor: errorColor,
                                  foregroundColor: JXColors.white,
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/svgs/delete_icon.svg',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.fill,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        localized(chatDelete),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: jxTextStyle.slidableTextStyle(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            child: _buildInputCell(context, index, subTask));
                  },
                  separatorBuilder: (context, index) {
                    return const CustomDivider();
                  },
                ),
              ),
            )),
        const SizedBox(height: 8),
        Text(
          localized(taskMax),
          style: TextStyle(
              fontSize: 14.0,
              fontWeight: MFontWeight.bold5.value,
              color: JXColors.iconSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildNextBtn() {
    return GestureDetector(
      onTap: () => controller.addTask(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Text(
          localized(taskNext),
          style: TextStyle(
              fontSize: 16.0,
              fontWeight: MFontWeight.bold5.value,
              color: JXColors.black32),
        ),
      ),
    );
  }

  Widget _buildInputCell(BuildContext context, int index, SubTask subTask) {
    return GestureDetector(
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  contextMenuBuilder: textMenuBar,
                  controller: subTask.textController,
                  focusNode: subTask.focusNode,
                  style: jxTextStyle
                      .textStyle17()
                      .copyWith(decorationThickness: 0),
                  cursorColor: accentColor,
                  decoration: InputDecoration(
                    hintText: localized(taskWhatTodo),
                    hintStyle: jxTextStyle.textStyle16(
                      color: JXColors.black32,
                    ),
                    filled: true,
                    fillColor: JXColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ).w,
                    isDense: true,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (text) {
                    subTask.content = text;
                    controller.updateSendValidState();
                  },
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => controller.showUserPicker(context, subTask),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: accentColor.withOpacity(0.2)),
                    child: Obx(() => subTask.userObv.value == null
                        ? Text(
                            "+${localized(taskPerson)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: MFontWeight.bold5.value,
                              color: accentColor,
                            ),
                          )
                        : _userInfoView(subTask.userObv.value!))),
              )
            ],
          )),
    );
  }

  Widget _userInfoView(User user) {
    return Row(
      children: [
        CustomAvatar(
          uid: user.uid,
          size: 26,
          headMin: Config().headMin,
        ),
        const SizedBox(width: 3),
        NicknameText(
          uid: user.uid,
          fontSize: MFontSize.size12.value,
          overflow: TextOverflow.ellipsis,
          isTappable: false,
          isShowYou: objectMgr.userMgr.isMe(user.uid),
        )
      ],
    );
  }
}
