import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/components/emoji_panel_container.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum ChatPopAnimationType {
  left,
  right,
  center,
}

class ChatPopAnimationInfo extends StatefulWidget {
  final Widget child;
  final GlobalKey childKey;
  final Widget? topWidget;
  final Widget? bottomWidget;
  final Offset tapDetails;
  final bool isShow;
  final ChatPopAnimationType? chatPopAnimationType;
  final double menuHeight;

  const ChatPopAnimationInfo(
    this.child,
    this.childKey,
    this.tapDetails, {
    this.topWidget,
    this.bottomWidget,
    this.isShow = false,
    super.key,
    this.chatPopAnimationType,
    this.menuHeight = 0,
  });

  @override
  State<ChatPopAnimationInfo> createState() => _ChatPopAnimationInfoState();
}

class _ChatPopAnimationInfoState extends State<ChatPopAnimationInfo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animationValue;
  final _kAniDuration = const Duration(milliseconds: 300);

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

  late double _screenWidth = 0.0;
  late double _screenHeight = 0.0;

  final _emojiWidgetPadding = 8.0;
  final _menuWidgetPadding = 8.0;

  double _emojiWidgetMovePadding = 0.0;

  late bool posTopFlag = false;
  late bool posSpecialEmoji = false;

  late double positionHorizontal = 0.0;

  late double positionEmojiVertical = 0.0;
  late double positionBubbleVertical = 0.0;
  late double positionMenuVertical = 0.0;

  late double childWidgetSizeHeight = childWidgetSize.height;

  double get positionVerticalMenu {
    double posY =
        positionBubbleVertical - childWidgetSizeHeight - _menuWidgetPadding;
    if (posY > 0) {
      return posY;
    }
    return 0.0;
  }

  late ChatPopAnimationType? chatPopAnimationType =
      widget.chatPopAnimationType ?? ChatPopAnimationType.left;
  late double menuHeight = widget.menuHeight;

  @override
  void initState() {
    super.initState();

    objectMgr.stickerMgr
        .on(StickerMgr.keyShowEmojiPanelClick, _onShowEmojiPanelClick);

    _animationController = AnimationController(
      duration: _kAniDuration,
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

  void renderSubMenu() {
    _emojiWidgetHeight = topWidgetKey.currentContext?.size?.height ?? 0;
    _bubbleWidgetHeight = childWidgetSizeHeight;
    _menuWidgetHeight = bottomWidgetKey.currentContext?.size?.height ?? 249;
    _menuWidgetHeight = menuHeight;

    final emojiWidgetWidth = topWidgetKey.currentContext?.size?.width ?? 0;
    _screenWidth = MediaQuery.of(context).size.width;

    _screenHeight = MediaQuery.of(context).size.height;
    final topSafeHeight = MediaQuery.of(context).padding.top + 24;
    final bottomSafeHeight = MediaQuery.of(context).padding.bottom == 0.0
        ? 34.0
        : MediaQuery.of(context).padding.bottom;
    final screenSafeHeight = _screenHeight - bottomSafeHeight - topSafeHeight;

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
        double heightYSc = _screenHeight - bottomSafeHeight - topSafeHeight;

        if (heightYIn > heightYSc) {
          // 底部越界，不能原位置展示,调整到最底部距离
          posTopFlag = true;

          ///  方式1 顶部起坐标
          positionEmojiVertical = _screenHeight -
              (_emojiWidgetHeight +
                  _emojiWidgetPadding +
                  _bubbleWidgetHeight +
                  _menuWidgetPadding +
                  _menuWidgetHeight +
                  bottomSafeHeight);
          positionBubbleVertical = _screenHeight -
              (bottomSafeHeight +
                  _menuWidgetHeight +
                  _menuWidgetPadding +
                  _bubbleWidgetHeight);
          positionMenuVertical =
              _screenHeight - (bottomSafeHeight + _menuWidgetHeight);

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
    switch (chatPopAnimationType) {
      case ChatPopAnimationType.right:
        positionHorizontal = 16.0;
        break;
      case ChatPopAnimationType.left:
        positionHorizontal = 16.0;
        break;
      case null:
      case ChatPopAnimationType.center:
    }

    final emojiTotalWidth = positionHorizontal + emojiWidgetWidth;
    if (emojiTotalWidth >= _screenWidth) {
      _emojiWidgetMovePadding = emojiTotalWidth - _screenWidth;
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatPopAnimationInfo oldWidget) {
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
                    _setUpCenterWidget(),
                    if (widget.bottomWidget != null &&
                        !objectMgr.stickerMgr.isShowEmojiPanel.value)
                      _setUpMenuWidget(),
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

  Widget _setUpCenterWidget() {
    Widget centerChild;
    if (chatPopAnimationType == ChatPopAnimationType.center) {
      centerChild = Positioned(
        key: childWidgetKey,
        top: posTopFlag ? positionBubbleVertical : null,
        bottom: posTopFlag ? null : positionBubbleVertical,
        // left: childPosition.dx,
        child: SizedBox(
          width: _screenWidth,
          // color: Colors.red,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: childWidgetSize.width,
                height: childWidgetSize.height,
                child: widget.child,
              ),
            ],
          ),
        ),
      );
    } else {
      centerChild = AnimatedPositioned(
        key: childWidgetKey,
        top: posTopFlag ? positionBubbleVertical : null,
        bottom: posTopFlag ? null : positionBubbleVertical,
        // left: childPosition.dx,
        duration: _kAniDuration,
        child: VisibilityDetector(
          key: const ValueKey('chatPopAnimationInfo_menu_key'),
          onVisibilityChanged: (VisibilityInfo info) {
            if (info.visibleFraction == 1) {
              if (mounted) {
                setState(() {
                  childWidgetSizeHeight = info.size.height;
                  renderSubMenu();
                });
              }
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: _getCenterCrossAxisAlignment(),
            children: [
              SizedBox(
                width: childWidgetSize.width,
                // height: childWidgetSize.height,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return centerChild;
  }

  CrossAxisAlignment _getCenterCrossAxisAlignment() {
    CrossAxisAlignment crossAxisAlignment;
    switch (chatPopAnimationType) {
      case ChatPopAnimationType.left:
        crossAxisAlignment = CrossAxisAlignment.start;
      case ChatPopAnimationType.right:
        crossAxisAlignment = CrossAxisAlignment.end;
      case ChatPopAnimationType.center:
        crossAxisAlignment = CrossAxisAlignment.center;
      default:
        crossAxisAlignment = CrossAxisAlignment.start;
    }
    return crossAxisAlignment;
  }

  Widget _setUpEmojiWidget() {
    if (widget.topWidget != null) {
      return Positioned(
        left: chatPopAnimationType == ChatPopAnimationType.left
            ? positionHorizontal - _emojiWidgetMovePadding
            : null,
        right: chatPopAnimationType == ChatPopAnimationType.left
            ? null
            : positionHorizontal - _emojiWidgetMovePadding,
        top: posTopFlag ? positionEmojiVertical : null,
        bottom: posTopFlag ? null : positionEmojiVertical,
        key: topWidgetKey,
        child: Transform.scale(
          scale: _animationValue.value,
          alignment: objectMgr.stickerMgr.isShowEmojiPanel.value
              ? Alignment.center
              : (chatPopAnimationType == ChatPopAnimationType.left
                  ? Alignment.centerLeft
                  : Alignment.centerRight),
          child: FadeTransition(
            opacity: _animationValue,
            child: AnimatedContainer(
              duration: _kAniDuration,
              height: getEmojiPanelHeight(),
              child: widget.topWidget!,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _setUpMenuWidget() {
    Widget menuChild;
    if (chatPopAnimationType == ChatPopAnimationType.center) {
      menuChild = Positioned(
        top: posTopFlag ? positionMenuVertical : null,
        bottom: posTopFlag ? null : positionMenuVertical,
        key: bottomWidgetKey,
        child: Transform.scale(
          alignment: Alignment.topCenter,
          scale: _animationValue.value,
          child: FadeTransition(
            opacity: _animationValue,
            child: SizedBox(
              // color: Colors.red,
              width: _screenWidth,
              child: UnconstrainedBox(
                child: widget.bottomWidget!,
              ),
            ),
          ),
        ),
      );
    } else {
      menuChild = AnimatedPositioned(
        left: chatPopAnimationType == ChatPopAnimationType.left
            ? positionHorizontal
            : null,
        right: chatPopAnimationType == ChatPopAnimationType.left
            ? null
            : positionHorizontal,
        top: posTopFlag ? positionMenuVertical : null,
        bottom: posTopFlag ? null : positionMenuVertical,
        key: bottomWidgetKey,
        duration: _kAniDuration,
        child: Transform.scale(
          alignment: Alignment.topCenter,
          scale: _animationValue.value,
          child: FadeTransition(
            opacity: _animationValue,
            child: widget.bottomWidget!,
          ),
        ),
      );
    }
    return menuChild;
  }
}
