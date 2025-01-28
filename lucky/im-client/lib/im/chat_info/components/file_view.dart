import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class FileView extends StatefulWidget {
  final Chat? chat;
  final bool isGroup;

  const FileView({
    super.key,
    required this.chat,
    required this.isGroup,
  });

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView>
    with AutomaticKeepAliveClientMixin {
  /// 加载状态
  final isLoading = false.obs;
  bool chatIsDeleted = false;

  final messageList = <Message>[].obs;

  /// 悬浮小窗参数
  OverlayEntry? floatWindowOverlay;
  Widget? overlayChild;
  final LayerLink layerLink = LayerLink();
  RenderBox? floatWindowRender;
  Offset? floatWindowOffset;

  bool singleAndNotFriend = false;

  ChatInfoController? get chatInfoController =>
      Get.isRegistered<ChatInfoController>()
          ? Get.find<ChatInfoController>()
          : null;

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  @override
  void initState() {
    super.initState();

    if (widget.chat != null) {
      if (widget.chat!.isSingle) {
        chatInfoController!.onMoreSelectCallback = onJumpToOriginalMessage;
        if (chatInfoController!.user.value!.relationship !=
            Relationship.friend) {
          singleAndNotFriend = true;
        }
      } else {
        groupInfoController!.onMoreSelectCallback = onJumpToOriginalMessage;
        if (widget.chat!.flag_my >= ChatStatus.MyChatFlagKicked.value) {
          chatIsDeleted = true;
        } else {
          chatIsDeleted = false;
        }
      }
      loadFileList();
    } else {
      singleAndNotFriend = true;
    }

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onFileMessageUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onMessageAutoDelete);

    if (!chatIsDeleted) {
      objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onMessageComing);
    }
  }

  _onFileMessageUpdate(sender, type, data) {
    if (data['id'] != widget.chat?.id || data['message'] == null) {
      return;
    }
    List<dynamic> delAsset = [];
    for (var item in data['message']) {
      int id = 0;
      int message_id = 0;
      if (item is Message) {
        id = item.id;
      } else {
        message_id = item;
      }
      for (final asset in messageList) {
        Message? msg = asset;
        if (id == 0) {
          if (msg.message_id == message_id) {
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

  _onMessageAutoDelete(sender, type, data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeFile) return;
      messageList.removeWhere((element) => element.message_id == data.message_id);
      return;
    }
  }

  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeFile) return;
      messageList.insert(0, data);
      return;
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onFileMessageUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onMessageAutoDelete);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onMessageComing);

    super.dispose();
  }

  loadFileList() async {
    if (messageList.isEmpty) isLoading.value = true;

    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND typ = ?',
      [
        widget.chat!.id,
        messageList.isEmpty
            ? widget.chat!.hide_chat_msg_idx
            : messageList.last.chat_idx - 1,
        messageTypeFile,
      ],
      'DESC',
      null,
    );
    List<Message> mList =
        tempList.map<Message>((e) => Message()..init(e)).toList();

    mList = mList
        .where((element) => !element.isDeleted && !element.isExpired)
        .toList();

    if (mList.isNotEmpty) {
      messageList.assignAll(mList);
    }

    isLoading.value = false;
  }

  onItemLongPress(Message message) async {
    if (widget.isGroup) {
      groupInfoController!.onMoreSelect.value = true;
      groupInfoController!.selectedMessageList.add(message);
    } else {
      chatInfoController!.onMoreSelect.value = true;
      chatInfoController!.selectedMessageList.add(message);
    }
  }

  onItemTap(Message message) {
    if (widget.isGroup) {
      if (groupInfoController!.selectedMessageList.contains(message)) {
        groupInfoController!.selectedMessageList.remove(message);
        if (groupInfoController!.selectedMessageList.isEmpty) {
          groupInfoController!.onMoreSelect.value = false;
        }
      } else {
        groupInfoController!.selectedMessageList.add(message);
      }
    } else {
      if (chatInfoController!.selectedMessageList.contains(message)) {
        chatInfoController!.selectedMessageList.remove(message);
        if (chatInfoController!.selectedMessageList.isEmpty) {
          chatInfoController!.onMoreSelect.value = false;
        }
      } else {
        chatInfoController!.selectedMessageList.add(message);
      }
    }
  }

  onJumpToOriginalMessage(Message message) {
    Get.back();
    if (widget.isGroup) {
      if (Get.isRegistered<GroupChatController>(
          tag: widget.chat!.id.toString())) {
        final groupController =
            Get.find<GroupChatController>(tag: widget.chat!.id.toString());
        groupController.clearSearching();
        groupController.locateToSpecificPosition([message.chat_idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    } else {
      if (Get.isRegistered<SingleChatController>(
          tag: widget.chat!.id.toString())) {
        final singleChatController =
            Get.find<SingleChatController>(tag: widget.chat!.id.toString());
        singleChatController.clearSearching();
        singleChatController.locateToSpecificPosition([message.chat_idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    }
  }

  bool fileIsSelected(int index) {
    return widget.isGroup
        ? groupInfoController!.selectedMessageList.contains(messageList[index])
        : chatInfoController!.selectedMessageList.contains(messageList[index]);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (!widget.isGroup) {
        if (chatInfoController!.user.value!.relationship !=
            Relationship.friend) {
          singleAndNotFriend = true;
        } else {
          singleAndNotFriend = false;
        }
      }

      if (isLoading.value) {
        return BallCircleLoading(
          radius: 20,
          ballStyle: BallStyle(
            size: 4,
            color: accentColor,
            ballType: BallType.solid,
            borderWidth: 1,
            borderColor: accentColor,
          ),
        );
      }

      if (singleAndNotFriend && messageList.isEmpty) {
        return Center(
          child: Text(localized(noItemFoundAddThisUserFirst)),
        );
      } else if (messageList.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding:
                  EdgeInsets.only(top: objectMgr.loginMgr.isDesktop ? 30.0 : 0),
              child: SvgPicture.asset(
                'assets/svgs/empty_state.svg',
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localized(noHistoryYet),
              style: jxTextStyle.textStyleBold16(),
            ),
            Text(
              localized(yourHistoryIsEmpty),
              style:
                  jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
            ),
          ],
        );
      } else {
        return CustomScrollView(
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext builder, int index) {
                  MessageFile file =
                      messageList[index].decodeContent(cl: MessageFile.creator);

                  return Obx(
                    () => GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (widget.isGroup) {
                          if (groupInfoController!.onMoreSelect.value) {
                            onItemTap(messageList[index]);
                          }
                        } else {
                          if (chatInfoController!.onMoreSelect.value) {
                            onItemTap(messageList[index]);
                          }
                        }
                      },
                      onLongPress: () {
                        if (widget.isGroup) {
                          if (!groupInfoController!.onMoreSelect.value) {
                            onItemLongPress(messageList[index]);
                          }
                        } else {
                          if (!chatInfoController!.onMoreSelect.value) {
                            onItemLongPress(messageList[index]);
                          }
                        }
                      },
                      child: Stack(
                        children: <Widget>[
                          FileItem(
                            message: messageList[index],
                            file: file,
                            onMoreSelected: widget.isGroup
                                ? groupInfoController!.onMoreSelect.value
                                : chatInfoController!.onMoreSelect.value,
                          ),
                          if (fileIsSelected(index))
                            Positioned(
                              left: 0.0,
                              right: 0.0,
                              bottom: 0.0,
                              top: 0.0,
                              child: ColoredBox(
                                color: systemColor.withOpacity(0.1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: messageList.length,
              ),
            ),
          ],
        );
      }
    });
  }
}

class FileItem extends StatelessWidget {
  final Message message;
  final MessageFile file;
  final bool onMoreSelected;

  const FileItem({
    super.key,
    required this.message,
    required this.file,
    required this.onMoreSelected,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onMoreSelected,
      child: GestureDetector(
        onTap: () async {
          var status = await Permission.storage.request();
          if (status.isDenied) {
            // The user did not grant permission, handle the situation as you see fit
          }
          cacheMediaMgr
              .downloadMedia(
            file.url,
            savePath: downloadMgr.getSavePath(file.file_name),
            timeoutSeconds: 3000,
          )
              .then((String? path) async {
            if (path == null) {
              Toast.showToast('Downloading or File is Not exist');
              return;
            }
            File? document = File(path);

            if (document.existsSync()) {
              final result = await OpenFilex.open(document.path);
              if (result.type == ResultType.noAppToOpen) {
                Toast.showToast('${result.message}');
              } else if (result.type == ResultType.fileNotFound) {
                Toast.showToast('${result.message}');
              } else if (result.type != ResultType.done) {
                Toast.showToast('${result.message}');
              }
            } else {
              Toast.showToast('Downloading or File is Not exist');
            }
          });
        },
        child: OverlayEffect(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// 文件图标
                ///  // Image.asset(
                //               //   fileIconNameWithSuffix(file.file_name),
                //               //   height: 40.0,
                //               //   width: 40.0,
                //               // ),
                Container(
                  height: 40,
                  width: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    color: accentColor,
                  ),
                  child: SvgPicture.asset(
                    'assets/svgs/file_icon.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.fill,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    decoration: BoxDecoration(
                      border: customBorder,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              /// 文件名
                              Text(
                                file.file_name,
                                style: jxTextStyle.textStyleBold16(
                                  fontWeight: MFontWeight.bold6.value,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              /// 文件大小以及时间
                              Row(
                                children: <Widget>[
                                  SvgPicture.asset(
                                    'assets/svgs/download_icon.svg',
                                    width: 12,
                                    height: 12,
                                    color: accentColor,
                                    fit: BoxFit.fill,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${fileSize(file.length)}',
                                    style: jxTextStyle.textStyle12(
                                      color: JXColors.secondaryTextBlack,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${FormatTime.chartTime(
                            message.create_time,
                            true,
                            todayShowTime: true,
                            dateStyle: DateStyle.MMDDYYYY,
                          )}',
                          style: jxTextStyle.textStyle14(
                            color: JXColors.secondaryTextBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
