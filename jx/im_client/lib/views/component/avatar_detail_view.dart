import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

class AvatarDetailView extends StatelessWidget {
  final int nicknameId;
  final int avatarId;
  final bool? isGroup;

  const AvatarDetailView({
    super.key,
    required this.nicknameId,
    required this.avatarId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(
              child: Container(
                color: Colors.black,
              ),
            ),

            /// Profile Picture
            Center(
              child: Hero(
                tag: '$avatarId',
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  minScale: 0.1,
                  maxScale: 4.0,
                  child: CustomAvatar(
                    dataProvider:
                        DataProvider(uid: avatarId, isGroup: isGroup ?? false),
                    size: MediaQuery.of(context).size.width,
                    borderRadius: objectMgr.loginMgr.isDesktop ? 0 : null,
                  ),
                ),
              ),
            ),

            /// AppBar
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 8,
              left: 2,
              right: 0,
              child: const CustomLeadingIcon(
                backButtonColor: Colors.white,
                withBackTxt: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
