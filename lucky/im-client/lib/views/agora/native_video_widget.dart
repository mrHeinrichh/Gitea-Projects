import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/utils.dart';
import 'dart:io';

import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/user.dart';

class NativeVideoWidget extends StatelessWidget {
  final int uid;
  final bool isBigScreen;

  const NativeVideoWidget({super.key, required this.uid, required this.isBigScreen});

  @override
  Widget build(BuildContext context) {
    User? user = objectMgr.callMgr.opponent;
    String avatarUrl = user != null && notBlank(user?.profilePicture) ? "${serversUriMgr.download2Uri}/${user?.profilePicture}" : "";
    String nickname = objectMgr.userMgr.getUserTitle(user);

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'native_video_widget',
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: {'uid': uid, 'nickname': nickname, 'remoteProfile': avatarUrl, 'isBigScreen': isBigScreen},
        onPlatformViewCreated: (int id) {

        },
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'native_video_widget',
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: {'uid': uid, 'nickname': nickname, "remoteProfile": avatarUrl, 'isBigScreen': isBigScreen},
        onPlatformViewCreated: (int id) {},
      );
    }
    return const Text('Platform not support');
  }
}
