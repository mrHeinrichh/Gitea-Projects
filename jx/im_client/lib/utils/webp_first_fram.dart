import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    Size imgSize = Size(image.width.toDouble(), image.height.toDouble());

    Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 根据适配模式，计算适合的缩放尺寸
    FittedSizes fittedSizes = applyBoxFit(BoxFit.cover, imgSize, dstRect.size);
    // 获得一个图片区域中，指定大小的，居中位置处的 Rect
    Rect inputRect =
        Alignment.center.inscribe(fittedSizes.source, Offset.zero & imgSize);
    // 获得一个绘制区域内，指定大小的，居中位置处的 Rect
    Rect outputRect =
        Alignment.center.inscribe(fittedSizes.destination, dstRect);
    canvas.drawImageRect(image, inputRect, outputRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class WebpWidget extends StatefulWidget {
  const WebpWidget({
    required this.imgBytes,
    this.width,
    this.height,
    this.callBack,
    super.key,
  });

  final Uint8List imgBytes;
  final double? width;
  final double? height;
  final Function(bool b)? callBack;

  @override
  WebpWidgetState createState() => WebpWidgetState();
}

class WebpWidgetState extends State<WebpWidget> {
  ui.Image? _image;
  ui.Codec? codec;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    final imgBytes = widget.imgBytes;
    codec = await ui.instantiateImageCodec(imgBytes);
    ui.FrameInfo frame;
    try {
      frame = await codec!.getNextFrame();
    } finally {
      codec?.dispose();
      codec = null;
    }
    if (mounted) {
      setState(() {
        _image = frame.image;
      });
    }
    widget.callBack?.call(_image == null);
  }

  @override
  void dispose() {
    if (codec != null) {
      codec!.dispose();
      codec = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;

    return _image == null
        ? SizedBox(
            width: width,
            height: height,
          )
        : CustomPaint(
            size: Size(width ?? 200, height ?? 200),
            painter: ImagePainter(_image!),
          );
  }
}
