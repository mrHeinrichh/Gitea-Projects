import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class MovableBadgePainter extends CustomPainter {
  final TouchInfo repaint;

  List<Offset> pos = [];

  final Paint _pathPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final Paint _circlePaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill
    ..strokeCap = StrokeCap.round;

  Paint fillPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  Point<double> widgetCenterPoint = const Point(0.0, 0.0);

  double shortestRadius = 0;

  //透過控制scaleRate來控制移動的寬度
  double scaleRate = 12.0;

  double circleScaleRate = 13.0;

  //透過控制disappearThreshold來控制消失門檻
  double disappearThreshold = 1.0;

  double circleThreshold = 1.0;

  double lerpFactor = 0.15;

  static ui.Image? widgetImage;

  final GlobalKey widgetKey;

  MovableBadgePainter(this.widgetKey,
      {required this.repaint,
      required this.widgetCenterPoint,
      required this.shortestRadius,
      this.disappearThreshold = 1.0})
      : super(repaint: repaint) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadImage());
  }

  void _loadImage() async {
    final RenderObject? renderObject =
        widgetKey.currentContext?.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      widgetImage = await renderObject.toImage();
      repaint.update();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    pos = repaint.points;

    if (pos.isEmpty) return;

    Path path1 = Path();
    Path path2 = Path();

    Path fillPath = Path();

    double midCircleX = widgetCenterPoint.x;
    double midCircleY = widgetCenterPoint.y;

    Offset lastPoint = pos.last;

    double destX = lastPoint.dx;
    double destY = lastPoint.dy;

    double threshold = shortestRadius;
    double distance =
        sqrt(pow(midCircleX - destX, 2) + pow(midCircleY - destY, 2));

    circleThreshold = threshold - distance / circleScaleRate;
    threshold = threshold - distance / scaleRate;

    Point<double> centerA = Point(midCircleX, midCircleY);
    Point<double> centerB = Point(destX, destY);
    List<Point<double>> tangents =
        findTangents(centerA, threshold, centerB, shortestRadius);

    path1.moveTo(tangents[0].x, tangents[0].y);
    path2.moveTo(tangents[2].x, tangents[2].y);

    Point<double> twoMidOfCenter = findMidPoint(centerA, centerB);
    Point<double> a1b1Mid = findMidPoint(tangents[0], tangents[1]);
    Point<double> a2b2Mid = findMidPoint(tangents[2], tangents[3]);

    // Point<double> a1b1MidOfMidCenter = findMidPoint(twoMidOfCenter,a1b1Mid);
    // Point<double> a2b2MidOfMidCenter = findMidPoint(twoMidOfCenter,a2b2Mid);

    Point<double> a1b1MidOfMidCenter = Point(
      lerp(twoMidOfCenter.x, a1b1Mid.x, lerpFactor),
      lerp(twoMidOfCenter.y, a1b1Mid.y, lerpFactor),
    );
    Point<double> a2b2MidOfMidCenter = Point(
      lerp(twoMidOfCenter.x, a2b2Mid.x, lerpFactor),
      lerp(twoMidOfCenter.y, a2b2Mid.y, lerpFactor),
    );

    double controlPointX1 = a1b1MidOfMidCenter.x;
    double controlPointY1 = a1b1MidOfMidCenter.y;

    double controlPointX2 = a2b2MidOfMidCenter.x;
    double controlPointY2 = a2b2MidOfMidCenter.y;

    path1.quadraticBezierTo(
        controlPointX1, controlPointY1, tangents[1].x, tangents[1].y);
    path2.quadraticBezierTo(
        controlPointX2, controlPointY2, tangents[3].x, tangents[3].y);

    fillPath.moveTo(tangents[0].x, tangents[0].y);
    fillPath.quadraticBezierTo(
        controlPointX1, controlPointY1, tangents[1].x, tangents[1].y);
    fillPath.lineTo(tangents[3].x, tangents[3].y);
    fillPath.quadraticBezierTo(
        controlPointX2, controlPointY2, tangents[2].x, tangents[2].y);
    fillPath.close();

    if (threshold > disappearThreshold) {
      canvas.drawPath(fillPath, _circlePaint);
      canvas.drawPath(path1, _pathPaint);
      canvas.drawPath(path2, _pathPaint);

      if (widgetImage != null && distance > widgetImage!.width.toDouble() / 2) {
        canvas.drawCircle(Offset(midCircleX, midCircleY), circleThreshold,
            _circlePaint..color);
      }
    }

    if (widgetImage != null) {
      double imageWidth = widgetImage!.width.toDouble();
      double imageHeight = widgetImage!.height.toDouble();
      canvas.drawCircle(
          Offset(destX, destY), shortestRadius, _circlePaint..color);
      canvas.drawImage(widgetImage!,
          Offset(destX - imageWidth / 2, destY - imageHeight / 2), Paint());
    }
  }

  double lerp(double start, double end, double factor) {
    return start + (end - start) * factor;
  }

  @override
  bool shouldRepaint(MovableBadgePainter oldDelegate) =>
      oldDelegate.repaint != repaint;
}

Future<ui.Image> widgetToImage(GlobalKey key) async {
  final RenderObject? renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderRepaintBoundary) {
    return await renderObject.toImage();
  } else {
    throw Exception('RenderObject is not a RenderRepaintBoundary');
  }
}

Point<double> findMidPoint(Point<double> pointA, Point<double> pointB) {
  return Point((pointA.x + pointB.x) / 2, (pointA.y + pointB.y) / 2);
}

List<Point<double>> findTangents(Point<double> centerA, double radiusA,
    Point<double> centerB, double radiusB) {
  double dx = centerB.x - centerA.x;
  double dy = centerB.y - centerA.y;
  double dist = sqrt(dx * dx + dy * dy);

  double angle = atan2(dy, dx);
  double angleOffset = acos((radiusA - radiusB) / dist);

  double angle1 = angle + angleOffset;
  double angle2 = angle - angleOffset;

  Point<double> tangentA1 = Point(
      centerA.x + radiusA * cos(angle1), centerA.y + radiusA * sin(angle1));
  Point<double> tangentB1 = Point(
      centerB.x + radiusB * cos(angle1), centerB.y + radiusB * sin(angle1));

  Point<double> tangentA2 = Point(
      centerA.x + radiusA * cos(angle2), centerA.y + radiusA * sin(angle2));
  Point<double> tangentB2 = Point(
      centerB.x + radiusB * cos(angle2), centerB.y + radiusB * sin(angle2));

  return [tangentA1, tangentB1, tangentA2, tangentB2];
}

class TouchInfo extends ChangeNotifier {
  final List<Offset> _points = [];
  int _selectIndex = -1;

  int get selectIndex => _selectIndex;

  List<Offset> get points => _points;

  set selectIndex(int value) {
    if (_selectIndex == value) return;

    _selectIndex = value;
    notifyListeners();
  }

  void addPoint(Offset point) {
    points.add(point);
    notifyListeners();
  }

  void updatePoint(int index, Offset point) {
    points[index] = point;
    notifyListeners();
  }

  void reset() {
    _points.clear();
    _selectIndex = -1;
    notifyListeners();
  }

  void resetPoints() {
    points.clear();
    notifyListeners();
  }

  void update() {
    notifyListeners();
  }

  Offset? get selectPoint => _selectIndex == -1 ? null : _points[_selectIndex];
}
