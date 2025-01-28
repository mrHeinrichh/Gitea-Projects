import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DoubleMessageView extends StatefulWidget {
  DoubleMessageView({
    Key? key,
    required this.messageText,
  }) : super(key: key);

  final MessageText messageText;

  @override
  State<DoubleMessageView> createState() => _DoubleMessageViewState();
}

class _DoubleMessageViewState extends State<DoubleMessageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFFFFFF,
      body: Container(
        padding: EdgeInsets.fromLTRB(16.w, 64.w, 16.w, 20.w),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            // padding: EdgeInsets.fromLTRB(16.w, 80.w, 16.w, 80.w),
            child: Text(
              widget.messageText.text,
              style: TextStyle(
                color: color000000,
                fontSize: 18.sp,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
