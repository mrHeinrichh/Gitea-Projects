import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class PushMessage extends StatefulWidget {
  final dynamic data;
  final VoidCallback callback;

  const PushMessage({super.key, required this.data, required this.callback});

  @override
  PushMessageState createState() => PushMessageState();
}

class PushMessageState extends State<PushMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> slide;

  Timer? _timer;
  int currentTime = 4;

  @override
  void initState() {
    super.initState();
    _init();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    slide = Tween<double>(begin: 0, end: -170)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.ease));
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _close();
      } else if (status == AnimationStatus.dismissed) {}
    });
  }

  _close() {
    if (_timer != null) _timer?.cancel();
    // objectMgr.pushMessageMgr.checkUserMsgShow = false;
    BotToast.removeAll('pushUserMessage');
  }

  _init() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentTime--;
      if (currentTime == -1) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    if (_timer != null) _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  //消息提醒框
  Widget _messageNotice() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.callback,
          child: Container(
            padding: EdgeInsets.only(left: 4.w, top: 4.w, bottom: 4.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(25.5.r)),
              gradient: LinearGradient(
                colors: [hexColor(0x5A98FA), hexColor(0x53DBED)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(150),
                    border: Border.all(
                      width: 1,
                      color: hexColor(0xFFFFFF, alpha: 0.41),
                    ),
                  ),
                  child: CustomAvatar.normal(
                    widget.data['id'],
                    size: 40,
                  ),
                ), //需要调整，离线推送也要区分单聊和群聊
                SizedBox(
                  width: 6.w,
                ),
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width / 3,
                        ),
                        child: Text(
                          widget.data['name'],
                          style: TextStyle(
                            color: colorWhite,
                            fontSize: 14.sp,
                            fontWeight: MFontWeight.bold5.value,
                            decoration: TextDecoration.none,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Text(
                        widget.data['content'],
                        style: TextStyle(
                          color: colorWhite,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.normal,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onHorizontalDragUpdate: (v) {
            if (v.delta.dx > 6) {
              _controller.forward();
            }
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Positioned(
                  bottom: 60.w,
                  right: slide.value,
                  child: SafeArea(
                    child: _messageNotice(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
