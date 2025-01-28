import 'package:jxim_client/utils/color.dart';
import 'package:flutter/material.dart';

class ClickColor extends StatefulWidget {
  final Widget child;
  const ClickColor({Key? key, required this.child}) : super(key: key);

  @override
  _ClickColorState createState() => _ClickColorState();
}

class _ClickColorState extends State<ClickColor> {
  Color color = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (v) {
        color = colorF7F7F7;
        if (mounted) setState(() {});
      },
      onPointerUp: (v) {
        color = Colors.transparent;
        if (mounted) setState(() {});
      },
      child: Container(
        color: color,
        child: widget.child,
      ),
    );
  }
}
