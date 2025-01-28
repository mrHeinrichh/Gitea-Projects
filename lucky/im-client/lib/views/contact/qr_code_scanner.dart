
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/qr_code_scanner_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../utils/theme/text_styles.dart';

class QRCodeScanner extends GetView<QRCodeScannerController> {
  const QRCodeScanner({Key? key}) : super(key: key);

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
                Container(
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
                      controller.getDataFromQR(data);
                    },
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: BorderPainter(),
                    child: Column(
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
                              Text(
                                localized(scanQrCode),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: MFontWeight.bold6.value,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0),
                                child: Text(
                                  textAlign: TextAlign.center,
                                  didGetText == null
                                      ? localized(scanQrDescription, params: ["${Config().enableWallet ? localized(scanQrDescriptionParam) : ""}"])
                                      : '扫描二维码获取收款地址',
                                  style: jxTextStyle.textStyle16(
                                      color: JXColors.secondaryTextWhite),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.48,
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
                                GestureDetector(
                                  onTap: () => controller.toggleTorch(),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                    child: Obx(
                                      () => SvgPicture.asset(
                                        'assets/svgs/flashlight.svg',
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(
                                          controller.torchOn.value
                                              ? Colors.white
                                              : JXColors.black48,
                                          BlendMode.srcIn,
                                        ),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    Column(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () => controller.qrCodePopUp(context),
                                          child: Container(
                                            width: 60.0,
                                            decoration: const BoxDecoration(
                                              color: JXColors.secondaryTextBlack,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: SvgPicture.asset(
                                              'assets/svgs/qrCode.svg',
                                              width: 24,
                                              height: 24,
                                              colorFilter: const ColorFilter.mode(
                                                JXColors.white,
                                                BlendMode.srcIn,
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          localized(scanContext),
                                          style: jxTextStyle.textStyle12(
                                            color: JXColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if(Config().enableWallet)
                                      Column(
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: () => controller.qrMoneyCodePopUp(context),
                                            child: Container(
                                              width: 60.0,
                                              decoration: const BoxDecoration(
                                                color: JXColors.secondaryTextBlack,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              child: SvgPicture.asset(
                                                'assets/svgs/qrCode_my_wallet.svg',
                                                width: 24,
                                                height: 24,
                                                colorFilter: const ColorFilter.mode(
                                                  JXColors.white,
                                                  BlendMode.srcIn,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          localized(scanContextMoney),
                                          style: jxTextStyle.textStyle12(
                                            color: JXColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () =>
                                              controller.getImage(context),
                                          child: Container(
                                            width: 60.0,
                                            decoration: const BoxDecoration(
                                              color: JXColors.secondaryTextBlack,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: SvgPicture.asset(
                                              'assets/svgs/album.svg',
                                              width: 24,
                                              height: 24,
                                              colorFilter: const ColorFilter.mode(
                                                JXColors.white,
                                                BlendMode.srcIn,
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          localized(scanMyAlbum),
                                          style: jxTextStyle.textStyle12(
                                            color: JXColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
          ),
        ),
      ),
    );
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
        Rect.fromLTWH(0.0, 0.0, size.width, qrBoxY), bgPaint); // top area
    canvas.drawRect(Rect.fromLTWH(0.0, qrBoxY + 280, size.width, qrBoxY),
        bgPaint); // bottom area
    canvas.drawRect(Rect.fromLTWH(0.0, qrBoxY, (size.width - 280) / 2, 280),
        bgPaint); // left area
    canvas.drawRect(
        Rect.fromLTWH(qrBoxX + 280, qrBoxY, (size.width - 280) / 2, 280),
        bgPaint); // right area

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
