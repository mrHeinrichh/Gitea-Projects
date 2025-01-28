import 'package:flutter/material.dart';
import 'package:jxim_client/utils/debug_info.dart';

import 'package:jxim_client/managers/object_mgr.dart';

class DesktopMessagePopMenu extends StatefulWidget {
  const DesktopMessagePopMenu({
    super.key,
    required this.offset,
    this.isSender = false,
    required this.popMenu,
    required this.menuHeight,
    required this.emojiSelector,
  });

  final Offset offset;
  final bool isSender;
  final Widget popMenu;
  final double menuHeight;
  final Widget emojiSelector;

  @override
  State<DesktopMessagePopMenu> createState() => _DesktopMessagePopMenuState();
}

class _DesktopMessagePopMenuState extends State<DesktopMessagePopMenu> {
  final GlobalKey _widgetKey = GlobalKey();
  double topStartingPoint = 0;
  double rightPosition = 0;

  @override
  void initState() {
    super.initState();
    topStartingPoint = widget.offset.dy;
    pdebug(widget.offset.dx);
    contentReplace();
  }

  void contentReplace() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final RenderBox renderBox =
          _widgetKey.currentContext!.findRenderObject() as RenderBox;
      final double widgetHeight = renderBox.size.height;
      final double widgetWidth = renderBox.size.height;
      final screenHeight = ObjectMgr.screenMQ!.size.height;
      final screenWidth = ObjectMgr.screenMQ!.size.width;
      if (widget.offset.dy + widgetHeight >= (screenHeight - 60)) {
        final double yReplacement =
            widget.offset.dy + widgetHeight - screenHeight + 60;
        topStartingPoint = widget.offset.dy - yReplacement;
      }
      pdebug('${widget.offset.dx + widgetWidth}');
      if (widget.isSender) {
        rightPosition = screenWidth - widget.offset.dx;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          key: _widgetKey,
          left: widget.isSender ? null : widget.offset.dx,
          right: widget.isSender ? rightPosition : null,
          top: topStartingPoint,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeIn,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              widget.emojiSelector,
              const SizedBox(height: 5),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 200,
                ),
                // height: widget.menuHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.popMenu,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
