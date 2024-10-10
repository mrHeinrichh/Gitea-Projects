import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class DesktopChatMenu extends StatefulWidget {
  const DesktopChatMenu({
    super.key,
    required this.offset,
    required this.actions,
    required this.topBar,
  });

  final Offset offset;
  final List<Widget> actions;
  final Widget topBar;

  @override
  State<DesktopChatMenu> createState() => _DesktopChatMenuState();
}

class _DesktopChatMenuState extends State<DesktopChatMenu> {
  final GlobalKey _widgetKey = GlobalKey();
  double startingPoint = 0;

  @override
  void initState() {
    super.initState();
    startingPoint = widget.offset.dy;
    contentReplace();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      onSecondaryTap: () => Get.back(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            AnimatedPositioned(
              key: _widgetKey,
              left: getStartPosition(widget.offset.dx),
              top: startingPoint,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeIn,
              child: Column(
                children: [
                  widget.topBar,
                  const SizedBox(
                    height: 10,
                  ),
                  ...widget.actions,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getStartPosition(double offsetX) {
    final screenWidth = ObjectMgr.screenMQ!.size.width;
    if (offsetX + 300 >= screenWidth) {
      return offsetX - (offsetX + 350 - screenWidth);
    } else {
      return offsetX;
    }
  }

  void contentReplace() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final RenderBox renderBox =
          _widgetKey.currentContext!.findRenderObject() as RenderBox;
      final double widgetHeight = renderBox.size.height;
      final screenHeight = ObjectMgr.screenMQ!.size.height;
      if (widget.offset.dy + widgetHeight >= (screenHeight - 75)) {
        setState(() {
          final double yReplacement =
              widget.offset.dy + widgetHeight - screenHeight + 75;
          startingPoint = widget.offset.dy - yReplacement;
        });
      }
    });
  }
}
