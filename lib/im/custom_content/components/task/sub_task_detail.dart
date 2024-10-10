import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class SubTaskDetail extends StatefulWidget {
  final Chat chat;
  final TaskContent task;
  final SubTask subTask;

  const SubTaskDetail({
    super.key,
    required this.chat,
    required this.task,
    required this.subTask,
  });

  @override
  State<SubTaskDetail> createState() => _SubTaskDetailState();
}

class _SubTaskDetailState extends State<SubTaskDetail> {
  late final SubTask subTask;

  @override
  void initState() {
    super.initState();
    subTask = widget.subTask;

    objectMgr.taskMgr.on(MgrTask.UPDATE_TASK, onStatusUpdate);
  }

  @override
  void dispose() {
    objectMgr.taskMgr.off(MgrTask.UPDATE_TASK, onStatusUpdate);
    super.dispose();
  }

  void onStatusUpdate(Object sender, Object type, Object? data) {
    if (data is SubTask && data.subTaskId == subTask.subTaskId) {
      subTask.status = data.status;
      if (mounted) setState(() {});
    }
  }

  void onStatusTap(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: [
            ColoredBox(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () => updateStatus(TaskStatus.toDo.value),
                child: Text(
                  localized(toDo),
                  style: TextStyle(color: themeColor),
                ),
              ),
            ),
            ColoredBox(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () => updateStatus(TaskStatus.progress.value),
                child: Text(
                  localized(progress),
                  style: TextStyle(color: themeColor),
                ),
              ),
            ),
            ColoredBox(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () => updateStatus(TaskStatus.done.value),
                child: Text(
                  localized(buttonDone),
                  style: TextStyle(color: themeColor),
                ),
              ),
            ),
            ColoredBox(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () => updateStatus(TaskStatus.cancel.value),
                child: Text(
                  localized(cancelled),
                  style: const TextStyle(color: colorRed),
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localized(cancel),
              style: TextStyle(color: themeColor),
            ),
          ),
        );
      },
    );
  }

  void updateStatus(int status) async {
    if (!objectMgr.userMgr.isMe(widget.task.creatorUid) &&
        !objectMgr.userMgr.isMe(subTask.uid)) {
      Toast.showToast(localized(errorTaskUpdateAuth));
      return;
    }

    try {
      objectMgr.taskMgr.updateTask(
        widget.task.taskId,
        widget.task.chatId,
        widget.chat.name,
        widget.task.userName,
        widget.task.groupName,
        subTask.subTaskId,
        subTask.uid,
        subTask.content,
        status,
      );
    } catch (e) {
      pdebug('updateTask error: $e');
    } finally {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        decoration: const BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                widget.task.title,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
            ),
            Divider(
              height: 0.5,
              thickness: 0.5,
              color: colorTextPrimary.withOpacity(0.06),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  buildTaskDetail(),
                  const SizedBox(height: 24),
                  buildAssigneeDetail(),
                  const SizedBox(height: 24),
                  buildTaskStatus(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTaskDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 8,
            bottom: 8,
          ),
          child: Text(
            localized(task),
            style: TextStyle(
              fontSize: 14.0,
              color: colorTextPrimary.withOpacity(0.6),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 50.0,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subTask.content,
            style: const TextStyle(
              fontSize: 16.0,
              color: colorTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAssigneeDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            localized(taskAssignee),
            style: TextStyle(
              fontSize: 14.0,
              color: colorTextPrimary.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              CustomAvatar.normal(
                subTask.uid,
                size: 44.0,
              ),
              const SizedBox(width: 12),
              NicknameText(
                uid: subTask.uid,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTaskStatus(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            localized(status),
            style: TextStyle(
              fontSize: 14.0,
              color: colorTextPrimary.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OpacityEffect(
          child: GestureDetector(
            onTap: () => onStatusTap(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colorTextPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
              ),
              child: buildStatus(subTask.status),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildStatus(TaskStatus status) {
    Widget tick;
    Widget name;
    if (status == TaskStatus.progress) {
      tick = Container(
        width: 20.0,
        height: 20.0,
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

      name = Text(
        localized(progress),
        style: const TextStyle(
          fontSize: 16.0,
          color: colorTaskPurple,
        ),
      );
    } else if (status == TaskStatus.done) {
      tick = Container(
        width: 20.0,
        height: 20.0,
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

      name = Text(
        localized(buttonDone),
        style: const TextStyle(
          fontSize: 16.0,
          color: colorGreen,
        ),
      );
    } else if (status == TaskStatus.cancel) {
      tick = Container(
        width: 20.0,
        height: 20.0,
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

      name = Text(
        localized(cancel),
        style: TextStyle(
          fontSize: 16.0,
          color: colorTextPrimary.withOpacity(0.06),
        ),
      );
    } else {
      tick = Container(
          width: 20.0,
          height: 20.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorTextSecondary,
              width: 1.0,
            ),
          ));

      name = Text(
        localized(toDo),
        style: const TextStyle(
          fontSize: 16.0,
          color: colorTextSecondary,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        tick,
        const SizedBox(width: 8),
        name,
      ],
    );
  }
}
