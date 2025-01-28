import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class RedPacket extends StatefulWidget {
  const RedPacket({
    super.key,
    this.onFinish,
    this.onOpen,
    required this.redPacketMessage,
    this.detailTap,
    this.onPressClose,
  });

  final Function? onFinish;
  final Function? onOpen;
  final GestureTapCallback? detailTap;
  final GestureTapCallback? onPressClose;
  final Widget redPacketMessage;

  @override
  RedPacketState createState() => RedPacketState();
}

class RedPacketState extends State<RedPacket> with TickerProviderStateMixin {
  late RedPacketController controller =
      RedPacketController(tickerProvider: this);
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool get isDesktop => objectMgr.loginMgr.isDesktop;

  @override
  void initState() {
    super.initState();
    controller.onOpen = widget.onOpen;
    controller.onFinish = widget.onFinish;
  }

  @override
  void dispose() {
    controller.dispose();
    _audioPlayer.onPlayerComplete.listen((event) async {
      _audioPlayer.dispose();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller.scaleController,
          curve: Curves.fastOutSlowIn,
        ),
      ),
      child: buildRedPacket(),
    );
  }

  Widget buildRedPacket() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTapUp: (details) {
          controller.clickGold(details, () async {
            bool status = objectMgr.localStorageMgr
                    .read(LocalStorageMgr.MESSAGE_SOUND_NOTIFICATION) ??
                true;
            if (status) {
              bool isAudioPlaying = false;
              if (objectMgr.loginMgr.isMobile) {
                isAudioPlaying = await objectMgr.sysOprateMgr.isAudioPlaying();
              }
              final ringerStatus = await SoundMode.ringerModeStatus;
              final isMute = [RingerModeStatus.silent, RingerModeStatus.vibrate]
                  .contains(ringerStatus);
              final shouldPlay = isAudioPlaying == false && isMute == false;
              if (shouldPlay == true) {
                _audioPlayer.play(AssetSource('sound/dakaihongbao.mp3'));
              }
            }
          });
        },
        child: CustomPaint(
          size: Size(1.sw, 1.sh),
          painter: RedPacketPainter(controller: controller),
          child: buildChild(),
        ),
      ),
    );
  }

  Widget bottomChild() {
    return GestureDetector(
      onTap: widget.detailTap,
      child: AnimatedBuilder(
        animation: controller.translateController,
        builder: (context, child) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '  ${localized(redPacketViewClaimDetails)}',
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFFEBCD9A),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFEBCD9A),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChild() {
    return AnimatedBuilder(
      animation: controller.translateController,
      builder: (context, child) => Stack(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: 0.25.sh * (1 - controller.translateCtrl.value),
            ),
            child: widget.redPacketMessage,
          ),
          if (controller.showOpenBtn) ...[
            Positioned(
              left: 0,
              right: 0,
              top: isDesktop ? 0.7.sh : (0.9.sh - 1.2.sw) / 2 + 1.2.sw - 28,
              child: bottomChild(),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: isDesktop ? 0.85.sh : (0.9.sh - 1.2.sw) / 2 + 1.2.sw + 45,
              child: GestureDetector(
                onTap: widget.onPressClose,
                behavior: HitTestBehavior.opaque,
                child: SvgPicture.asset(
                  'assets/svgs/close_icon_circle.svg',
                  height: 32,
                  width: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class RedPacketMessageWidget extends StatelessWidget {
  const RedPacketMessageWidget({
    super.key,
    required this.messageRed,
    required this.message,
    required this.chat,
  });

  final MessageRed messageRed;
  final Message message;
  final Chat chat;

  String getRedPacketTxtByType(RedPacketType rpType) {
    return switch (rpType) {
      RedPacketType.normalRedPacket => localized(normalRedPacket),
      RedPacketType.luckyRedPacket => localized(luckyRedPacket),
      RedPacketType.exclusiveRedPacket => localized(exclusiveRedPacket),
      RedPacketType.none => 'Unknown Type RedPacket',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ObjectMgr.screenMQ!.size.width * .18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomAvatar.normal(message.send_id, size: 38),
          SizedBox(height: 5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: NicknameText(
                  uid: message.send_id,
                  fontSize: MFontSize.size17.value,
                  color: const Color(0xFFE1FFC7),
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w500,
                  groupId: chat.isGroup ? chat.id : null,
                ),
              ),
            ],
          ),
          Text(
            localized(redEnvelopesSent),
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFFE1FFC7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            messageRed.remark,
            maxLines: 5,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class RedPacketController {
  final TickerProviderStateMixin tickerProvider;
  Listenable? repaint;

  Path? goldPath;

  late AnimationController angleController;
  late AnimationController translateController;
  late AnimationController scaleController;
  late Animation<double> translateCtrl;
  late Animation<Color?> colorCtrl;
  late Animation<double> angleCtrl;
  bool isAdd = false;
  bool showOpenText = true;
  bool showOpenBtn = true;

  Timer? timer;

  Function? onFinish;
  Function? onOpen;

  RedPacketController({required this.tickerProvider}) {
    initAnimation();
  }

  void initAnimation() {
    angleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: tickerProvider,
    );
    translateController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: tickerProvider,
    );
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: tickerProvider,
    )..forward();
    angleCtrl = angleController.drive(Tween(begin: 1.0, end: 0.0));

    translateCtrl = translateController.drive(Tween(begin: 0.0, end: 1.0));
    colorCtrl = translateController.drive(
      ColorTween(
        begin: const Color(0xFFFF5F5F),
        end: const Color(0x00FF5252),
      ),
    );

    translateController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onFinish?.call();
      }
    });
    repaint = Listenable.merge([angleController, translateController]);
  }

  void stop() async {
    if (angleController.isAnimating) {
      if (angleController.status == AnimationStatus.forward) {
        await angleController.forward();
        angleController.reverse();
      } else if (angleController.status == AnimationStatus.reverse) {
        angleController.reverse();
      }
      showOpenBtn = false;
      translateController.forward();
      onOpen?.call();
    }
  }

  void clickGold(TapUpDetails details, Function playSound) {
    if (checkClickGold(objectMgr.loginMgr.isDesktop ? details.localPosition
        : details.globalPosition)) {
      if (angleController.isAnimating) {
        stop();
      } else {
        angleController.repeat(reverse: true);
        showOpenText = false;
        timer = Timer(const Duration(milliseconds: 1300), () {
          stop();
        });
      }
      playSound();
    }
  }

  bool checkClickGold(Offset point) {
    return goldPath?.contains(point) == true;
  }

  void handleClick(Offset point) async {
    if (checkClickGold(point)) {
      return;
    }
    await scaleController.reverse();
    onFinish?.call();
  }

  void dispose() {
    angleController.dispose();
    translateController.dispose();
    timer?.cancel();
  }
}

class RedPacketPainter extends CustomPainter {
  RedPacketController controller;

  bool get isDesktop => objectMgr.loginMgr.isDesktop;
  late final Paint _paint = Paint()..isAntiAlias = true;
  final Path path = Path();

  late double height = isDesktop ? 0.65.sh : 1.2.sw;
  late double topBezierEnd = (0.9.sh - height) / 2 + height / 8 * 7;
  late double topBezierStart = topBezierEnd - (isDesktop ? 0.2.sh : 0.2.sw);

  late double bottomBezierStart = topBezierEnd - (isDesktop ? 0.4.sh : 0.4.sw);

  Offset goldCenter = Offset.zero;
  late double centerWidth = 0.5.sw - (isDesktop ? 150 : 0);

  late double left = 0.1.sw;
  late double right = 0.9.sw - (isDesktop ? 301 : 0);
  late double top = (0.9.sh - height) / 2;
  late double bottom = (0.9.sh - height) / 2 + height + 25;

  RedPacketPainter({required this.controller})
      : super(repaint: controller.repaint);

  @override
  void paint(Canvas canvas, Size size) {
    drawBg(canvas);
    if (controller.showOpenBtn) {
      drawGoldOpen(canvas);
    }
  }

  void drawBg(ui.Canvas canvas) {
    _paint.color = controller.colorCtrl.value ?? const Color(0xFFFF5F5F);
    _paint.style = PaintingStyle.fill;

    drawBottom(canvas);

    drawTop(canvas);
  }

  void drawTop(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(0, topBezierEnd * (-controller.translateCtrl.value));

    path.reset();
    path.addRRect(
      RRect.fromLTRBAndCorners(
        left,
        top,
        right,
        topBezierStart,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
    );
    var bezierPath = getTopBezierPath();
    path.addPath(bezierPath, Offset.zero);
    path.close();

    canvas.drawShadow(path, const Color(0xFFEBCD9A), 2, true);
    canvas.drawPath(path, _paint);
    canvas.restore();
  }

  Path getTopBezierPath() {
    Path bezierPath = Path();
    bezierPath.moveTo(left, topBezierStart);
    bezierPath.quadraticBezierTo(
      centerWidth,
      topBezierEnd,
      right,
      topBezierStart,
    );

    var pms = bezierPath.computeMetrics();
    var pm = pms.first;
    goldCenter = pm.getTangentForOffset(pm.length / 2)?.position ?? Offset.zero;
    return bezierPath;
  }

  void drawBottom(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(0, topBezierStart * (controller.translateCtrl.value));

    path.reset();
    path.moveTo(left, bottomBezierStart);
    path.quadraticBezierTo(centerWidth, topBezierEnd, right, bottomBezierStart);
    path.lineTo(right, topBezierEnd);
    path.lineTo(left, topBezierEnd);
    path.addRRect(
      RRect.fromLTRBAndCorners(
        left,
        topBezierEnd,
        right,
        bottom,
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ),
    );
    path.close();
    canvas.drawShadow(path, const Color(0xFFFF5F5F), 2, true);
    canvas.drawPath(path, _paint);

    canvas.restore();
  }

  void drawGoldOpen(ui.Canvas canvas) {
    drawGold(canvas);
    drawOpenText(canvas);
  }

  void drawOpenText(ui.Canvas canvas) {
    bool cnLanguage = AppLocalizations.of(navigatorKey.currentContext!)!
        .locale
        .languageCode
        .contains('zh');

    if (controller.showOpenText) {
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: cnLanguage ? "開" : "OPEN",
          style: TextStyle(
            fontSize: cnLanguage ? 34.sp : 20.sp,
            color: Colors.black.withOpacity(0.56),
            height: 1.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        textWidthBasis: TextWidthBasis.longestLine,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      )..layout();

      canvas.save();
      canvas.translate(centerWidth, goldCenter.dy);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  void drawGold(ui.Canvas canvas) {
    Path path = Path();
    double angle = controller.angleCtrl.value;

    canvas.save();
    canvas.translate(centerWidth, goldCenter.dy);

    path.reset();
    _paint.style = PaintingStyle.fill;
    path.addOval(Rect.fromLTRB(-40.w * angle, -40.w, 40.w * angle, 40.w));
    if (!controller.showOpenText) {
      path.addRect(Rect.fromLTRB(-10.w * angle, -10.w, 10.w * angle, 10.w));
      path.fillType = PathFillType.evenOdd;
    }

    var frontOffset = 0.0;
    var backOffset = 0.0;
    if (controller.angleCtrl.status == AnimationStatus.reverse) {
      frontOffset = 4.w;
      backOffset = -4.w;
    } else if (controller.angleCtrl.status == AnimationStatus.forward) {
      frontOffset = -4.w;
      backOffset = 4.w;
    }
    var path2 = path.shift(Offset(backOffset * (1 - angle), 0));
    path = path.shift(Offset(frontOffset * (1 - angle), 0));

    controller.goldPath = path.shift(Offset(centerWidth, goldCenter.dy));


    _paint.color = const Color(0xFFEBCD9A);
    canvas.drawPath(path2, _paint);

    drawGoldCenterRect(path, path2, canvas);

    _paint.color = const Color(0xFFEBCD9A);
    canvas.drawPath(path, _paint);

    canvas.restore();
  }

  void drawGoldCenterRect(ui.Path path, ui.Path path2, ui.Canvas canvas) {
    var pms1 = path.computeMetrics();
    var pms2 = path2.computeMetrics();

    var pathMetric1 = pms1.first;
    var pathMetric2 = pms2.first;
    var length = pathMetric1.length;
    Path centerPath = Path();
    for (int i = 0; i < length; i++) {
      var position1 = pathMetric1.getTangentForOffset(i.toDouble())?.position;
      var position2 = pathMetric2.getTangentForOffset(i.toDouble())?.position;
      if (position1 == null || position2 == null) {
        continue;
      }
      centerPath.moveTo(position1.dx, position1.dy);
      centerPath.lineTo(position2.dx, position2.dy);
    }

    Paint centerPaint = Paint()
      ..color = const Color(0xFFEBCD9A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(centerPath, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
