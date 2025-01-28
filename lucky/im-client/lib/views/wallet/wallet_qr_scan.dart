import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../contact/qr_code_scanner.dart';
import 'controller/qr_scanner_controller.dart';

class WalletQrScanner extends GetView<QRScannerController> {
  const WalletQrScanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key("QRCodeScanner"),
      onVisibilityChanged: (VisibilityInfo info) {
        final isVisible = info.visibleFraction != 0;
        if (isVisible) {
          controller.isScannable.value = true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: <Widget>[
            SizedBox(height: 50.h),
            Expanded(
              flex: 8,
              child: Stack(
                children: <Widget>[
                  Container(
                    height: 700.h,
                    child: MobileScanner(
                      controller: controller.mobileScannerController,
                      onDetect: (BarcodeCapture barcodes) {
                        final data = barcodes.barcodes.first.displayValue;
                        controller.scanQR(data);
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.h, 20.h, 20.h, 0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await controller.mobileScannerController.stop();
                              Get.back();
                            },
                            child: Container(
                              height: 40.h,
                              width: 40.h,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100.h),
                                  color: Colors.black),
                              child: Icon(Icons.close,
                                  color: Colors.white, size: 18.sp),
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox(), flex: 7),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              controller.toggleTorch();
                            },
                            child: Container(
                              height: 40.h,
                              width: 40.h,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.black),
                              child: Obx(
                                () => Icon(
                                  controller.torchOn.value
                                      ? Icons.flash_off
                                      : Icons.flash_on,
                                  color: Colors.white,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: CustomPaint(
                        foregroundPainter: BorderPainter(),
                        child: Container(
                          width: 350.h,
                          height: 350.h,
                        )),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 650.h, left: 20.h),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              controller.getImage(context);
                            },
                            child: Container(
                              height: 40.h,
                              width: 40.h,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.black),
                              child: Icon(Icons.image,
                                  color: Colors.white, size: 18.sp),
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox(), flex: 8),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
