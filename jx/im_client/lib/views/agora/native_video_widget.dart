import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debug_info.dart';

class NativeVideoWidget extends StatelessWidget {
  final int uid;
  final bool isBigScreen;
  final int retryCount;

  const NativeVideoWidget({
    super.key,
    required this.uid,
    required this.isBigScreen,
    this.retryCount = 0,
  });

  Future<Map<String, String?>> getAvatar() async {
    User? user = objectMgr.callMgr.opponent;
    String? userNickname = objectMgr.userMgr.getUserTitle(user);
    String avatarUrl = await objectMgr.callMgr.getAvatarUrl(user);

    return {
      'avatarUrl': avatarUrl,
      'nickname': userNickname,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
        future: getAvatar(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // 获取数据
            final data = snapshot.data!;
            String avatarUrl = data['avatarUrl']!;
            String nickname = data['nickname']!;

            if (Platform.isAndroid) {
              pdebug("NativeVideoWidget========> ");
              return AndroidView(
                key: ValueKey('$uid-$retryCount'),
                viewType: 'native_video_widget',
                creationParamsCodec: const StandardMessageCodec(),
                creationParams: {
                  'uid': uid,
                  'nickname': nickname,
                  'remoteProfile': avatarUrl,
                  'isBigScreen': isBigScreen,
                },
                onPlatformViewCreated: (int id) {},
              );
            } else if (Platform.isIOS) {
              return UiKitView(
                viewType: 'native_video_widget',
                key: ValueKey('$uid-$retryCount'),
                creationParamsCodec: const StandardMessageCodec(),
                creationParams: {
                  'uid': uid,
                  'nickname': nickname,
                  "remoteProfile": avatarUrl,
                  'isBigScreen': isBigScreen,
                },
                onPlatformViewCreated: (int id) {},
              );
            }
          }

          // 如果没有数据，显示默认的内容
          return const SizedBox();
        });
  }
}
