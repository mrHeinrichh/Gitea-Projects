import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import '../../data/db_group.dart';
import '../../data/db_user.dart';
import '../../home/home_controller.dart';
import '../../im/model/group/group.dart';
import '../../main.dart';
import '../../object/user.dart';
import '../../routes.dart';
import '../../utils/net/update_block_bean.dart';

class NicknameText extends StatefulWidget {
  final int uid;
  final displayName;
  final bool isGroup;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final double fontLineHeight;
  final double fontSpace;
  final TextAlign textAlign;
  final bool isTappable;
  final TextOverflow overflow;
  final int maxLine;
  final bool isRandomColor;
  final bool isShowYou; // show "you" when you are the account user

  NicknameText({
    Key? key,
    required this.uid,
    this.displayName = '',
    this.isGroup = false,
    this.color = Colors.black,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.normal,
    this.fontLineHeight = 1.2,
    this.fontSpace = 0.15,
    this.textAlign = TextAlign.left,
    this.isTappable = true,
    this.overflow = TextOverflow.clip,
    this.maxLine = 1,
    this.isRandomColor = false,
    this.isShowYou = false,
  }) : super(key: key);

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
    if (!notBlank(displayName)) {
      initData();
    }
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
        displayName = objectMgr.userMgr.getUserTitle(user);
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
            this.displayName = group!.name;
          });
        }
      }
    } else {
      user = await objectMgr.userMgr.loadUserById2(widget.uid);
      if (mounted) {
        setState(() {
          displayName = objectMgr.userMgr.getUserTitle(user);
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
                  Get.toNamed(RouteName.groupChatInfo,
                      arguments: {'groupId': group!.id},
                      id: objectMgr.loginMgr.isDesktop ? id : null);
                }
              } else {
                if (Get.isRegistered<ChatInfoController>()) {
                  Get.back();
                } else {
                  if (objectMgr.userMgr.isMe(widget.uid)) {
                    return;
                  }
                  Get.toNamed(RouteName.chatInfo,
                      arguments: {
                        "uid": widget.uid,
                        "id": widget.uid,
                      },
                      id: objectMgr.loginMgr.isDesktop ? id : null);
                }
              }
            }
          : null,
      child: Text(
        /// add alias here
        !widget.isShowYou ? displayName : displayYouName,
        style: TextStyle(
          fontWeight: widget.fontWeight,
          fontSize: widget.fontSize,
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
          String newDisplayName = objectMgr.userMgr.getUserTitle(user);
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
    super.dispose();
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBGroup.tableName}", _onGroupUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBGroup.tableName}", _onGroupUpdate);
  }
}
