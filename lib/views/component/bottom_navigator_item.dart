import 'dart:math';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/message/component/custom_angle.dart';
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class BottomNavigatorItem extends StatelessWidget {
  final int selectIndex;
  final int index;
  final Widget activeIcon;
  final Widget? inactiveIcon;
  final String? title;
  final int? badge;
  final bool? redDot; //小红点数据
  final Function(int index) onChange;
  final Function(int index)? onDoubleTap;
  final double? width;
  final double? height;
  final GlobalKey? badgeGlobalKey;
  final Function(int index)? onLongPress;
  final Function(LongPressMoveUpdateDetails details)? onLongPressMoveUpdate;
  final Function()? onLongPressUp;
  final bool hideBadge;


  const BottomNavigatorItem({
    super.key,
    required this.selectIndex,
    required this.index,
    required this.activeIcon,
    required this.onChange,
    this.inactiveIcon,
    this.badge,
    this.title,
    this.onDoubleTap,
    this.redDot,
    this.width = 24,
    this.height = 24,
    this.badgeGlobalKey,
    this.onLongPress,
    this.onLongPressMoveUpdate,
    this.onLongPressUp,
    this.hideBadge = false,
  })  : assert(
          (badge != null && redDot == null) ||
              (badge == null && redDot != null) ||
              (badge == null && redDot == null),
        );

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    List<Widget> children = <Widget>[];
    children.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 3),
          Flexible(
            child: (inactiveIcon == null || selectIndex == index)
                ? BounceOutWidget(
                    duration: const Duration(seconds: 2),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                      child: badge != null && badge != 0
                          ? Stack(
                              clipBehavior: Clip.none,
                              children: [
                                activeIcon,
                                Positioned(
                                  top: isDesktop ? -6 : -2.w,
                                  right: -12,
                                  child: hideBadge
                                      ? const SizedBox()
                                      : RepaintBoundary(
                                          key: badgeGlobalKey,
                                          child: CustomAngle(value: badge ?? 0),
                                        ),
                                ),
                              ],
                            )
                          : Stack(
                              clipBehavior: Clip.none,
                              children: [
                                activeIcon,
                                Visibility(
                                  visible: redDot ?? false,
                                  child: Positioned(
                                    top: isDesktop ? -3 : -3.w,
                                    right: isDesktop ? -3 : -3.w,
                                    child: const Icon(
                                      Icons.circle,
                                      color: colorRed,
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                    child: badge != null && badge != 0
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              inactiveIcon ?? activeIcon,
                              Positioned(
                                top: isDesktop ? -6 : -2.w,
                                right: -12,
                                child: CustomAngle(value: badge ?? 0),
                              ),
                            ],
                          )
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              inactiveIcon ?? activeIcon,
                              Visibility(
                                visible: redDot ?? false,
                                child: Positioned(
                                  top: isDesktop ? -3 : -3.w,
                                  right: isDesktop ? -3 : -3.w,
                                  child: const Icon(
                                    Icons.circle,
                                    color: colorRed,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title!,
                style: jxTextStyle.textStyleBold10(
                    color: selectIndex == index ? themeColor : colorTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );

    Stack stack = Stack(
      clipBehavior: Clip.none,
      children: children,
    );

    Widget child = stack;
    if (index == 3) {
      child = EventsWidget(
        data: objectMgr,
        eventTypes: const [ObjectMgr.eventNewVersion],
        builder: (BuildContext context) {
          return stack;
        },
      );
    }

    return Expanded(
      child: Listener(
        onPointerUp: (v) {
          onChange(index);
        },
        child: isDesktop
            ? DesktopGeneralButton(
                onPressed: () {},
                child: getChild(child),
              )
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  if (onDoubleTap != null) {
                    onDoubleTap!(index);
                  }
                },
                onLongPress: () => onLongPress?.call(index),
                onLongPressMoveUpdate: (details) => onLongPressMoveUpdate?.call(details),
                onLongPressUp: onLongPressUp,
                child: getChild(child),
              ),
      ),
    );
  }

  Widget getChild(Widget child) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(bottom: title == '' ? 9 : 0),
      height: 52,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class BounceOutWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BounceOutWidget({
    super.key,
    required this.child,
    required this.duration,
  });

  @override
  State<BounceOutWidget> createState() => _BounceOutWidgetState();
}

class _BounceOutWidgetState extends State<BounceOutWidget>
    with SingleTickerProviderStateMixin {
  late final controller =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween(begin: const Offset(0, -1e-2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: controller,
          curve: const _SpringCurve(amplitude: 35, w: 3 * pi * 5, damping: 0.5),
        ),
      ),
      child: widget.child,
    );
  }
}

class _SpringCurve extends Curve {
  const _SpringCurve({
    this.damping = sqrt1_2,
    this.w = 19.4,
    this.amplitude = 1,
  });

  final double w;
  final double damping;
  final double tShift = 0;
  final double amplitude;

  @override
  double transformInternal(double t) {
    final rad = w * sqrt(1 - pow(damping, 2).clamp(0, 1));
    final lambda = w * damping;
    final dt = tShift.clamp(0, 1);
    return t < dt
        ? 0
        : (pow(e, -(t - dt) * lambda) * cos((t - dt) * rad - pi / 2).abs()) *
            -amplitude;
  }
}

class ForwardBottomNavItem extends StatelessWidget {
  const ForwardBottomNavItem({
    super.key,
    required this.selectedCondition,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.title,
  });

  final bool selectedCondition;
  final String activeIcon;
  final String inactiveIcon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 5.h,
      ),
      child: Column(
        children: [
          Image.asset(
            selectedCondition ? activeIcon : inactiveIcon,
            width: 24.sp,
            height: 24.sp,
          ),
          Text(
            title,
            style: TextStyle(
              color: selectedCondition ? themeColor : colorTextSecondary,
              fontSize: 11.sp,
              fontWeight: MFontWeight.bold5.value,
            ),
          ),
        ],
      ),
    );
  }
}
