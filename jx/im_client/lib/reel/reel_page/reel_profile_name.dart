import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ReelProfileName extends StatefulWidget {
  final int userId;
  final String? name;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  const ReelProfileName({
    super.key,
    required this.userId,
    this.name,
    this.color,
    this.fontWeight,
    required this.fontSize,
  });

  @override
  State<ReelProfileName> createState() => _ReelProfileNameState();
}

class _ReelProfileNameState extends State<ReelProfileName> {
  // @override
  // bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(ReelProfileName oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Text(
      widget.name ?? "",
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight ?? MFontWeight.bold6.value,
        overflow: TextOverflow.ellipsis,
        color: widget.color ?? Colors.white,
      ),
    );
  }
}
