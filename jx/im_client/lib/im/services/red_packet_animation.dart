import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

/// 红包动画组件
///
/// [**coverWidget**] 红包封面组件
///
/// 想要显示在封面上的 内容可以通过这个组件去填充
///
/// [**contentWidget**] 红包卡片组件
///
/// 需自定义内容的样式以及内容排版
///
/// [**redPacketCover**] 红包封面装饰图片
///
/// 例： 小云朵， 小金钱
///
/// [**redPacketOpen**] 红包打开装饰图片
///
/// 放置 启动动画按钮的 图标
///
///
/// [List<Color> topFoldGradient, bottomFoldGradient, bodyGradient, cardGradient]
/// [List<int> topFoldStops, bottomFoldStops, bodyStops, cardStops]
///
/// [**topFoldGradient**]
/// 红包翻开以后的内里颜色 - 渐变色
///
/// 需配合 [**topFoldStops**] 使用
///
/// *两个list的数量必须一致*
///
///
/// [**bottomFoldGradient**]
/// 红包翻开以前的表面颜色 - 渐变色
///
/// 需配合 [**bottomFoldStops**] 使用
///
/// *两个list的数量必须一致*
///
///
/// [**bodyGradient**]
/// 红包卡片封面背景颜色 - 渐变色
///
/// 需配合 [**bodyStops**] 使用
///
/// *两个list的数量必须一致*
///
/// [**cardGradient**]
/// 红包卡片内容背景颜色 - 渐变色
///
/// 需配合 [**cardStops**] 使用
///
/// *两个list的数量必须一致*
///
/// [**enableOpenAnimation**] 是否启用打开动画
///
/// [**onTapCallback**] 点击回调
///
/// [**showEndStatus**] 是否显示结束状态
///
class RedPacketAnimation extends StatefulWidget {
  final Widget cover;
  final Widget contentWidget;
  final Widget topFold;
  final Shader Function(Rect bounds)? shaderCallback;
  final bool isOpen;

  const RedPacketAnimation({
    super.key,
    required this.cover,
    required this.contentWidget,
    required this.topFold,
    required this.isOpen,
    this.shaderCallback,
  });

  @override
  State<RedPacketAnimation> createState() => _RedPacketAnimationState();
}

class _RedPacketAnimationState extends State<RedPacketAnimation>
    with TickerProviderStateMixin {
  late AnimationController animateController;

  @override
  void initState() {
    super.initState();
    animateController = AnimationController(
      vsync: this,
      value: widget.isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1333),
    );
    animateController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(RedPacketAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (animateController.isAnimating && !widget.isOpen) {
        animateController.reverse();
      } else {
        animateController.animateTo(
          1.0,
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    animateController.dispose();
    super.dispose();
  }

  Offset get paperOffset {
    double animDuration = animateController.duration!.inMilliseconds / 1000;
    if (topFoldAnimEnd && !paperTransformTopEnd) {
      // 第一阶段
      return Offset(
        0,
        ui.lerpDouble(
          0,
          -350,
          (((animateController.value - 0.5) / 0.3) * animDuration) /
              animDuration,
        )!,
      );
    } else if (paperTransformTopEnd) {
      // 第二阶段，向下到0
      return Offset(
        0,
        ui.lerpDouble(
          -350,
          45,
          (((animateController.value - 0.8) / 0.2) * animDuration) /
              animDuration,
        )!,
      );
    } else {
      return Offset(0, animateController.value * 60);
    }
  }

  /// End when the topFold is flipped a half radius
  bool get topFoldAnimEnd => animateController.value >= 0.5;

  /// End when the paper animate to the top
  bool get paperTransformTopEnd => animateController.value >= 0.8;

  /// Show End State when animation is not animating
  bool get animStopShowEnd => !animateController.isAnimating && widget.isOpen;

  @override
  Widget build(BuildContext context) {
    /// 封面
    Widget body = Transform.translate(
      offset: Offset(0, animateController.value * 60),
      child: widget.cover,
    );

    /// 卡片
    Widget paper = Transform.translate(
      offset: paperOffset,
      child: widget.contentWidget,
    );

    /// 顶部翻页
    Widget top = widget.topFold;

    if (topFoldAnimEnd && widget.shaderCallback != null) {
      top = ShaderMask(
        shaderCallback: widget.shaderCallback!,
        child: top,
      );
    }

    top = Transform.translate(
      offset: Offset(0, animateController.value * 60),
      child: Transform(
        transform: Matrix4.rotationX(animateController.value * (math.pi)),
        child: top,
      ),
    );

    List<Widget> list = [];
    if (!topFoldAnimEnd) {
      list = [paper, body, top];
    } else if (!paperTransformTopEnd) {
      list = [top, paper, body];
    } else {
      list = [top, body, paper];
    }

    return Center(
      child: Stack(
        alignment: Alignment.topCenter,
        children: list,
      ),
    );
  }
}

class RedPacketAnimImpl extends StatelessWidget {
  final RedPacketTheme theme;
  final Function()? onOpen;
  final bool isOpen;

  final bool isMessage;
  final int rpStatus;
  final Message message;
  final MessageRed messageRed;
  final ReceiveInfo redPacketReceiveInfo;
  final Size cardSize;

  final Function()? onDetailTapCallback;

  const RedPacketAnimImpl({
    super.key,
    required this.theme,
    required this.isMessage,
    required this.rpStatus,
    required this.message,
    required this.messageRed,
    required this.redPacketReceiveInfo,
    required this.cardSize,
    required this.isOpen,
    this.onDetailTapCallback,
    this.onOpen,
  });

  bool get enableOpenAnimation => onOpen != null;

  @override
  Widget build(BuildContext context) {
    Widget body = Stack(
      children: <Widget>[
        Positioned(
          top: isOpen && isMessage ? 60.0 : 0.0,
          left: 0.0,
          right: 0.0,
          bottom: 0.0,
          child: Transform.translate(
            offset: Offset(0, isOpen && isMessage ? -60 : 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.bodyBackground,
                ),
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/red_packet/${theme.redPacketCover}.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: RedPacketCover(
                isMessage: isMessage,
                messageRed: messageRed,
                sendId: message.send_id,
                isOpen: isOpen,
                onDetailTapCallback: onDetailTapCallback,
              ),
            ),
          ),
        ),
      ],
    );

    Widget topFold = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              bottom: isOpen ? 50.0 : 0.0,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: RedPacketTopFold(
                    gradient: [
                      theme.bottomFoldBackground,
                      theme.bottomFoldBackground,
                    ],
                  ),
                ),
              ),
            ),
            if (!isOpen)
              GestureDetector(
                onTap: enableOpenAnimation ? onOpen : null,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: constraints.maxHeight * 0.08,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'assets/images/red_packet/${theme.redPacketOpen}.png',
                      alignment: Alignment.topCenter,
                      width: constraints.maxWidth / 3.5,
                      height: constraints.maxWidth / 3.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

    return RedPacketAnimation(
      cover: body,
      contentWidget: RedPacketPaper(
        isMessage: isMessage,
        rpStatus: rpStatus,
        messageRed: messageRed,
        redPacketReceiveInfo: redPacketReceiveInfo,
        cardSize: cardSize,
        theme: theme,
      ),
      topFold: topFold,
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.topFoldBackground,
            theme.topFoldBackground,
          ],
        ).createShader(bounds);
      },
      isOpen: isOpen,
    );
  }
}

class RedPacketTopFold extends CustomPainter {
  final List<Color> gradient;

  const RedPacketTopFold({
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillColor = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      gradient, // List of colors for the gradient
    );

    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = fillColor;

    canvas.drawRect(
      Rect.fromLTWH(
        0.0,
        0.0,
        size.width,
        size.height * 0.15,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        0.0,
        size.height * 0.15 / 2,
        size.width,
        size.height * 0.15,
      ),
      paint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.2),
      size.width / 6,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RedPacketCardClip extends CustomPainter {
  final bool isMessage;
  RedPacketCardClip({required this.isMessage}) : super();

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFFFFE176)
      ..style = PaintingStyle.fill;

    // Left circle
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, isMessage ? 20 : 50, isMessage ? 20 : 50),
    );
    canvas.drawCircle(const Offset(0, 0), isMessage ? 20 : 50, paint);
    canvas.restore();

    // Right circle
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        size.width - (isMessage ? 20 : 50),
        0,
        size.width,
        isMessage ? 20 : 50,
      ),
    );
    canvas.drawCircle(Offset(size.width, 0), isMessage ? 20 : 50, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RedPacketCover extends StatelessWidget {
  final bool isMessage;
  final MessageRed messageRed;
  final int sendId;
  final bool isOpen;
  final Function()? onDetailTapCallback;
  const RedPacketCover({
    super.key,
    this.isMessage = false,
    required this.messageRed,
    required this.sendId,
    required this.isOpen,
    this.onDetailTapCallback,
  });

  @override
  Widget build(BuildContext context) {
    if (isMessage) return const SizedBox();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          padding: const EdgeInsets.all(10.0),
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              Positioned(
                bottom: constraints.maxHeight * 0.2,
                left: 0.0,
                right: 0.0,
                child: Text(
                  messageRed.remark,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: MFontWeight.bold4.value,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                bottom: constraints.maxHeight * 0.07,
                left: 0.0,
                right: 0.0,
                child: RichText(
                  text: TextSpan(
                    text: '${localized(chatFrom)}: ',
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: MFontWeight.bold4.value,
                      decoration: TextDecoration.none,
                    ),
                    children: [
                      WidgetSpan(
                        child: NicknameText(
                          uid: sendId,
                          isTappable: false,
                          overflow: TextOverflow.ellipsis,
                          color: Colors.white,
                          fontSize: MFontSize.size12.value,
                          fontWeight: MFontWeight.bold4.value,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: GestureDetector(
                  onTap: onDetailTapCallback,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      isOpen ? '' : '${localized(clickToViewDetails)} >>>',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: MFontWeight.bold4.value,
                        decoration: TextDecoration.none,
                        letterSpacing: -0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RedPacketPaper extends StatelessWidget {
  final bool isMessage;
  final int rpStatus;
  final MessageRed messageRed;
  final ReceiveInfo redPacketReceiveInfo;
  final Size cardSize;
  final RedPacketTheme theme;

  const RedPacketPaper({
    super.key,
    this.isMessage = false,
    required this.rpStatus,
    required this.messageRed,
    required this.redPacketReceiveInfo,
    required this.cardSize,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardSize.width,
      height: cardSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.paperBackground,
            theme.paperBackground,
          ],
        ),
      ),
      child: CustomPaint(
        foregroundPainter: RedPacketCardClip(
          isMessage: isMessage,
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: appFontfamily,
          ),
          child: Builder(
            builder: (context) {
              if (rpStatus == rpReceived) {
                return isMessage
                    ? Container(
                        margin: const EdgeInsets.all(5.0),
                        padding: const EdgeInsets.all(5.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              '${localized(claimed)}!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold6.value,
                              ),
                            ),
                            Image.asset(
                              'assets/images/red_packet/red_packet_received_card.png',
                              width: 37.0,
                              height: 37.0,
                            ),
                            Text(
                              localized(
                                  congratulationsYouHaveClaimedThisRedPacket),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 12.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/red_packet/red_packet_received_card.png',
                              width: 60.0,
                              height: 60.0,
                            ),
                            Text(
                              '${localized(congratulations)}!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                            ),
                            Text(
                              '${localized(youHaveReceivedAn)} ${messageRed.rpType.name.redPacketName}!',
                              style: TextStyle(
                                color: Colors.black,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                                fontSize: 14.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            RichText(
                              text: TextSpan(
                                text: redPacketReceiveInfo.amount,
                                style: TextStyle(
                                  color: themeColor,
                                  decoration: TextDecoration.none,
                                  fontSize: 28,
                                  fontWeight: MFontWeight.bold4.value,
                                ),
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: ' ${messageRed.currency}',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: themeColor,
                                      decoration: TextDecoration.none,
                                      fontWeight: MFontWeight.bold4.value,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
              } else if (rpStatus == rpExpired) {
                return isMessage
                    ? Container(
                        margin: const EdgeInsets.all(5.0),
                        padding: const EdgeInsets.all(5.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              'Oops!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold6.value,
                              ),
                            ),
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 37.0,
                              height: 37.0,
                            ),
                            Text(
                              localized(thisRedPacketHasExpired),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 12.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 60.0,
                              height: 60.0,
                            ),
                            Text(
                              localized(redPacketHasEnded),
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 20.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              localized(
                                  youHaveFailedToClaimedTheRedPacketWithinTheTimeFrame),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
              } else if (rpStatus == rpFullyClaimed) {
                return isMessage
                    ? Container(
                        margin: const EdgeInsets.all(5.0),
                        padding: const EdgeInsets.all(5.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              '${localized(sorry)}!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold6.value,
                              ),
                            ),
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 37.0,
                              height: 37.0,
                            ),
                            Text(
                              localized(thisRedPacketHasBeenFullyClaimed),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 12.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 60.0,
                              height: 60.0,
                            ),
                            Text(
                              localized(sorryYouAreALittleLate),
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 20.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              localized(allTheRedPacketsHaveBeenFullyClaimed),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
              } else if (rpStatus == rpNotInExclusive) {
                return isMessage
                    ? Container(
                        margin: const EdgeInsets.all(5.0),
                        padding: const EdgeInsets.all(5.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              '${localized(sorry)}!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold6.value,
                                fontSize: 14.0,
                              ),
                            ),
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 37.0,
                              height: 37.0,
                            ),
                            Text(
                              localized(youWereNotOneOfTheSelectedRecipients),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 12.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 60.0,
                              height: 60.0,
                            ),
                            Text(
                              localized(oppsYouAreNotInvolved),
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 20.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              localized(youWereNotOneOfTheSelectedRecipients),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
              } else if (rpStatus == rpUnknownError) {
                return isMessage
                    ? Container(
                        margin: const EdgeInsets.all(5.0),
                        padding: const EdgeInsets.all(5.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              '${localized(sorry)}!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold6.value,
                              ),
                            ),
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 37.0,
                              height: 37.0,
                            ),
                            Text(
                              localized(anUnknownErrorHasOccurred),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 12.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/red_packet/red_packet_claim_failed.png',
                              width: 60.0,
                              height: 60.0,
                            ),
                            Text(
                              'Oops, ${localized(anUnknownErrorHasOccurred)}!',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 20.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              localized(anUnknownErrorHasOccurred),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
              } else {
                return isMessage
                    ? Container(
                        margin: const EdgeInsets.all(5.0),
                        padding: const EdgeInsets.all(5.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              '${localized(claimed)}!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold6.value,
                              ),
                            ),
                            Image.asset(
                              'assets/images/red_packet/red_packet_received_card.png',
                              width: 37.0,
                              height: 37.0,
                            ),
                            Text(
                              localized(
                                  congratulationsYouHaveClaimedThisRedPacket),
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 12.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10.0),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/red_packet/red_packet_received_card.png',
                              width: 60.0,
                              height: 60.0,
                            ),
                            Text(
                              '${localized(congratulations)}!',
                              style: TextStyle(
                                color: const Color(0xFFF79A44),
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                              ),
                            ),
                            Text(
                              '${localized(youHaveReceivedAn)} ${messageRed.rpType.name.redPacketName}}!',
                              style: TextStyle(
                                color: Colors.black,
                                decoration: TextDecoration.none,
                                fontWeight: MFontWeight.bold4.value,
                                fontSize: 14.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            RichText(
                              text: TextSpan(
                                text: redPacketReceiveInfo.amount,
                                style: TextStyle(
                                  color: themeColor,
                                  decoration: TextDecoration.none,
                                  fontSize: 28,
                                  fontWeight: MFontWeight.bold4.value,
                                ),
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: ' ${messageRed.currency}',
                                    style: TextStyle(
                                      color: themeColor,
                                      decoration: TextDecoration.none,
                                      fontWeight: MFontWeight.bold4.value,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
              }
            },
          ),
        ),
      ),
    );
  }
}

const luckyRedPacketConfig = <String, dynamic>{
  'redPacketCover': 'red_packet_lucky',
  'redPacketOpen': 'red_packet_lucky_open',
  'topFoldBackground': Color(0xFFCA7039),
  'bottomFoldBackground': Color(0xFFFAAB34),
  'bodyBackground': <Color>[
    Color(0xFFF6884A),
    Color(0xFFF6884A),
  ],
  'paperBackground': Color(0xFFFFE176),
};
const normalRedPacketConfig = <String, dynamic>{
  'redPacketCover': 'red_packet_standard',
  'redPacketOpen': 'red_packet_standard_open',
  'topFoldBackground': Color(0xFF930404),
  'bottomFoldBackground': Color(0xFFFA3434),
  'bodyBackground': <Color>[
    Color(0xFFD32F2D),
    Color(0xFFD32F2D),
  ],
  'paperBackground': Color(0xFFFFE176),
};
const exclusiveRedPacketConfig = <String, dynamic>{
  'redPacketCover': 'red_packet_specified',
  'redPacketOpen': 'red_packet_specified_open',
  'topFoldBackground': Color(0xFFA07F2B),
  'bottomFoldBackground': Color(0xFFE8C671),
  'bodyBackground': <Color>[
    Color(0xFFB99027),
    Color(0xFFFFD771),
    Color(0xFFD7A72D),
    Color(0xFFD7A72D),
  ],
  'bodyStops': <double>[
    0.0,
    0.5365,
    1.0,
    1.0,
  ],
  'paperBackground': Color(0xFFFFE176),
};
