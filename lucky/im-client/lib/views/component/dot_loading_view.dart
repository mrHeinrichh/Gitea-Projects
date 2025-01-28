import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DotLoadingView extends StatefulWidget {
  final Color dotColor;
  final double size;
  const DotLoadingView({Key? key, this.dotColor = Colors.white, this.size = 25}) : super(key: key);
  @override
  State<StatefulWidget> createState() => DotLoadingViewState();

}

class DotLoadingViewState extends State<DotLoadingView> {
  @override
  Widget build(BuildContext context) {
    return SpinKitThreeBounce(
      itemBuilder: (context, index) {
        final num = index % 3;
        final colors = [
          widget.dotColor,
          widget.dotColor.withOpacity(0.7),
          widget.dotColor.withOpacity(0.4),
        ];
        return DecoratedBox(
          decoration: BoxDecoration(color: colors[num], shape: BoxShape.circle),
        );
      },
      size: widget.size,
      duration: const Duration(milliseconds: 1000),
    );
  }

}
