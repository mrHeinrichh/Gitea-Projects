import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:jxim_client/utils/cache_image.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    Size imgSize = Size(image.width.toDouble(), image.height.toDouble());

    Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 根据适配模式，计算适合的缩放尺寸
    FittedSizes fittedSizes = applyBoxFit(BoxFit.fitHeight, imgSize, dstRect.size);
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
  const WebpWidget(this.imgData, {super.key});

  final RemoteImageData imgData;

  @override
  _WebpWidgetState createState() => _WebpWidgetState();
}

class _WebpWidgetState extends State<WebpWidget> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    final imgBytes = widget.imgData.cacheFile!.file.readAsBytesSync();
    ui.Codec codec = await ui.instantiateImageCodec(imgBytes);
    ui.FrameInfo frame;
    try {
      frame = await codec.getNextFrame();
    } finally {
      codec.dispose();
    }

    setState(() {
      _image = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.imgData.width;
    final height = widget.imgData.height;

    return _image == null
        ? Shimmer(
            enabled: true,
            color: Colors.black26,
            colorOpacity: 0.2,
            duration: const Duration(seconds: 2),
            child: SizedBox(
              width: width,
              height: height,
            ),
          )
        : CustomPaint(
            size: Size(width ?? 200, height ?? 200),
            painter: ImagePainter(_image!),
          );
  }
}
