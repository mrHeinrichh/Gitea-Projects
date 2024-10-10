part of '../index.dart';

class TapWidget extends StatelessWidget {
  final int clicktime = 200;

  final Widget child;
  final GestureTapCallback onTap;
  final GestureLongPressCallback? onLongPress;
  final GestureDragUpdateCallback? onPanUpdate;

  const TapWidget({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    int lastClickTime = 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        var dateTimeNowMilli = DateTime.now().millisecondsSinceEpoch;
        if (dateTimeNowMilli - lastClickTime > clicktime) {
          lastClickTime = dateTimeNowMilli;
          onPanUpdate?.call(details);
        }
      },
      onTap: () {
        var dateTimeNowMilli = DateTime.now().millisecondsSinceEpoch;
        if (dateTimeNowMilli - lastClickTime > clicktime) {
          lastClickTime = dateTimeNowMilli;
          onTap.call();
        }
      },
      onLongPress: onLongPress,
      child: child,
    );
  }
}
