import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/components/file_icon.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet_info.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/chat_pop_animation_info.dart';
import 'package:jxim_client/im/services/file_download_service.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:open_filex/open_filex.dart';

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

class _FileViewState extends MessageWidgetMixin<FileView>
    with AutomaticKeepAliveClientMixin {
  /// 加载状态
  final isLoading = false.obs;
  bool chatIsDeleted = false;

  final messageList = <Message>[].obs;

  final List<TargetWidgetKeyModel> _keyList = [];

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
      if (widget.chat!.isSingle || widget.chat!.isSpecialChat) {
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
        int index = messageList.indexOf(item);
        _keyList.removeAt(index);
        messageList.remove(item);
      }
    }
  }

  _onMessageAutoDelete(sender, type, data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeFile) return;
      messageList
          .removeWhere((element) => element.message_id == data.message_id);
      return;
    }
  }

  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeFile) return;
      if (data.isEncrypted) return;
      messageList.insert(0, data);
      TargetWidgetKeyModel model = TargetWidgetKeyModel(0, GlobalKey());
      _keyList.insert(0, model);
      for (Message msg in messageList) {
        if (data.id == msg.id && msg.message_id == 0) {
          messageList.remove(msg);
          break;
        }
      }
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
      'chat_id = ? AND chat_idx > ? AND typ = ? AND ref_typ == 0',
      [
        widget.chat!.id,
        messageList.isEmpty
            ? widget.chat!.hide_chat_msg_idx
            : messageList.last.chat_idx - 1,
        messageTypeFile,
      ],
      'DESC',
      null,
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
    return WillPopScope(
      onWillPop: Platform.isAndroid
          ? () async {
              resetPopupWindow();
              return true;
            }
          : null,
      child: Obx(() {
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
              color: themeColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: themeColor,
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
                padding: EdgeInsets.only(
                    top: objectMgr.loginMgr.isDesktop ? 30.0 : 0),
                child: SvgPicture.asset(
                  'assets/svgs/empty_state.svg',
                  width: 60,
                  height: 60,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localized(noHistoryYet),
                style:
                    jxTextStyle.headerText(fontWeight: MFontWeight.bold5.value),
              ),
              Text(
                localized(yourHistoryIsEmpty),
                style: jxTextStyle.normalText(color: colorTextSecondary),
              ),
            ],
          );
        } else {
          _keyList.clear();
          if (widget.isGroup) {
            groupInfoController?.setUpItemKey(messageList, _keyList);
          } else {
            chatInfoController?.setUpItemKey(messageList, _keyList);
          }

          return CustomScrollView(
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext builder, int index) {
                    MessageFile file = messageList[index]
                        .decodeContent(cl: MessageFile.creator);

                    Widget child = FileItem(
                      message: messageList[index],
                      file: file,
                      onMoreSelected: widget.isGroup
                          ? groupInfoController!.onMoreSelect.value
                          : chatInfoController!.onMoreSelect.value,
                    );
                    TargetWidgetKeyModel model = _keyList[index];

                    return Obx(
                      () => GestureDetector(
                        key: model.targetWidgetKey,
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) {
                          tapPosition = details.globalPosition;
                        },
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
                          vibrate();
                          if (objectMgr.loginMgr.isDesktop) {
                            if (widget.isGroup) {
                              if (!groupInfoController!.onMoreSelect.value) {
                                onItemLongPress(messageList[index]);
                              }
                            } else {
                              if (!chatInfoController!.onMoreSelect.value) {
                                onItemLongPress(messageList[index]);
                              }
                            }
                          } else {
                            if (widget.chat != null) {
                              final msg = messageList[index];
                              enableFloatingWindowInfo(
                                context,
                                widget.chat!.id,
                                msg,
                                child,
                                model.targetWidgetKey,
                                tapPosition,
                                ChatPopMenuSheetInfo(
                                  message: msg,
                                  chat: widget.chat!,
                                  sendID: msg.send_id,
                                  menuClick: (String title) {
                                    resetPopupWindow();
                                  },
                                ),
                                chatPopAnimationType:
                                    ChatPopAnimationType.right,
                                menuHeight: ChatPopMenuSheetInfo.getMenuHeight(
                                  msg,
                                  widget.chat!,
                                ),
                              );
                            }
                          }
                        },
                        child: Stack(
                          children: <Widget>[
                            child,
                            if (fileIsSelected(index))
                              const Positioned(
                                left: 0.0,
                                right: 0.0,
                                bottom: 0.0,
                                top: 0.0,
                                child: ColoredBox(
                                  color: colorBackground6,
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
      }),
    );
  }
}

class FileItem extends StatefulWidget {
  final Message message;
  final MessageFile file;
  final bool onMoreSelected;

  /// for searchView only
  final bool? isSearch;
  final String? searchText;

  const FileItem({
    super.key,
    required this.message,
    required this.file,
    required this.onMoreSelected,
    this.isSearch = false,
    this.searchText,
  });

  @override
  State<FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<FileItem> {
  Message get message => widget.message;

  MessageFile get file => widget.file;

  bool get onMoreSelected => widget.onMoreSelected;

  bool isExist = false;

  MessageFile get fileMessage {
    final fileMessage = message.decodeContent(cl: MessageFile.creator);
    return fileMessage;
  }

  bool get _shouldShowCover {
    return shouldShowCover(fileMessage.url);
  }

  bool get hasThumbnail {
    final thumbnailUrl = fileMessage.cover;
    return thumbnailUrl.isNotEmpty == true;
  }

  bool get isEncrypt {
    final isEncrypt = fileMessage.isEncrypt;
    return isEncrypt == 1;
  }

  Map<String, String> get chatNameMap {
    if (widget.isSearch == true) {
      return getChatNameMap(widget.message);
    } else {
      return {};
    }
  }

  Widget getThumbnail() {
    if (isEncrypt) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/file/red-file.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Image.asset(
          'assets/icons/file/lock-file.png',
          width: 20,
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: RemoteImage(
          src: fileMessage.cover,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          mini: Config().headMin,
        ),
      );
    }
  }

  String get pathWithFileName =>
      '${fileMessage.url.substring(0, fileMessage.url.lastIndexOf("/"))}/${fileMessage.file_name}';

  final downloadString = ''.obs;
  final downloadProgress = 0.0.obs;
  final isDownloading = false.obs;
  CancelToken cancelToken = CancelToken();

  void _onTap() async {
    if (isDownloading.value) {
      cancelToken.cancel();
      isDownloading.value = false;
    }

    final localFilePathWithName =
        '${downloadMgr.appDocumentRootPath}/$pathWithFileName';

    File localFile = File(file.filePath);

    if (!localFile.existsSync()) {
      localFile = File(localFilePathWithName);
    }

    if (!localFile.existsSync()) {
      final localPath = downloadMgr.checkLocalFile(widget.file.url);
      if (localPath != null) {
        localFile = File(localPath);
      }
    }

    File? document;
    try {
      if (!isExist || !localFile.existsSync()) {
        isDownloading.value = true;
        DownloadResult result = await downloadMgrV2.download(
          file.url,
          timeout: const Duration(seconds: 3000),
          onReceiveProgress: (received, total) {
            downloadProgress.value = received / total;
            downloadString.value = "${fileSize(received)}/";
          },
        );
        final path = result.localPath;

        if (path == null) {
          return;
        }
        localFile = File(path);
        // 在确认下载完成后发送事件
        fileDownloadService.event(
            fileDownloadService, FileDownloadService.fileDownloadComplete,
            data: {'localPath': localFile.path, 'url': file.url});
      }

      setState(() {
        isExist = true;
      });

      if (!File(localFilePathWithName).existsSync()) {
        File(localFilePathWithName).createSync(recursive: true);
        File(localFilePathWithName).writeAsBytesSync(
          localFile.readAsBytesSync(),
        );
        localFile.deleteSync();
      }

      document = File(localFilePathWithName);
    } catch (e, s) {
      pdebug('Error: $e', stackTrace: s);
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0.0;
      downloadString.value = '';
      cancelToken = CancelToken();
    }

    if (document?.existsSync() ?? false) {
      final result = await OpenFilex.open(document!.path);
      if (result.type == ResultType.noAppToOpen) {
        Toast.showToast(result.message);
      } else if (result.type == ResultType.fileNotFound) {
        Toast.showToast(result.message);
      } else if (result.type != ResultType.done) {
        Toast.showToast(result.message);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    checkFileDownload();
  }

  void checkFileDownload() {
    try {
      String combinedFileName =
          '${downloadMgr.appDocumentRootPath}/$pathWithFileName';

      if (file.filePath.isNotEmpty &&
          (File(file.filePath).existsSync() ||
              File(combinedFileName).existsSync())) {
        if (File(file.filePath).existsSync()) {
          isExist = true;
        } else {
          isExist = checkFileSize(combinedFileName);
        }
      } else {
        if (File(combinedFileName).existsSync()) {
          isExist = checkFileSize(combinedFileName);
        } else {
          final localPath = downloadMgrV2.getLocalPath(widget.file.url);
          if (localPath != null) {
            isExist = checkFileSize(localPath);
            return;
          }
          if ((file.size != null && file.size <= 5 * 1024 * 1024)) {
            final fileExist = downloadMgrV2.getLocalPath(widget.file.url);
            if (fileExist != null) {
              int fileSize = File(widget.file.url).lengthSync();
              if (fileSize == widget.file.size) {
                isExist = true;
                return;
              }
            }
            isExist = false;
          } else {
            isExist = false;
          }
        }
      }
    } catch (_) {}
  }

  bool checkFileSize(String url) {
    int fileSize = File(url).lengthSync();
    if (fileSize < file.size) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onMoreSelected,
      child: GestureDetector(
        onTap: _onTap,
        child: OverlayEffect(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: _shouldShowCover && hasThumbnail
                          ? getThumbnail()
                          : FileIcon(fileName: file.file_name),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            /// 文件名

                            RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: getHighlightSpanList(
                                  file.file_name,
                                  widget.searchText,
                                  jxTextStyle.headerText(
                                      fontWeight: MFontWeight.bold5.value),
                                  needCut: notBlank(widget.searchText),
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Visibility(
                              visible: widget.isSearch == true &&
                                  notBlank(widget.searchText) &&
                                  notBlank(file.caption),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    children: getHighlightSpanList(
                                      file.caption,
                                      widget.searchText,
                                      jxTextStyle.normalSmallText(
                                        color: colorTextSecondary,
                                      ),
                                      needCut: notBlank(widget.searchText),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// 文件大小以及时间
                            Row(
                              children: <Widget>[
                                Visibility(
                                  visible: !isExist,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 5.0),
                                    child: Obx(() {
                                      return SvgPicture.asset(
                                        isDownloading.value
                                            ? 'assets/svgs/Pause.svg'
                                            : 'assets/svgs/download_icon.svg',
                                        width: 12,
                                        height: 12,
                                        color: themeColor,
                                        fit: BoxFit.fill,
                                      );
                                    }),
                                  ),
                                ),
                                Obx(() {
                                  return Text(
                                    "${downloadString.value}${fileSize(file.size)}",
                                    style: jxTextStyle.normalSmallText(
                                      color: colorTextSecondary,
                                    ),
                                  );
                                }),
                                Text(
                                  ' · ',
                                  style: jxTextStyle.normalSmallText(
                                    color: colorTextSecondary,
                                  ),
                                ),
                                Text(
                                  FormatTime.getFullDayTime(
                                    message.create_time,
                                  ),
                                  style: jxTextStyle.normalSmallText(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ],
                            ),

                            Visibility(
                              visible: chatNameMap.isNotEmpty,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      chatNameMap['first'] ?? '',
                                      style: jxTextStyle.normalSmallText(
                                        color: colorTextSecondary,
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        size: 12,
                                        color: colorTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      chatNameMap['second'] ?? '',
                                      style: jxTextStyle.normalSmallText(
                                        color: colorTextSecondary,
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
                  ],
                ),
                SizedBox(
                  height: 1,
                  child: Obx(() {
                    return LinearProgressIndicator(
                      value: downloadProgress.value,
                      color: themeColor,
                      backgroundColor: Colors.transparent,
                    );
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 64.0),
                  child: CustomDivider(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
