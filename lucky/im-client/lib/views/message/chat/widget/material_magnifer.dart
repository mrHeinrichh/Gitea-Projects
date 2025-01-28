import 'dart:ui';
import 'package:jxim_client/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const double _kToolbarScreenPadding = 8.0;
const double _kToolbarHeight = 44.0;

class MaterialMagnifier extends StatelessWidget {
  const MaterialMagnifier({
    Key? key,
    required this.anchorAbove,
    required this.anchorBelow,
    required this.textLineHeight,
    this.size = const Size(90, 50),
    this.scale = 1.7,
    required this.translateY,
  }) : super(key: key);
  final Offset anchorAbove;
  final Offset anchorBelow;
  final Size size;
  final double scale;
  final double textLineHeight;
  final double translateY;

  @override
  Widget build(BuildContext context) {
    final double paddingAbove =
        MediaQuery.of(context).padding.top + _kToolbarScreenPadding;
    final double availableHeight = anchorAbove.dy - paddingAbove;
    final bool fitsAbove = _kToolbarHeight <= availableHeight;
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);
    final Matrix4 updatedMatrix = Matrix4.identity()
      ..scale(1.1, 1.1)
      ..translate(0.0, translateY.w);
    Matrix4 _matrix = updatedMatrix;
    return Container(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _kToolbarScreenPadding,
          paddingAbove,
          _kToolbarScreenPadding,
          _kToolbarScreenPadding,
        ),
        child: Stack(
          children: <Widget>[
            CustomSingleChildLayout(
              delegate: TextSelectionToolbarLayoutDelegate(
                anchorAbove: anchorAbove - localAdjustment,
                anchorBelow: anchorBelow - localAdjustment,
                fitsAbove: fitsAbove,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.matrix(_matrix.storage),
                  child: Container(
                    width: size.width,
                    height: size.height,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            width: 1, color: hexColor(0x000000, alpha: 0.3)),
                      ),
                    ),
                  ),
                  // child: CustomPaint(
                  //   painter: const MagnifierPainter(color: Color(0xFFdfdfdf)),
                  //   size: size,
                  // ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
