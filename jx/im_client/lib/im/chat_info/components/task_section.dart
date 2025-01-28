import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/components/task_cell.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class TaskSection extends StatefulWidget {
  final Chat? chat;
  final bool isGroup;

  const TaskSection({
    super.key,
    this.chat,
    required this.isGroup,
  });

  @override
  State<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends State<TaskSection>
    with AutomaticKeepAliveClientMixin {
  /// 加载状态
  final scrollThreshold = 200;
  final messageList = <Message>[].obs;

  final taskList = <TaskContent>[].obs;

  final isLoading = false.obs;
  bool noMoreNext = false;
  bool isLoadingMore = true;
  bool chatIsDeleted = false;

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  @override
  void initState() {
    super.initState();

    if (widget.chat != null) {
      if (widget.chat!.flag_my >= ChatStatus.MyChatFlagKicked.value) {
        chatIsDeleted = true;
      } else {
        chatIsDeleted = false;
      }

      doLoadTaskList();
    }

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _doTaskMessageChange);
    objectMgr.taskMgr.on(MgrTask.UPDATE_TASK, onStatusUpdate);

    if (!chatIsDeleted) {
      objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _doMessageCome);
    }
  }

  _doTaskMessageChange(sender, type, data) {
    if (data['id'] != widget.chat?.id || data['message'] == null) {
      return;
    }
    List<dynamic> delAsset = [];
    for (var item in data['message']) {
      int id = 0;
      int messageId = 0;
      if (item is Message) {
        id = item.id;
      } else {
        messageId = item;
      }
      for (final asset in messageList) {
        Message? msg = asset;
        if (id == 0) {
          if (msg.message_id == messageId) {
            delAsset.add(asset);
          }
        } else {
          if (msg.id == id) {
            delAsset.add(asset);
          }
        }
      }
    }

    if (delAsset.isNotEmpty) {
      for (final item in delAsset) {
        messageList.remove(item);
      }
    }
  }

  _doMessageCome(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeTaskCreated) return;
      messageList.insert(0, data);
      return;
    }
  }

  void onStatusUpdate(Object sender, Object type, Object? data) {
    if (data is SubTask) {
      TaskContent? task =
          taskList.firstWhereOrNull((element) => element.taskId == data.taskId);

      if (task == null) return;

      final subTask = task.subtasks.firstWhere(
          (element) => element.subTaskId == data.subTaskId,
          orElse: () => SubTask());
      subTask.status = data.status;
      taskList.refresh();
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _doTaskMessageChange);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _doMessageCome);
    objectMgr.taskMgr.off(MgrTask.UPDATE_TASK, onStatusUpdate);

    super.dispose();
  }

  doLoadTaskList() async {
    if (messageList.isEmpty) isLoading.value = true;
    if (noMoreNext) return;

    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND chat_idx < ? AND typ = ?  AND (expire_time == 0 OR expire_time > ?) AND message_id != 0',
      [
        widget.chat!.id,
        widget.chat!.hide_chat_msg_idx,
        messageList.isEmpty
            ? widget.chat!.msg_idx + 1
            : messageList.last.chat_idx,
        messageTypeTaskCreated,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ],
      'DESC',
      30,
      null,
    );

    if (tempList.isEmpty) {
      noMoreNext = true;
    }

    List<Message> mList =
        tempList.map<Message>((e) => Message()..init(e)).toList();

    messageList.addAll(mList);

    taskList.addAll(
      messageList
          .map<TaskContent>((e) => e.decodeContent(cl: TaskContent.creator))
          .toList(),
    );

    List<TaskContent> tempTaskList = List.from(taskList);
    for (int i = 0; i < tempTaskList.length; i++) {
      if (objectMgr.taskMgr.taskMap[tempTaskList[i].taskId] != null) {
        taskList[i] = objectMgr.taskMgr.taskMap[tempTaskList[i].taskId]!;
      }
    }

    isLoading.value = false;
  }

  void navigateToTaskDetail(TaskContent task, Message message) {
    Get.toNamed(RouteName.taskDetail, arguments: {
      'task': task,
      'message': message,
      'chat': widget.chat,
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (isLoading.value) {
        return BallCircleLoading(
          radius: 20,
          ballStyle: BallStyle(
            size: 4,
            color: themeColor,
            ballType: BallType.solid,
            borderWidth: 1,
            borderColor: themeColor,
          ),
        );
      }

      if (messageList.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svgs/emptyStateIcon.svg',
              width: 60,
              height: 60,
            ),
            const SizedBox(height: 16),
            Text(
              localized(noHistoryYet),
              style: jxTextStyle.textStyleBold16(),
            ),
            Text(
              localized(yourHistoryIsEmpty),
              style: jxTextStyle.textStyle14(color: colorTextSecondary),
            ),
          ],
        );
      }

      return CustomScrollView(
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext builder, int index) {
                return Obx(() {
                  TaskContent task = taskList[index];

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => navigateToTaskDetail(task, messageList[index]),
                    child: TaskCell(task: task),
                  );
                });
              },
              childCount: messageList.length,
            ),
          ),
        ],
      );
    });
  }

  @override
  bool get wantKeepAlive => true;
}
