import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/utility.dart';

import '../../data/db_group.dart';
import '../../data/db_user.dart';
import '../../im/model/group/group.dart';
import '../../object/user.dart';
import '../../utils/color.dart';
import '../../utils/net/update_block_bean.dart';
import '../../utils/theme/text_styles.dart';

class CustomAvatar extends StatefulWidget {
  const CustomAvatar({
    Key? key,
    required this.uid,
    required this.size,
    this.isGroup = false,
    this.headMin,
    this.onTap,
    this.onLongPress,
    this.isFullPage = false,
    this.fontSize,
    this.isShowInitial = false,
    this.withEditEmptyPhoto = false,
    this.shouldAnimate = true,
    this.borderRadius,
  }) : super(key: key);
  final double size;
  final int uid;
  final bool isGroup;
  final int? headMin;
  final Function()? onTap;
  final Function()? onLongPress;
  final double? fontSize;
  final bool isFullPage;
  final bool isShowInitial;
  final bool withEditEmptyPhoto; //show camera icon
  final bool shouldAnimate;
  final double? borderRadius;

  @override
  State<CustomAvatar> createState() => _CustomAvatarState();
}

class _CustomAvatarState extends State<CustomAvatar> {
  String? avatarPath;
  String avatarName = '';

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

    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);

    objectMgr.on(ObjectMgr.eventKiwiConnect, onKiwiInit);

    ///这里只判断名字忽略path, 因为path没有默认名称
    _initData();
  }

  _initData() {
    if (widget.uid < 0) {
      return;
    }

    if (widget.uid == 0) {
      avatarName = '平台系统';
      return;
    }

    if (widget.isGroup) {
      Chat? chat = objectMgr.chatMgr.getChatById(widget.uid);
      final Group? group = objectMgr.myGroupMgr.getGroupById(widget.uid);
      if (group == null) {
        if (chat != null) {
          avatarName = chat.name;
          avatarPath = chat.icon;
        }

        _loadData();
        return;
      }

      avatarPath = group.icon;
      avatarName = group.name;
    }

    final User? user = objectMgr.userMgr.getUserById(widget.uid);
    if (user != null) {
      avatarPath = user.profilePicture;
      avatarName = objectMgr.userMgr.getUserTitle(user);
    } else {
      _loadData();
    }
  }

  _loadData() async {
    if (widget.isGroup) {
      final Group? group = await objectMgr.myGroupMgr.loadGroupById(widget.uid);
      if (group != null) {
        avatarPath = group.icon;
        avatarName = group.name;
        if (mounted) {
          setState(() {});
        }
      } else {
        Chat? chat = objectMgr.chatMgr.getChatById(widget.uid);
        if (chat != null) {
          avatarPath = chat.icon;
          avatarName = chat.name;
          if (mounted) {
            setState(() {});
          }
        }
      }
    } else {
      final User? user = await objectMgr.userMgr.loadUserById2(widget.uid);
      if (user != null && avatarPath != user.profilePicture) {
        avatarPath = user.profilePicture;
        avatarName = user.nickname;
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void _onChatUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is Chat && widget.uid == data.id) {
        final chat = data;

        ///若是头像或名字改变时，都需要更改头像
        if (avatarPath != data.icon || avatarName != data.name) {
          avatarPath = chat.icon;
          avatarName = chat.name;
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  onKiwiInit(sender, type, data) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(CustomAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.uid != widget.uid) {
      _initData();
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

    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);

    objectMgr.off(ObjectMgr.eventKiwiConnect, onKiwiInit);
    super.dispose();
  }

  void _onUserUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is User && data.uid == widget.uid) {
        ///若是头像或名字改变时，都需要更改头像
        if (this.avatarPath != data.profilePicture ||
            this.avatarName != objectMgr.userMgr.getUserTitle(data)) {
          this.avatarPath = data.profilePicture;
          this.avatarName = objectMgr.userMgr.getUserTitle(data);
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  void _onGroupUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is Group && widget.uid == data.uid) {
        ///若是头像或名字改变时，都需要更改头像
        if (avatarPath != data.icon || avatarName != data.name) {
          avatarPath = data.icon;
          avatarName = data.name;
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: widget.isFullPage ? buildFullAvatar() : _buildAvatarContainer(),
    );
  }

  Widget buildFullAvatar() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: notBlank(avatarPath)
            ? RemoteImage(
                src: avatarPath!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Container(color: const Color(0xFF4685BC)),
      ),
    );
  }

  Widget _buildAvatarContainer() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? widget.size),
        color: Colors.transparent,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildAvatarContent(),
    );
  }

  Widget _buildAvatarContent() {
    Widget child = const SizedBox();

    if (notBlank(avatarPath) && !widget.isShowInitial) {
      child = RemoteImage(
        src: avatarPath!,
        mini: widget.headMin,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      );
    } else {
      child = avatarFromNickName(avatarName);
    }

    if (widget.shouldAnimate) {
      child = AnimatedSwitcher(
        duration: const Duration(milliseconds: 50),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: child,
      );
    }

    return child;
  }

  Widget avatarFromNickName(String nickName) {
    if (widget.withEditEmptyPhoto) {
      return Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(25.0),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
        ),
        child: SvgPicture.asset(
          'assets/svgs/edit_camera_icon.svg',
          width: 50,
          height: 50,
          colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
        ),
      );
    }

    int themeIndex = _colorThemeFromNickName(nickName);
    themeIndex = widget.uid % 8;
    List<Color> colors = _avatarThemes[themeIndex];
    String shortName = shortNameFromNickName(nickName);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius ?? widget.size / 2.0)),
      ),
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Text(
          shortName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: MFontWeight.bold5.value,
            fontSize: widget.fontSize ??
                jxDimension.avatarFontSizeMap[widget.size] ??
                20 * widget.size / 60,
          ),
        ),
      ),
    );
  }
}

List<List<Color>> _avatarThemes = [
  [const Color(0xffFE9D7F), const Color(0xffF44545)],
  [const Color(0xffFFAE7B), const Color(0xffF07F38)],
  [const Color(0xffFBC87B), const Color(0xffFFA800)],
  [const Color(0xffAAF490), const Color(0xff52D05E)],
  [const Color(0xff85A3F9), const Color(0xff5D60F6)],
  [const Color(0xff7EC2F4), const Color(0xff3B90E1)],
  [const Color(0xff6BF0F9), const Color(0xff1EAECD)],
  [const Color(0xffD784FC), const Color(0xffB35AD1)],
];

int _colorThemeFromNickName(String nickName) {
  String md5 = _generateMD5(nickName);
  int index = md5.codeUnitAt(0) % 7;
  return index;
}

String _generateMD5(String data) {
  Uint8List content = const Utf8Encoder().convert(data);
  Digest digest = md5.convert(content);
  return digest.toString();
}
