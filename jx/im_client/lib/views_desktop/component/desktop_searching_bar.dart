import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class DesktopSearchingBar extends StatefulWidget {
  const DesktopSearchingBar({
    super.key,
    this.height = 40,
    this.fontSize = 15,
    this.iconSize = 25,
    this.fontWeight = FontWeight.w400,
    this.autoFocus = true,
    this.onChanged,
    this.controller,
    this.suffixIcon,
    this.inputType = TextInputType.text,
    this.horizontalPadding = 5,
    this.focusNode,
  });

  final double height;
  final double fontSize;
  final double iconSize;
  final FontWeight fontWeight;
  final bool autoFocus;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final TextInputType inputType;
  final double horizontalPadding;
  final FocusNode? focusNode;

  @override
  State<DesktopSearchingBar> createState() => _DesktopSearchingBarState();
}

class _DesktopSearchingBarState extends State<DesktopSearchingBar> {
  final FocusNode focusNode = FocusNode();
  bool isSelected = false;

  @override
  void initState() {
    super.initState();
    (widget.focusNode ?? focusNode).addListener(() {
      setState(() {
        isSelected = (widget.focusNode ?? focusNode).hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colorBackground6,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          autofocus: widget.autoFocus,
          focusNode: widget.focusNode ?? focusNode,
          cursorColor: Colors.black,
          cursorHeight: widget.fontSize,
          maxLines: 1,
          enabled: true,
          onChanged: widget.onChanged,
          controller: widget.controller,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: widget.inputType,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            letterSpacing: 0.25,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isCollapsed: true,
            // contentPadding: EdgeInsets.symmetric(vertical: widget.fontSize / 2),
            prefixIcon: Icon(
              Icons.search,
              color: colorTextSupporting,
              size: widget.iconSize,
            ),
            hintText: localized(search),
            hintStyle: TextStyle(
              fontSize: widget.fontSize,
              color: colorTextSupporting,
              fontWeight: widget.fontWeight,
              letterSpacing: 0.25,
            ),
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ),
    );
  }
}
