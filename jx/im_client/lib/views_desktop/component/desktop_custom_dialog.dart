import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/custom_image.dart';
import 'package:jxim_client/views/component/custom_text_button.dart';

class DesktopCustomDialog extends StatelessWidget {
  final String title;
  final String buttonName;
  final Color? buttonColor;
  final Widget contentWidget;
  final double? height;
  final void Function()? buttonClick;
  final BoxConstraints? boxConstraints;

  const DesktopCustomDialog({
    super.key,
    required this.title,
    required this.buttonName,
    this.buttonColor,
    required this.contentWidget,
    this.height,
    this.buttonClick,
    this.boxConstraints,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
            clipBehavior: Clip.hardEdge,
            width: 360,
          height: height,
          constraints: boxConstraints,
          decoration: BoxDecoration(
            color: colorBackground,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopBar(),
              _buildContent(),
              _buildButton(),
            ]
          )
        )
      )
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: customBorder,
        color: colorWhite,
      ),
      child: NavigationToolbar(
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: CustomImage(
              'assets/svgs/close_round_outlined.svg',
              color: themeColor,
              padding: const EdgeInsets.only(left: 20),
              size: 24,
              onClick: ()=> Get.back(),
            ),
          ),
          middle: Text(title),
      ),
    );
  }

  Widget _buildContent(){
      return contentWidget;
  }

  Widget _buildButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: colorWhite,
        border: Border(
            top: BorderSide(
              color: colorDivider,
              width: 0.33,
            ),
        ),
      ),
      child: Center(
        child: CustomTextButton(
          buttonName,
          fontSize: 14,
          color: buttonColor ?? themeColor,
          onClick: buttonClick,
        ),
      ),
    );
  }
}
