import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class CustomAvatar extends StatefulWidget {
  const CustomAvatar(
      {super.key,
      required this.size,
      required this.dataProvider,
      this.headMin,
      this.onTap,
      this.onLongPress,
      this.fontSize,
      this.isShowInitial = false,
      this.withEditEmptyPhoto = false,
      this.shouldAnimate = true,
      this.borderRadius,
      this.tag = 'CustomAvatar'});

  final DataProvider dataProvider;
  final double size;
  final int? headMin;
  final Function()? onTap;
  final Function()? onLongPress;
  final double? fontSize;
  final bool isShowInitial;
  final bool withEditEmptyPhoto; //show camera icon
  final bool shouldAnimate;
  final double? borderRadius;
  final String? tag;

  CustomAvatar.normal(int uid,
      {super.key,
      required this.size,
      this.headMin,
      this.onTap,
      this.onLongPress,
      this.fontSize,
      this.isShowInitial = false,
      this.withEditEmptyPhoto = false,
      this.shouldAnimate = true,
      this.borderRadius,
      this.tag = 'CustomAvatar.normal'})
      : dataProvider = DataProvider(uid: uid);

  CustomAvatar.chat(Chat chat,
      {super.key,
      required this.size,
      this.headMin,
      this.onTap,
      this.onLongPress,
      this.fontSize,
      this.isShowInitial = false,
      this.withEditEmptyPhoto = false,
      this.shouldAnimate = true,
      this.borderRadius,
      this.tag = 'CustomAvatar.chat'})
      : dataProvider = DataProvider(
            uid: chat.isGroup ? chat.id : chat.friend_id,
            isGroup: chat.isGroup,
            chat: chat);

  CustomAvatar.user(User user,
      {super.key,
      required this.size,
      this.headMin,
      this.onTap,
      this.onLongPress,
      this.fontSize,
      this.isShowInitial = false,
      this.withEditEmptyPhoto = false,
      this.shouldAnimate = true,
      this.borderRadius,
      this.tag = 'CustomAvatar.user'})
      : dataProvider = DataProvider(user: user);

  CustomAvatar.group(Group group,
      {super.key,
      required this.size,
      this.headMin,
      this.onTap,
      this.onLongPress,
      this.fontSize,
      this.isShowInitial = false,
      this.withEditEmptyPhoto = false,
      this.shouldAnimate = true,
      this.borderRadius,
      this.tag = 'CustomAvatar.group'})
      : dataProvider = DataProvider(group: group, isGroup: true);

  @override
  State<CustomAvatar> createState() => _CustomAvatarState();
}

class _CustomAvatarState extends State<CustomAvatar> {
  String? oriPath;
  String? avatarPath;
  String avatarName = '';
  bool isLoaded = false;
  bool isShowInitial = false;
  bool showOriginal = false;

  @override
  void initState() {
    super.initState();
    showOriginal = false;
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
    _prepareData();
  }

  _prepareData() {
    if (widget.dataProvider.uid <= 0) {
      return;
    }

    isShowInitial = widget.isShowInitial;
    if (widget.dataProvider.chat != null) {
      oriPath = widget.dataProvider.chat!.icon;
      _preloadImageSync(widget.dataProvider.chat!.icon);
      avatarName = widget.dataProvider.chat!.name;
    } else if (widget.dataProvider.isGroup == false) {
      final User? user = widget.dataProvider.getUserSync();
      if (user != null) {
        if (user.deletedAt > 0) {
          oriPath = '';
        } else {
          oriPath = user.profilePicture;
        }
        _preloadImageSync(oriPath ?? '');
        avatarName = objectMgr.userMgr.getUserTitle(user);
      } else {
        _loadUserAsync(widget.dataProvider);
      }
    } else {
      final Group? group = widget.dataProvider.getGroupSync();
      if (group != null) {
        oriPath = group.icon;
        _preloadImageSync(group.icon);
        avatarName = group.name;
      } else {
        Chat? chat = widget.dataProvider.getChatSync();
        if (chat != null) {
          oriPath = chat.icon;
          _preloadImageSync(chat.icon);
          avatarName = chat.name;
        }
        _loadGroupAsync(widget.dataProvider);
      }
    }
    _reflushUI();
  }

  void _preloadImageSync(String icon) {
    if (icon.isEmpty) return;
    final gausPath = imageMgr.getBlurHashSavePath(icon);
    if (File(gausPath).existsSync()) {
      avatarPath = gausPath;
    }

    if (avatarPath?.isEmpty ?? true) {
      avatarPath = icon;
    }

    if (avatarPath == null || avatarPath!.isEmpty) return;

    String? thumbPath = downloadMgrV2.getLocalPath(
      icon,
      mini: widget.headMin,
    );

    if (thumbPath != null && thumbPath.isNotEmpty) {
      avatarPath = icon;
      _reflushUI();
      return;
    }

    _preloadImageAsync(icon);
  }

  void _preloadImageAsync(String icon) async {
    DownloadResult result = await downloadMgrV2.download(
      icon,
      mini: Config().headMin,
    );
    final thumbPath = result.localPath;

    // final thumbPath = await downloadMgr.downloadFile(
    //   icon,
    //   mini: Config().headMin,
    //   priority: 3,
    // );

    if (thumbPath != null && thumbPath.isNotEmpty) {
      avatarPath = icon;
      _reflushUI();
      return;
    }

    isShowInitial = true;
    avatarPath = null;
    _reflushUI();
  }

  _loadUserAsync(DataProvider avatarInfo) async {
    final User? user = await avatarInfo.getUserAsync();
    if (user != null &&
        (avatarPath != user.profilePicture || avatarName != user.nickname)) {
      _preloadImageSync(user.deletedAt > 0 ? '' : user.profilePicture);
      avatarName = user.nickname;
    }
  }

  _loadGroupAsync(DataProvider avatarInfo) async {
    final Group? group = await avatarInfo.getGroupAsync();
    if (group != null &&
        (avatarPath != group.icon || avatarName != group.icon)) {
      _preloadImageSync(group.icon);
      avatarName = group.name;
    }
  }

  void _onChatUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is Chat && widget.dataProvider.uid == data.id) {
        final chat = data;

        ///若是头像或名字改变时，都需要更改头像
        if (avatarPath != data.icon || avatarName != data.name) {
          avatarPath = chat.icon;
          avatarName = chat.name;
          _reflushUI();
        }
      }
    }
  }

  onKiwiInit(sender, type, data) {
    if (!isLoaded) {
      _reflushUI();
    }
  }

  @override
  void didUpdateWidget(CustomAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataProvider.uid != widget.dataProvider.uid) {
      _prepareData();
    }

    if (oldWidget.isShowInitial != widget.isShowInitial) {
      isShowInitial = widget.isShowInitial;
      _reflushUI();
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
    showOriginal = false;
    super.dispose();
  }

  bool _isRebuilding = false;

  _reflushUI() {
    if (_isRebuilding) return; // 如果已经在执行，则直接返回

    _isRebuilding = true; // 标记正在执行

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        setState(() {});
      }
      _isRebuilding = false; // 完成后重置标志
    });
  }

  void _onUserUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is User && data.uid == widget.dataProvider.uid) {
        ///若是头像或名字改变时，都需要更改头像
        if (avatarPath != data.profilePicture ||
            avatarName != objectMgr.userMgr.getUserTitle(data)) {
          avatarPath = data.profilePicture;
          avatarName = objectMgr.userMgr.getUserTitle(data);
          _reflushUI();
        }
      }
    }
  }

  void _onGroupUpdate(Object sender, Object type, Object? data) {
    var opt = type.toString()[0];
    if (opt == blockOptUpdate) {
      if (data is Group && widget.dataProvider.uid == data.uid) {
        ///若是头像或名字改变时，都需要更改头像
        if (avatarPath != data.icon || avatarName != data.name) {
          avatarPath = data.icon;
          avatarName = data.name;
          _reflushUI();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: _buildAvatarContainer(),
    );
  }

  Widget _buildAvatarContainer() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.all(
            Radius.circular(widget.borderRadius ?? widget.size)),
        child: _buildAvatarContent(),
      ),
    );
  }

  Widget _buildAvatarContent() {
    late Widget child;

    if (notBlank(avatarPath) && !isShowInitial) {
      child = Stack(
        children: [
          if (widget.headMin == null)
            RemoteImage(
              src: avatarPath!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              onLoadCallback: (File? file) {
                if (!showOriginal) {
                  showOriginal = true;
                  _reflushUI();
                }
              },
            ),
          Offstage(
            offstage: showOriginal,
            child: RemoteImageV2(
              src: avatarPath!,
              mini: avatarPath == imageMgr.getBlurHashSavePath(oriPath ?? '')
                  ? null
                  : widget.headMin ?? Config().headMin,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          ),
        ],
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
          color: themeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
        ),
        child: SvgPicture.asset(
          'assets/svgs/edit_camera_icon.svg',
          width: 50,
          height: 50,
          colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn),
        ),
      );
    }

    int themeIndex = _colorThemeFromNickName(nickName);
    themeIndex = widget.dataProvider.uid % 8;
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
        borderRadius: BorderRadius.all(
          Radius.circular(widget.borderRadius ?? widget.size / 2.0),
        ),
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
