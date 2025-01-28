import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/user.dart';
import 'package:crypto/crypto.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';

final liveLocationUtils = LiveLocationUtils();

class LiveLocationUtils {
  LiveLocationUtils._internal();

  factory LiveLocationUtils() => _instance;

  static final LiveLocationUtils _instance = LiveLocationUtils._internal();

  List<List<Color>> avatarThemes = [
    [const Color(0xffFE9D7F), const Color(0xffF44545)],
    [const Color(0xffFFAE7B), const Color(0xffF07F38)],
    [const Color(0xffFBC87B), const Color(0xffFFA800)],
    [const Color(0xffAAF490), const Color(0xff52D05E)],
    [const Color(0xff85A3F9), const Color(0xff5D60F6)],
    [const Color(0xff7EC2F4), const Color(0xff3B90E1)],
    [const Color(0xff6BF0F9), const Color(0xff1EAECD)],
    [const Color(0xffD784FC), const Color(0xffB35AD1)],
  ];

  int colorThemeFromNickName(String nickName) {
    String md5 = generateMD5(nickName);
    int index = md5.codeUnitAt(0) % 7;
    return index;
  }

  String generateMD5(String data) {
    Uint8List content = const Utf8Encoder().convert(data);
    Digest digest = md5.convert(content);
    return digest.toString();
  }

  Future<Uint8List?> widgetToImage(GlobalKey globalKey) async {
    Future<Uint8List?> convert() async {
      RenderRepaintBoundary boundary =
          globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      ui.Image? image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();
      return pngBytes;
    }

    try {
      return await convert();
    } catch (e) {
      debugPrint('[widgetToImage]: convert widget to image error $e');
      await Future.delayed(const Duration(milliseconds: 200));
      return await convert();
    }
  }

  Future<String?> getShortNameById(int uid) async {
    final User? user = objectMgr.userMgr.getUserById(uid);
    if (user != null) {
      return shortNameFromNickName(user.nickname);
    } else {
      final User? user = await objectMgr.userMgr.getRemoteUser(uid);

      if (user != null) {
        return shortNameFromNickName(user.nickname);
      }
    }
    return null;
  }

  Future<Widget> getAvatar() async {
    final userId = objectMgr.localStorageMgr.userID;
    final User? user = objectMgr.userMgr.getUserById(userId);
    assert(user != null, 'getAvatar: user can not be none');
    if (notBlank(user?.profilePicture)) {
      return await getAvatarById();
    }
    final nickname = shortNameFromNickName(user!.nickname);
    return getAvatarByNickname(nickname);
  }

  Widget getAvatarByNickname(String nickName) {
    int themeIndex = colorThemeFromNickName(nickName);
    final userId = objectMgr.localStorageMgr.userID;
    themeIndex = userId % 8;
    List<Color> colors = avatarThemes[themeIndex];
    const size = 80.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(size / 2)),
      ),
      alignment: Alignment.center,
      child: Text(
        nickName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: MFontWeight.bold5.value,
          fontSize: 30,
        ),
      ),
    );
  }

  Future<Widget> getAvatarById() async {
    final userId = objectMgr.localStorageMgr.userID;
    final User? user = objectMgr.userMgr.getUserById(userId);
    late String? profilePicture;
    if (user != null) {
      profilePicture = user.profilePicture;
    } else {
      final User? user = await objectMgr.userMgr.loadUserById2(userId);
      if (user != null) {
        profilePicture = user.profilePicture;
      }
    }
    assert(profilePicture != null);
    return ClipOval(
      child: RemoteImage(
        src: profilePicture!,
        mini: Config().headMin,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }
}
