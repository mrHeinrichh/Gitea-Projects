import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/qr_code_scanner_controller.dart';
import 'package:lottie_tgs/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class QRCodeScanner extends GetView<QRCodeScannerController> {
  const QRCodeScanner({super.key});

  @override
  Widget build(BuildContext context) {
    // 从 Get.arguments 中提取 didGetText 函数
    final Function(String)? didGetText =
        Get.arguments != null ? Get.arguments['didGetText'] : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: VisibilityDetector(
          key: const Key("QRCodeScanner"),
          onVisibilityChanged: (VisibilityInfo info) {
            final isVisible = info.visibleFraction != 0;
            if (isVisible) {
              controller.isScannable.value = true;
            }
          },
          child: Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.black,
            body: Stack(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: MobileScanner(
                    controller: controller.mobileScannerController,
                    errorBuilder: (
                      BuildContext context,
                      MobileScannerException error,
                      Widget? child,
                    ) {
                      controller.restartScanner();
                      return const Center(
                        child: Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                    onDetect: (BarcodeCapture barcodes) {
                      final data = barcodes.barcodes.first.displayValue;
                      // 检查函数是否不为空，然后调用它
                      if (didGetText != null && data != null) {
                        didGetText(data);
                        controller.mobileScannerController?.stop();
                        Get.back();
                        return;
                      }
                      controller.getDataFromQR(data, context);
                    },
                  ),
                ),
                content(didGetText, context),
                Obx(
                  () => Visibility(
                    visible: controller.verificationSuccess.value,
                    child: Center(
                      child: Lottie.asset(
                        "assets/lottie/animate_success.json",
                        height: MediaQuery.of(context).size.width - 16 * 2,
                        width: MediaQuery.of(context).size.width - 16 * 2,
                        repeat: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget content(Function(String)? didGetText, BuildContext context) {
    return Positioned.fill(
      child: GetBuilder(
        tag: "content",
        init: controller,
        builder: (_) {
          return CustomPaint(
            painter: controller.scanQrCodeType ==
                ScanQrCodeType.verifyPrivateKey
                ? (controller.verificationSuccess.value ? null : CircularBorderPainter())
                : BorderPainter(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).viewPadding.top + 10,
                    bottom: 8,
                  ),
                  child: const CustomLeadingIcon(
                    backButtonColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Center(
                        child: Text(
                          localized(scanQRCodeTitle),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: MFontWeight.bold6.value,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                        ),
                        child: Text(
                          textAlign: TextAlign.center,
                          didGetText == null
                              ? getBrief()
                              : localized(
                              walletQrScanToGetPayAddress),
                          style: jxTextStyle.textStyle16(
                            color: colorWhite.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                    child: Column(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () => controller.toggleTorch(),
                            child: Container(
                              height: 60,
                              width: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              child: Obx(
                                    () => SvgPicture.asset(
                                  'assets/svgs/flashlight.svg',
                                  width: 32,
                                  height: 32,
                                  colorFilter: ColorFilter.mode(
                                    controller.torchOn.value
                                        ? Colors.white
                                        : colorTextSecondary,
                                    BlendMode.srcIn,
                                  ),
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(
                              () => Visibility(
                            visible:
                            controller.showBottomButton.value,
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                qrButton(
                                  svgName: 'qrCode',
                                  text: localized(scanContext),
                                  onTap: () =>
                                      controller.qrCodePopUp(context),
                                ),
                                if (isWalletEnable())
                                  qrButton(
                                    svgName: 'qrCode_my_wallet',
                                    text: localized(scanContextMoney),
                                    onTap: () => controller
                                        .qrMoneyCodePopUp(context),
                                  ),
                                qrButton(
                                  svgName: 'album',
                                  text: localized(scanMyAlbum),
                                  onTap: () =>
                                      controller.getImage(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget qrButton({
    Function()? onTap,
    required svgName,
    String? text,
    double? svgSize,
  }) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: onTap,
          child: OpacityEffect(
            child: Container(
              height: 60,
              width: 60,
              decoration: const BoxDecoration(
                color: colorTextSecondary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(19),
              child: SvgPicture.asset(
                'assets/svgs/$svgName.svg',
                width: svgSize ?? 22,
                height: svgSize ?? 22,
                colorFilter: const ColorFilter.mode(
                  colorWhite,
                  BlendMode.srcIn,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 4),
          Text(
            text,
            style: jxTextStyle.textStyle12(
              color: colorWhite,
            ),
          ),
        ],
      ],
    );
  }

  String getBrief() {
    if (controller.scanQrCodeType == ScanQrCodeType.verifyPrivateKey) return "";
    String brief =
        "${localized(scanFast)}${localized(scanAddFriend)}/${localized(scanLoginDesk)}";
    if (isWalletEnable()) {
      brief = "$brief/${localized(scanTransferFund)}";
    }
    return brief;
  }
}

class CircularBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white // Set the color to white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Set stroke width to 4

    // Calculate the radius considering the padding
    final double radius =
        (size.width - 64) / 2; // 32 pixels padding on each side

    // Draw the circular border
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.h
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Paint bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.54)
      ..strokeWidth = 4.h
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    double squareBox = 17;

    canvas.save();

    /// QR Coordinate
    double qrBoxY = (size.height / 2) - 135;
    double qrBoxX = (size.width / 2) - 140;

    /// TopLeft corner
    Path topLeftPath = Path();
    topLeftPath.moveTo(squareBox, 0);

    topLeftPath.lineTo(1, 0);
    topLeftPath.lineTo(0.5, 0.5);
    topLeftPath.lineTo(0, 1);
    topLeftPath.lineTo(0, squareBox);

    /// TopRight corner
    Path topRightPath = Path();
    topRightPath.moveTo(280 - squareBox, 0);
    topRightPath.lineTo(279, 0);
    topRightPath.lineTo(279.5, 0.5);
    topRightPath.lineTo(280, 1);
    topRightPath.lineTo(280, squareBox);
    // topRightPath.quadraticBezierTo(280, 0, 280, squareBox);

    /// BottomLeft corner
    Path bottomLeftPath = Path();
    bottomLeftPath.moveTo(0, 280 - squareBox);
    bottomLeftPath.lineTo(0, 279);
    bottomLeftPath.lineTo(0.5, 279.5);
    bottomLeftPath.lineTo(1, 280);
    bottomLeftPath.lineTo(squareBox, 280);
    // bottomLeftPath.quadraticBezierTo(0, 280, squareBox, 280);

    /// BottomRight corner
    Path bottomRightPath = Path();
    bottomRightPath.moveTo(280, 280 - squareBox);
    bottomRightPath.lineTo(280, 279);
    bottomRightPath.lineTo(279.5, 279.5);
    bottomRightPath.lineTo(279, 280);
    bottomRightPath.lineTo(280 - squareBox, 280);
    // bottomRightPath.quadraticBezierTo(280, 280, 280 - squareBox, 280);

    canvas.restore();

    /// draw background

    /// top area
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, size.width, qrBoxY),
      bgPaint,
    ); // top area
    canvas.drawRect(
      Rect.fromLTWH(0.0, qrBoxY + 280, size.width, qrBoxY),
      bgPaint,
    ); // bottom area
    canvas.drawRect(
      Rect.fromLTWH(0.0, qrBoxY, (size.width - 280) / 2, 280),
      bgPaint,
    ); // left area
    canvas.drawRect(
      Rect.fromLTWH(qrBoxX + 280, qrBoxY, (size.width - 280) / 2, 280),
      bgPaint,
    ); // right area

    /// Move canvas to QR Coordinate
    canvas.translate(qrBoxX, qrBoxY);
    canvas.drawPath(topLeftPath, paint);
    canvas.drawPath(topRightPath, paint);
    canvas.drawPath(bottomLeftPath, paint);
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(BorderPainter oldDelegate) => false;
}
