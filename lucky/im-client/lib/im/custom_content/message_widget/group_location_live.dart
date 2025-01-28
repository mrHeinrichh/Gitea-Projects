import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_input/component/circular_count_down.dart';
import 'package:jxim_client/im/custom_input/component/location_item.dart';
import 'package:jxim_client/im/custom_input/location_sharing_btn.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/live_location_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'group_location_live_map.dart';

class GroupLocationLive extends StatefulWidget {
  final Chat chat;
  final MessageMyLocation messageLocation;

  final String role;

  const GroupLocationLive({
    super.key,
    required this.chat,
    required this.messageLocation,
    required this.role,
  });

  @override
  State<GroupLocationLive> createState() => _GroupLocationLiveState();
}

class _GroupLocationLiveState extends State<GroupLocationLive> {
  final userId = objectMgr.localStorageMgr.userID;
  late final nickname;
  late int countDownSec;
  late double animateProgress;

  @override
  void initState() {
    nickname = objectMgr.userMgr.getUserById(userId)?.nickname;
    _updateDuration();
    if (widget.role == 'sender') {
      liveLocationManager.addCurLocationToBase();
    }
    super.initState();
  }

  void _updateDuration() {
    final now = DateTime.now();
    final startTime =
        DateTime.fromMillisecondsSinceEpoch(widget.messageLocation.startTime!);
    final difference = now.difference(startTime).inSeconds;
    final duration =
        Duration(milliseconds: widget.messageLocation.duration!).inSeconds;
    final newDuration = Duration(seconds: duration - difference);
    liveLocationManager.updateDurationMap(
      friendId: widget.chat.friend_id,
      duration: newDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    updateCountDownSec();
    animateProgress = countDownSec /
        Duration(milliseconds: widget.messageLocation.duration!).inSeconds;
    return SafeArea(
      child: Column(
        children: [
          _buildCloseBtn(context),
          Expanded(
            child: GroupLocationLiveMap(
              chat: widget.chat,
              messageLocation: widget.messageLocation,
              role: widget.role,
            ),
          ),
          if (widget.role == 'me')
            _buildLocationItemMe()
          else if (widget.role == 'sender')
            _buildLocationItemSender(),
          LocationSharingBtn(
            key: UniqueKey(),
            chat: widget.chat,
            value: countDownSec > 0,
            onChanged: (bool value) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  LocationItem _buildLocationItemMe() {
    return LocationItem(
      avatarUid: userId,
      title: nickname,
      subTitle: countDownSec > 0
          ? 'Updated just now'
          : 'Updated in realtime as you move',
      rightWidget: Padding(
        padding: const EdgeInsets.only(right: 17),
        child: Center(
          child: countDownSec > 0 && LiveLocationManager.enable
              ? CircularCountdown(
                  countDownSec: countDownSec,
                  animationProgress: animateProgress,
                  onChanged: (int value) {
                    liveLocationManager.updateDurationMap(
                      friendId: widget.chat.friend_id,
                      duration: Duration(seconds: value),
                    );
                    updateCountDownSec();
                    if (value <= 0) {
                      liveLocationManager.disableLiveLocation(
                        friendId: widget.chat.friend_id,
                      );
                      LiveLocationManager.enable = false;
                      setState(() {
                        countDownSec = 0;
                      });
                    }
                  },
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void updateCountDownSec() {
    countDownSec = LiveLocationManager.enable
        ? LiveLocationManager.durationMap[widget.chat.friend_id]?.inSeconds ?? 0
        : 0;
  }

  LocationItem _buildLocationItemSender() {
    return LocationItem(
      avatarUid: userId,
      title: nickname,
      subTitle: countDownSec > 0
          ? 'Updated just now'
          : 'Updated in realtime as you move',
      rightWidget: Padding(
        padding: const EdgeInsets.only(right: 17),
        child: Center(
          child: countDownSec > 0 && LiveLocationManager.enable
              ? CircularCountdown(
                  countDownSec: countDownSec,
                  animationProgress: animateProgress,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Container _buildCloseBtn(BuildContext context) {
    return Container(
      height: 50,
      color: JXColors.white,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localized(walletInformationClose),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              localized(location),
              style: jxTextStyle.textStyleBold16(),
            ),
          ),
        ],
      ),
    );
  }
}
