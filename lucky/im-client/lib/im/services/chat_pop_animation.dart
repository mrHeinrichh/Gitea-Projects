import 'package:flutter/material.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';

class ChatPopAnimation extends StatefulWidget {
  final Widget child;
  final GlobalKey childKey;
  final Widget? topWidget;
  final Widget? bottomWidget;
  final Offset tapDetails;
  final bool isShow;
  final BubbleType? bubbleType;
  final double menuHeight;

  const ChatPopAnimation(
    this.child,
    this.childKey,
    this.tapDetails, {
    this.topWidget,
    this.bottomWidget,
    this.isShow = false,
    super.key,
    this.bubbleType,
    this.menuHeight = 0,
  });

  @override
  State<ChatPopAnimation> createState() => _ChatPopAnimationState();
}

class _ChatPopAnimationState extends State<ChatPopAnimation>
    with SingleTickerProviderStateMixin {
  final double _kPadding = 10.0;

  late final AnimationController _animationController;
  late final Animation<double> _animationValue;

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
  late double menuHeight = widget.menuHeight ?? 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
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

  void renderSubMenu() {
    _emojiWidgetHeight = topWidgetKey.currentContext?.size?.height ?? 0;
    _bubbleWidgetHeight = childWidgetSize.height;
    _menuWidgetHeight = bottomWidgetKey.currentContext?.size?.height ?? 249;
    _menuWidgetHeight = menuHeight;

    final _screenHeight = MediaQuery.of(context).size.height;
    final _topSafeHeight = MediaQuery.of(context).padding.top + 24;
    final _bottomSafeHeight = MediaQuery.of(context).padding.bottom == 0.0
        ? 34.0
        : MediaQuery.of(context).padding.bottom;
    final _screenSafeHeight = _screenHeight - _bottomSafeHeight - _topSafeHeight;

    /// 总高度越界,气泡、菜单计算
    double originHeight = _emojiWidgetHeight +
        _emojiWidgetPadding +
        _bubbleWidgetHeight +
        _menuWidgetPadding +
        _menuWidgetHeight;
    if (originHeight >= _screenSafeHeight) {
      _totalWidgetHeight = _topSafeHeight +
          _emojiWidgetHeight +
          _emojiWidgetPadding +
          _bubbleWidgetHeight +
          _menuWidgetPadding +
          _menuWidgetHeight +
          _bottomSafeHeight;

      // 总高度越界，需要滑动处理,且滑动位置从底部开始
      posSpecialEmoji = true;
      posTopFlag = true;
      positionEmojiVertical = _topSafeHeight;
      positionBubbleVertical = _totalWidgetHeight -
          (_bottomSafeHeight +
              _menuWidgetHeight +
              _menuWidgetPadding +
              _bubbleWidgetHeight +
              _emojiWidgetPadding);
      positionMenuVertical = _totalWidgetHeight -
          (_bottomSafeHeight + _menuWidgetHeight + _menuWidgetPadding);
    } else {
      _totalWidgetHeight = _screenSafeHeight;
      //未越界，屏幕内高度处理
      posSpecialEmoji = false;
      double _heightYIn = childPosition.dy +
          _bubbleWidgetHeight +
          _menuWidgetPadding +
          _menuWidgetHeight;

      if ((childPosition.dy - _emojiWidgetHeight - _emojiWidgetPadding) <= _topSafeHeight) {
        // 顶部超出，不能原位置展示,调整到最顶部距离
        posTopFlag = true;
        positionEmojiVertical = _topSafeHeight;
        positionBubbleVertical =
            _topSafeHeight + _emojiWidgetHeight + _emojiWidgetPadding;
        positionMenuVertical = _topSafeHeight +
            _emojiWidgetHeight +
            _emojiWidgetPadding +
            _bubbleWidgetHeight +
            _menuWidgetPadding;
      } else {
        double _heightYSc = _screenHeight - _bottomSafeHeight - _topSafeHeight;

        if (_heightYIn > _heightYSc) {
          // 底部越界，不能原位置展示,调整到最底部距离
          posTopFlag = true;

          ///  方式1 顶部起坐标
          positionEmojiVertical = _screenHeight -
              (_emojiWidgetHeight +
                  _emojiWidgetPadding +
                  _bubbleWidgetHeight +
                  _menuWidgetPadding +
                  _menuWidgetHeight +
                  _bottomSafeHeight);
          positionBubbleVertical = _screenHeight -
              (_bottomSafeHeight +
                  _menuWidgetHeight +
                  _menuWidgetPadding +
                  _bubbleWidgetHeight);
          positionMenuVertical =
              _screenHeight - (_bottomSafeHeight + _menuWidgetHeight);

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

    /// menu 位置
    switch (bubbleType) {
      case BubbleType.sendBubble:
        positionHorizontal = 8;
        break;
      case BubbleType.receiverBubble:
        positionHorizontal = 16;
        break;
      case null:
        // TODO: Handle this case.
    }

    if (_animationController.isAnimating) {
      _animationController.stop();
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
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
                    Positioned(
                      key: childWidgetKey,
                      top: posTopFlag ? positionBubbleVertical : null,
                      bottom: posTopFlag ? null : positionBubbleVertical,
                      left: childPosition.dx,
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
                    if (widget.bottomWidget != null)
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
                            child: widget.bottomWidget!,
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
        left:
            bubbleType == BubbleType.receiverBubble ? positionHorizontal : null,
        right:
            bubbleType == BubbleType.receiverBubble ? null : positionHorizontal,
        top: posTopFlag ? positionEmojiVertical : null,
        bottom: posTopFlag ? null : positionEmojiVertical,
        key: topWidgetKey,
        child: Transform.scale(
          scale: _animationValue.value,
          alignment: Alignment.centerRight,
          child: FadeTransition(
            opacity: _animationValue,
            child: widget.topWidget!,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
