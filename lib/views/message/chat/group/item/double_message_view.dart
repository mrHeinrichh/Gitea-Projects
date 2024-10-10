import 'package:jxim_client/object/chat/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class DoubleMessageView extends StatefulWidget {
  const DoubleMessageView({
    super.key,
    required this.messageText,
  });

  final MessageText messageText;

  @override
  State<DoubleMessageView> createState() => _DoubleMessageViewState();
}

class _DoubleMessageViewState extends State<DoubleMessageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorWhite,
      body: Container(
        padding: EdgeInsets.fromLTRB(16.w, 64.w, 16.w, 20.w),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Text(
            widget.messageText.text,
            style: TextStyle(
              color: colorTextPrimary,
              fontSize: 18.sp,
              height: 1.4,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}