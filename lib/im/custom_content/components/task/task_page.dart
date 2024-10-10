import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/components/task/assignee.dart';
import 'package:jxim_client/im/custom_content/components/task/ctr_task.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class TaskPage extends GetView<CtrTask> {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        leadingWidth: 90.0,
        leading: OpacityEffect(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    color: themeColor,
                  ),
                  Text(
                    localized(buttonBack),
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight:MFontWeight.bold4.value,
                      color: themeColor,
                      inherit: true,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        elevation: 0.0,
        centerTitle: true,
        title: Text(
          localized(taskDetail),
          style: TextStyle(
            fontSize: 17.0,
            fontWeight: MFontWeight.bold5.value,
          ),
        ),
        actions: <Widget>[
          IconButton(
            key: controller.moreKey,
            onPressed: () => controller.onMoreTap(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorTextPrimary.withOpacity(0.06)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildTitle(),
            const SizedBox(height: 24),
            Expanded(child: buildTasks()),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          localized(taskTitle),
          style: TextStyle(
            fontSize: 14.0,
            color: colorTextPrimary.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            controller.task.value.title,
            style: const TextStyle(
              fontSize: 16.0,
              color: colorTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          localized(tasks),
          style: TextStyle(
            fontSize: 14.0,
            color: colorTextPrimary.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: controller.task.value.totalCount < 10,
            itemCount: controller.task.value.totalCount,
            itemBuilder: (BuildContext context, int index) {
              return Obx(() {
                final SubTask subTask = controller.task.value.subtasks[index];

                return GestureDetector(
                  onTap: () => controller.onChangeStatus(
                    context,
                    subTask,
                    index,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      buildStatusTick(subTask.status),
                      const SizedBox(width: 12.0),
                      buildTaskContent(
                        subTask,
                        index == (controller.task.value.totalCount - 1),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildStatusTick(TaskStatus status) {
    if (status == TaskStatus.progress) {
      return Container(
        width: 20.0,
        height: 20.0,
        margin: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: colorTaskPurple,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_horiz,
          size: 18.0,
          color: Colors.white,
        ),
      );
    }

    if (status == TaskStatus.done) {
      return Container(
        width: 20.0,
        height: 20.0,
        margin: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: colorGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 18.0,
          color: Colors.white,
        ),
      );
    }

    if (status == TaskStatus.cancel) {
      return Container(
        width: 20.0,
        height: 20.0,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: colorTextPrimary.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          size: 18.0,
          color: Colors.white,
        ),
      );
    }

    return Container(
      width: 20.0,
      height: 20.0,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorTextPrimary.withOpacity(0.06),
          width: 1.0,
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget buildTaskContent(SubTask subTask, bool isLast) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: colorTextPrimary.withOpacity(0.06),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                subTask.content,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: colorTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Assignee(uid: subTask.uid),
          ],
        ),
      ),
    );
  }
}
