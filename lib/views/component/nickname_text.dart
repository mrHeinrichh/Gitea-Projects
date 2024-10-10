import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class NicknameText extends StatefulWidget {
  final int uid;
  final String displayName;
  final bool isGroup;
  final Color color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double fontLineHeight;
  final double fontSpace;
  final TextAlign textAlign;
  final bool isTappable;
  final TextOverflow overflow;
  final int maxLine;
  final bool isRandomColor;
  final bool isShowYou;
  final bool isReply;
  final int? groupId;

  const NicknameText({
    super.key,
    required this.uid,
    this.displayName = '',
    this.isGroup = false,
    this.color = Colors.black,
    this.fontSize,
    this.fontWeight,
    this.fontLineHeight = 1.2,
    this.fontSpace = 0.15,
    this.textAlign = TextAlign.left,
    this.isTappable = true,
    this.overflow = TextOverflow.clip,
    this.maxLine = 1,
    this.isRandomColor = false,
    this.isShowYou = false,
    this.isReply = false,
    this.groupId,
  });

  @override
  State<StatefulWidget> createState() => NicknameTextState();
}

class NicknameTextState extends State<NicknameText> {
  User? user;
  Group? group;
  String displayName = '';
  String displayYouName =
      localized(you)[0].toUpperCase() + localized(you).substring(1);

  @override
  void initState() {
    super.initState();
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBGroup.tableName}", _onGroupUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBGroup.tableName}", _onGroupUpdate);
    displayName = widget.displayName;
    initData();
  }

  initData() {
    if (widget.uid == 0) return;

    if (widget.isGroup) {
      group = objectMgr.myGroupMgr.getGroupById(widget.uid);
      if (group != null) {
        displayName = group?.name ?? '';
        if (mounted) setState(() {});
      } else {
        loadData();
      }
    } else {
      user = objectMgr.userMgr.getUserById(widget.uid);
      if (user != null) {
        displayName =
            objectMgr.userMgr.getUserTitle(user, groupId: widget.groupId);
        if (mounted) setState(() {});
      } else {
        loadData();
      }
    }
  }

  loadData() async {
    if (widget.isGroup) {
      group = await objectMgr.myGroupMgr.loadGroupById(widget.uid);
      if (group != null) {
        if (mounted) {
          setState(() {
            displayName = group!.name;
          });
        }
      }
    } else {
      user = await objectMgr.userMgr.loadUserById2(widget.uid);
      if (mounted) {
        setState(() {
          displayName =
              objectMgr.userMgr.getUserTitle(user, groupId: widget.groupId);
        });
      }
    }
  }

  @override
  void didUpdateWidget(NicknameText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.uid != widget.uid) {
      initData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isTappable
          ? () {
              VolumePlayerService.sharedInstance.stopPlayer();
              VolumePlayerService.sharedInstance.resetPlayer();
              final id =
                  Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;

              if (widget.isGroup) {
                if (group != null) {
                  Get.toNamed(
                    RouteName.groupChatInfo,
                    arguments: {'groupId': group!.id},
                    id: objectMgr.loginMgr.isDesktop ? id : null,
                  );
                }
              } else {
                if (Get.isRegistered<ChatInfoController>()) {
                  Get.back();
                } else {
                  if (objectMgr.userMgr.isMe(widget.uid)) {
                    return;
                  }
                  Get.toNamed(
                    RouteName.chatInfo,
                    arguments: {
                      "uid": widget.uid,
                      "id": widget.uid,
                    },
                    id: objectMgr.loginMgr.isDesktop ? id : null,
                  );
                }
              }
            }
          : null,
      child: Text(
        (widget.isReply ? '${localized(reply)} ' : '') +
            (!widget.isShowYou ? displayName : displayYouName),
        style: TextStyle(
          fontWeight: widget.fontWeight ?? MFontWeight.bold4.value,
          fontSize: widget.fontSize ?? MFontSize.size14.value,
          color: widget.isRandomColor ? getColor() : widget.color,
          decoration: TextDecoration.none,
          height: widget.fontLineHeight,
          letterSpacing: widget.fontSpace,
        ).useSystemChineseFont(),
        maxLines: widget.maxLine,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
      ),
    );
  }

  void _onUserUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is User) {
        final user = data;
        if (widget.uid == user.uid) {
          String newDisplayName =
              objectMgr.userMgr.getUserTitle(user, groupId: widget.groupId);
          if (displayName != newDisplayName) {
            this.user = user;
            displayName = newDisplayName;
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    }
  }

  void _onGroupUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is Group) {
        final group = data;
        if (widget.uid == group.uid) {
          String newDisplayName = group.name;
          if (displayName != newDisplayName) {
            this.group = group;
            displayName = newDisplayName;
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    }
  }

  Color getColor() {
    if (user != null) {
      return groupMemberColor(user!.uid);
    } else {
      return widget.color;
    }
  }

  @override
  void dispose() {
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBGroup.tableName}", _onGroupUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBGroup.tableName}", _onGroupUpdate);
    super.dispose();
  }
}
