import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/components/emoji_panel_container.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';

class ChatPopAnimation extends StatefulWidget {
  final Widget child;
  final GlobalKey childKey;
  final Widget? topWidget;
  final Widget? bottomWidget;
  final Offset tapDetails;
  final bool isShow;
  final bool isGroup;
  final BubbleType? bubbleType;
  final double menuHeight;

  const ChatPopAnimation(
    this.child,
    this.childKey,
    this.tapDetails, {
    this.topWidget,
    this.bottomWidget,
    this.isShow = false,
    this.isGroup = false,
    super.key,
    this.bubbleType,
    this.menuHeight = 0,
  });

  @override
  State<ChatPopAnimation> createState() => _ChatPopAnimationState();
}

class _ChatPopAnimationState extends State<ChatPopAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animationValue;
  final kAniDuration = const Duration(milliseconds: 300);

  double totalWidgetHeight = 0.0;

  final GlobalKey childWidgetKey = GlobalKey();
  Offset childPosition = Offset.zero;
  Size childWidgetSize = Size.zero;

  final GlobalKey topWidgetKey = GlobalKey();
  Offset topWidgetPosition = Offset.zero;

  final GlobalKey bottomWidgetKey = GlobalKey();
  Offset bottomWidgetPosition = Offset.zero;

  late double _emojiWidgetHeight = 48.0;
  late double _menuWidgetHeight = 249.0;
  late double _bubbleWidgetHeight = 0.0;
  late double _totalWidgetHeight = 0.0;

  final _emojiWidgetPadding = 8.0;
  final _menuWidgetPadding = 8.0;

  double _emojiWidgetMovePadding = 0.0;

  late bool posTopFlag = false;
  late bool posSpecialEmoji = false;

  late double positionHorizontal = 0.0;

  late double positionEmojiVertical = 0.0;
  late double positionBubbleVertical = 0.0;
  late double positionMenuVertical = 0.0;

  double get positionVerticalMenu {
    double posY =
        positionBubbleVertical - childWidgetSize.height - _menuWidgetPadding;
    if (posY > 0) {
      return posY;
    }
    return 0.0;
  }

  late BubbleType? bubbleType = widget.bubbleType ?? BubbleType.receiverBubble;
  late double menuHeight = widget.menuHeight;

  late bool canScroller = true;

  @override
  void initState() {
    super.initState();

    objectMgr.stickerMgr
        .on(StickerMgr.keyShowEmojiPanelClick, _onShowEmojiPanelClick);
    objectMgr.stickerMgr
        .on(StickerMgr.keyChatPopMenuAreaEvent, _onChatPopMenuAreaEvent);

    _animationController = AnimationController(
      duration: kAniDuration,
      reverseDuration: const Duration(milliseconds: 0),
      vsync: this,
    );

    _animationValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animationController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.childKey.currentContext != null) {
        final RenderBox box =
            widget.childKey.currentContext!.findRenderObject() as RenderBox;
        childPosition = box.localToGlobal(Offset.zero);
        childWidgetSize = box.size;

        if (mounted) setState(() {});
        renderSubMenu();
      }
    });
  }

  void _onShowEmojiPanelClick(Object sender, Object type, Object? data) {
    if (mounted) {
      setState(() {
        renderSubMenu();
      });
    }
  }

  void _onChatPopMenuAreaEvent(Object sender, Object type, Object? data) {
    bool isInMenuArea = data as bool;
    canScroller = !isInMenuArea;
    if (mounted) setState(() {});
  }

  void renderSubMenu() {
    _emojiWidgetHeight = topWidgetKey.currentContext?.size?.height ?? 0;
    _bubbleWidgetHeight = childWidgetSize.height;
    _menuWidgetHeight = bottomWidgetKey.currentContext?.size?.height ?? 249;
    _menuWidgetHeight = menuHeight;

    final emojiWidgetWidth = topWidgetKey.currentContext?.size?.width ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;

    final screenHeight = MediaQuery.of(context).size.height;
    final topSafeHeight = MediaQuery.of(context).padding.top + 24;
    final bottomSafeHeight = MediaQuery.of(context).padding.bottom == 0.0
        ? 34.0
        : MediaQuery.of(context).padding.bottom;
    final screenSafeHeight = screenHeight - bottomSafeHeight - topSafeHeight;

    /// 总高度越界,气泡、菜单计算
    double originHeight = _emojiWidgetHeight +
        _emojiWidgetPadding +
        _bubbleWidgetHeight +
        _menuWidgetPadding +
        _menuWidgetHeight;
    if (originHeight >= screenSafeHeight) {
      _totalWidgetHeight = topSafeHeight +
          _emojiWidgetHeight +
          _emojiWidgetPadding +
          _bubbleWidgetHeight +
          _menuWidgetPadding +
          _menuWidgetHeight +
          bottomSafeHeight;

      // 总高度越界，需要滑动处理,且滑动位置从底部开始
      posSpecialEmoji = true;
      posTopFlag = true;
      positionEmojiVertical = topSafeHeight;
      positionBubbleVertical = _totalWidgetHeight -
          (bottomSafeHeight +
              _menuWidgetHeight +
              _menuWidgetPadding +
              _bubbleWidgetHeight +
              _emojiWidgetPadding);
      positionMenuVertical = _totalWidgetHeight -
          (bottomSafeHeight + _menuWidgetHeight + _menuWidgetPadding);
    } else {
      _totalWidgetHeight = screenSafeHeight;
      //未越界，屏幕内高度处理
      posSpecialEmoji = false;
      double heightYIn = childPosition.dy +
          _bubbleWidgetHeight +
          _menuWidgetPadding +
          _menuWidgetHeight;

      if ((childPosition.dy - _emojiWidgetHeight - _emojiWidgetPadding) <=
          topSafeHeight) {
        // 顶部超出，不能原位置展示,调整到最顶部距离
        posTopFlag = true;
        positionEmojiVertical = topSafeHeight;
        positionBubbleVertical =
            topSafeHeight + _emojiWidgetHeight + _emojiWidgetPadding;
        positionMenuVertical = topSafeHeight +
            _emojiWidgetHeight +
            _emojiWidgetPadding +
            _bubbleWidgetHeight +
            _menuWidgetPadding;
      } else {
        double heightYSc = screenHeight - bottomSafeHeight - topSafeHeight;

        if (heightYIn > heightYSc) {
          // 底部越界，不能原位置展示,调整到最底部距离
          posTopFlag = true;

          ///  方式1 顶部起坐标
          positionEmojiVertical = screenHeight -
              (_emojiWidgetHeight +
                  _emojiWidgetPadding +
                  _bubbleWidgetHeight +
                  _menuWidgetPadding +
                  _menuWidgetHeight +
                  bottomSafeHeight);
          positionBubbleVertical = screenHeight -
              (bottomSafeHeight +
                  _menuWidgetHeight +
                  _menuWidgetPadding +
                  _bubbleWidgetHeight);
          positionMenuVertical =
              screenHeight - (bottomSafeHeight + _menuWidgetHeight);

          /// 方式2 底部起坐标
          // positionMenuVertical = _bottomSafeHeight;
          // positionBubbleVertical =
          //     _bottomSafeHeight + _menuWidgetHeight + _menuWidgetPadding;
          // positionEmojiVertical = _emojiWidgetPadding +
          //     _bubbleWidgetHeight +
          //     _menuWidgetPadding +
          //     _menuWidgetHeight +
          //     _bottomSafeHeight;
        } else {
          // 原位置展示
          posTopFlag = true;
          positionBubbleVertical = childPosition.dy;
          positionEmojiVertical =
              childPosition.dy - _emojiWidgetHeight - _emojiWidgetPadding;
          positionMenuVertical =
              childPosition.dy + _bubbleWidgetHeight + _menuWidgetPadding;
        }
      }
    }

    if (objectMgr.stickerMgr.isShowEmojiPanel.value) {
      positionBubbleVertical =
          positionBubbleVertical - _emojiWidgetHeight + getEmojiPanelHeight();
    }

    /// menu 位置
    switch (bubbleType) {
      case BubbleType.sendBubble:
        positionHorizontal = 12;
        break;
      case BubbleType.receiverBubble:
        if (widget.isGroup) {
          positionHorizontal = 8;
        } else {
          positionHorizontal = 14;
        }
        break;
      case null:
    }

    final emojiTotalWidth = positionHorizontal + emojiWidgetWidth;
    if (emojiTotalWidth >= screenWidth) {
      _emojiWidgetMovePadding = emojiTotalWidth - screenWidth;
    }

    if (_animationController.isAnimating) {
      _animationController.stop();
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    objectMgr.stickerMgr
        .off(StickerMgr.keyShowEmojiPanelClick, _onShowEmojiPanelClick);
    objectMgr.stickerMgr
        .off(StickerMgr.keyChatPopMenuAreaEvent, _onChatPopMenuAreaEvent);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatPopAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isShow != oldWidget.isShow) {
      if (widget.isShow) {
        _animationController.forward();
      } else {
        _animationController.stop();
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'pingfang',
        decoration: TextDecoration.none,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              physics:
                  canScroller ? null : const NeverScrollableScrollPhysics(),
              reverse: true,
              child: IntrinsicHeight(
                child: Stack(
                  alignment: AlignmentDirectional.bottomStart,
                  fit: StackFit.loose,
                  children: <Widget>[
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height,
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      height: _totalWidgetHeight,
                    ),
                    AnimatedPositioned(
                      key: childWidgetKey,
                      top: posTopFlag ? positionBubbleVertical : null,
                      bottom: posTopFlag ? null : positionBubbleVertical,
                      left: childPosition.dx,
                      duration: kAniDuration,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            bubbleType == BubbleType.receiverBubble
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: childWidgetSize.width,
                            height: childWidgetSize.height,
                            child: widget.child,
                          ),
                          // SizedBox(
                          //   height: _menuWidgetPadding,
                          // ),
                          // if (widget.bottomWidget != null)
                          //   Transform.scale(
                          //     // alignment: Alignment.topLeft,
                          //     scale: _animationValue.value,
                          //     child: FadeTransition(
                          //       opacity: _animationValue,
                          //       child: Padding(
                          //           padding: EdgeInsets.only(
                          //               left: positionHorizontal,
                          //               right: positionHorizontal),
                          //           child: widget.bottomWidget!),
                          //     ),
                          //   ),
                        ],
                      ),
                    ),
                    if (widget.bottomWidget != null &&
                        !objectMgr.stickerMgr.isShowEmojiPanel.value)
                      Positioned(
                        left: bubbleType == BubbleType.receiverBubble
                            ? positionHorizontal
                            : null,
                        right: bubbleType == BubbleType.receiverBubble
                            ? null
                            : positionHorizontal,
                        top: posTopFlag ? positionMenuVertical : null,
                        bottom: posTopFlag ? null : positionMenuVertical,
                        key: bottomWidgetKey,
                        child: Transform.scale(
                          alignment: Alignment.topCenter,
                          scale: _animationValue.value,
                          child: FadeTransition(
                            opacity: _animationValue,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: widget.bottomWidget!,
                            ),
                          ),
                        ),
                      ),
                    if (!posSpecialEmoji) _setUpEmojiWidget(),
                  ],
                ),
              ),
            ),
            if (posSpecialEmoji) _setUpEmojiWidget(),
          ],
        ),
      ),
    );
  }

  Widget _setUpEmojiWidget() {
    if (widget.topWidget != null) {
      return Positioned(
        left: bubbleType == BubbleType.receiverBubble
            ? positionHorizontal - _emojiWidgetMovePadding
            : null,
        right: bubbleType == BubbleType.receiverBubble
            ? null
            : positionHorizontal - _emojiWidgetMovePadding,
        top: posTopFlag ? positionEmojiVertical : null,
        bottom: posTopFlag ? null : positionEmojiVertical,
        key: topWidgetKey,
        child: Transform.scale(
          scale: _animationValue.value,
          alignment: objectMgr.stickerMgr.isShowEmojiPanel.value
              ? Alignment.center
              : (bubbleType == BubbleType.receiverBubble
                  ? Alignment.centerLeft
                  : Alignment.centerRight),
          child: FadeTransition(
            opacity: _animationValue,
            child: AnimatedContainer(
              duration: kAniDuration,
              height: getEmojiPanelHeight(),
              child: widget.topWidget!,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
