import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/input/textfield_light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class ChatSearchBar extends StatefulWidget {
  const ChatSearchBar({
    super.key,
    required this.focusNode,
    required this.editingController,
    this.autofocus = false,
    required this.hintText,
    required this.onChange,
    required this.onSearch,
    this.circular = 16,
    this.height = 32,
    this.bgColor,
  });
  final Color? bgColor;
  final FocusNode focusNode;
  final TextEditingController editingController;
  final bool autofocus;
  final String hintText;
  final VoidCallback onChange;
  final VoidCallback onSearch;
  final int circular;
  final int height;

  @override
  ChatSearchBarState createState() => ChatSearchBarState();
}

class ChatSearchBarState extends State<ChatSearchBar> {
  _onClear() {
    widget.editingController.clear();
  }

  bool isShow = false;

  @override
  void initState() {
    super.initState();
    widget.editingController.addListener(() {
      if (!widget.editingController.value.isComposingRangeValid) {
        if (mounted) {
          setState(() {
            isShow = widget.editingController.text.isNotEmpty;
          });
        }
        widget.onChange();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height.w,
      decoration: BoxDecoration(
        color: widget.bgColor ?? hexColor(0xF0F0F0),
        borderRadius: BorderRadius.circular(widget.circular.w),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/message_new/search.png',
            width: 20.w,
            height: 20.w,
          ),
          Expanded(
            flex: 1,
            child: TextFieldLight(
              focusNode: widget.focusNode,
              controller: widget.editingController,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              cursorColor: colorTextPrimary,
              style: TextStyle(
                color: colorTextPrimary,
                fontSize: 15.sp,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: colorWhite,
                  fontSize: 15.sp,
                ),
                counterText: "",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.all(0),
              ),
              onSubmitted: (value) {
                widget.onSearch();
              },
            ),
          ),
          Visibility(
            visible: isShow,
            child: GestureDetector(
              onTap: _onClear,
              child: Image.asset(
                'assets/images/message/search_delected.png',
                width: 24.w,
                height: 24.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
