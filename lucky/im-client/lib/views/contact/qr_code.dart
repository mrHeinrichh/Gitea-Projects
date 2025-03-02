import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QRCode extends StatelessWidget {
  const QRCode({
    Key? key,
    required this.qrSize,
    required this.qrData,
    required this.roundEdges,
    this.image,
    this.color,
  }) : super(key: key);

  final String qrData;
  final double qrSize;
  final bool roundEdges;
  final ImageProvider<Object>? image;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   width: qrSize,
    //   height: qrSize,
    //   child: _PrettyQrAnimatedView(
    //     qrImage: QrImage(
    //       QrCode.fromData(
    //         data: qrData,
    //         errorCorrectLevel: QrErrorCorrectLevel.H,
    //       ),
    //     ),
    //     decoration: PrettyQrDecoration(
    //         shape: PrettyQrSmoothSymbol(
    //           color: Colors.black,
    //         ),
    //         image: PrettyQrDecorationImage(
    //           image: AssetImage('assets/images/wallet_background_img.png'),
    //           position: PrettyQrDecorationImagePosition.embedded,
    //         )),
    //   ),
    // );
    return PrettyQr(
      data: qrData,
      size: qrSize,
      roundEdges: roundEdges,
      // typeNumber: 5,
      errorCorrectLevel: QrErrorCorrectLevel.M,
      image: image,
      elementColor: color ?? Colors.black,
    );
  }
}

class _PrettyQrAnimatedView extends StatefulWidget {
  @protected
  final QrImage qrImage;

  @protected
  final PrettyQrDecoration decoration;

  const _PrettyQrAnimatedView({
    required this.qrImage,
    required this.decoration,
  });

  @override
  State<_PrettyQrAnimatedView> createState() => _PrettyQrAnimatedViewState();
}

class _PrettyQrAnimatedViewState extends State<_PrettyQrAnimatedView> {
  @protected
  late PrettyQrDecoration previosDecoration;

  @override
  void initState() {
    super.initState();

    previosDecoration = widget.decoration;
  }

  @override
  void didUpdateWidget(
    covariant _PrettyQrAnimatedView oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.decoration != oldWidget.decoration) {
      previosDecoration = oldWidget.decoration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TweenAnimationBuilder<PrettyQrDecoration>(
        tween: PrettyQrDecorationTween(
          begin: previosDecoration,
          end: widget.decoration,
        ),
        curve: Curves.ease,
        duration: const Duration(
          milliseconds: 240,
        ),
        builder: (context, decoration, child) {
          return PrettyQrView(
            qrImage: widget.qrImage,
            decoration: decoration,
          );
        },
      ),
    );
  }
}
