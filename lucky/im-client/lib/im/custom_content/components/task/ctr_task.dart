import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jxim_client/api/chat.dart' as chat_api;

import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/components/task/sub_task_detail.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/task_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/register/components/themedAlertDialog.dart';

class CtrTask extends GetxController {
  /// VARIABLES
  late Rx<TaskContent> task;
  late Chat chat;
  late Message message;
  final GroupChatInfoController groupInfoController =
      Get.find<GroupChatInfoController>();

  final GlobalKey moreKey = GlobalKey();
  OverlayEntry? floatWindowOverlay;
  final LayerLink layerLink = LayerLink();
  RenderBox? floatWindowRender;
  Offset? floatWindowOffset;

  /// METHODS
  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments as Map<String, dynamic>;

    if (!arguments.containsKey('task') ||
        !arguments.containsKey('chat') ||
        !arguments.containsKey('message')) {
      Get.back();
      return;
    }

    task = Rx<TaskContent>(arguments['task'] as TaskContent);
    chat = arguments['chat'] as Chat;
    message = arguments['message'] as Message;

    objectMgr.taskMgr.on(MgrTask.UPDATE_TASK, onStatusUpdate);
  }

  @override
  void onClose() {
    objectMgr.taskMgr.off(MgrTask.UPDATE_TASK, onStatusUpdate);
    super.onClose();
  }

  void onStatusUpdate(Object sender, Object type, Object? data) {
    if (data is SubTask && data.taskId == task.value.taskId) {
      final subTask = task.value.subtasks.firstWhere(
          (element) => element.subTaskId == data.subTaskId,
          orElse: () => SubTask());
      subTask.status = data.status;
      task.refresh();
    }
  }

  void onChangeStatus(BuildContext context, SubTask subTask, int index) {
    Toast.showBottomSheet(
      context: context,
      container: SubTaskDetail(chat: chat, task: task.value, subTask: subTask),
    );
  }

  void onMoreTap(BuildContext context) {
    List<ToolOptionModel> optionModelList = [
      ToolOptionModel(
        title: localized(findInChat),
        optionType: MessagePopupOption.findInChat.optionType,
        icon: Icons.find_in_page_outlined,
        color: JXColors.primaryTextBlack,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
      ToolOptionModel(
        title: localized(deleteForEveryone),
        optionType: DeletePopupOption.deleteForMe.optionType,
        color: Colors.red,
        largeDivider: false,
        isShow: true,
        tabBelonging: 1,
      ),
    ];

    floatWindowRender = moreKey.currentContext!.findRenderObject() as RenderBox;
    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
    } else {
      floatWindowRender =
          moreKey.currentContext!.findRenderObject() as RenderBox;
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);

      var left = floatWindowOffset!.dx;
      var top = floatWindowOffset!.dy;
      var targetAnchor = Alignment.bottomRight;
      var followerAnchor = Alignment.topRight;

      List<int> uids = [
        task.value.creatorUid,
        ...task.value.subtasks.map<int>((e) => e.uid).toList(),
      ];
      if (!uids.contains(objectMgr.userMgr.mainUser.uid)) {
        optionModelList[1].isShow = false;
      }

      floatWindowOverlay = createOverlayEntry(
        context,
        IconButton(
          onPressed: () => onMoreTap(context),
          icon: const Icon(Icons.more_vert),
        ),
        Container(
          width: 200.0,
          decoration: BoxDecoration(
            color: JXColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: JXColors.bgTertiaryColor,
                offset: Offset(0, 2),
                blurRadius: 4.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(optionModelList.length, (index) {
              ToolOptionModel optionModel = optionModelList[index];
              return GestureDetector(
                onTap: () => onActionTap(context, optionModel),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: JXColors.bgTertiaryColor,
                      ),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    optionModel.title,
                    style: TextStyle(
                      color: optionModel.color,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        layerLink,
        left: left,
        right: null,
        top: top,
        bottom: null,
        targetAnchor: targetAnchor,
        followerAnchor: followerAnchor,
        dismissibleCallback: () {
          floatWindowOffset = null;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
        },
      );
    }
  }

  void onActionTap(BuildContext context, ToolOptionModel option) {
    if (option.title == localized(findInChat)) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
      if (Get.isRegistered<GroupChatController>(tag: chat.id.toString())) {
        final groupController =
            Get.find<GroupChatController>(tag: chat.id.toString());
        Get.close(2);

        groupController.clearSearching();
        groupController.locateToSpecificPosition([message.chat_idx]);
      } else {
        Get.close(3);
        Routes.toChat(chat: chat, selectedMsgIds: [message]);
      }
    } else if (option.title == localized(deleteForMe)) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
      // groupInfoController.onDeleteForMeTap(context, task.value.taskId);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return ThemedAlertDialog(
              title: '${localized(delete)} ${task.value.title}?',
              confirmButtonText: localized(delete),
              confirmButtonColor: Colors.red,
              confirmButtonCallback: () => onDeleteTask(context),
              cancelButtonText: localized(cancel),
              cancelButtonCallback: Get.back,
            );
          });
    }
  }

  void onDeleteTask(BuildContext context) {
    deleteMessages(
      [message],
      chat.id,
      isAll: true,
    );
    Get.back();
  }

  Future<void> deleteMessages(
    List<dynamic> messages,
    int? chatId, {
    bool isAll = false,
  }) async {
    List<Message> remoteMessages = [];
    List<int> remoteMessageIds = [];
    // filter fake message
    messages.forEach((msg) {
      if (msg is Message) {
        if (msg.message_id == 0 && !msg.isSendOk) {
          objectMgr.chatMgr.mySendMgr.remove(msg);
        } else {
          remoteMessages.add(msg);
          remoteMessageIds.add(msg.message_id);
        }
      } else if (msg is AlbumDetailBean) {
        Message? bean = msg.currentMessage;
        if (bean != null) {
          if (bean.message_id == 0 && !bean.isSendOk) {
            objectMgr.chatMgr.mySendMgr.remove(bean);
          } else {
            remoteMessages.add(bean);
            remoteMessageIds.add(bean.message_id);
          }
        } else {
          pdebug("前面逻辑出了问题");
          throw "检查代码";
        }
      }
    });

    if (remoteMessages.length > 0) {
      chat_api.deleteMsg(
        chatId ?? remoteMessages.first.chat_id,
        remoteMessageIds,
        isAll: isAll,
      );

      remoteMessages.forEach((message) {
        objectMgr.chatMgr.localDelMessage(message);
      });
    }
  }
}
