import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../im/custom_input/component/text_input_field.dart';
import '../../object/chat/chat.dart';
import 'custom_avatar.dart';

class CustomAvatarHero extends StatelessWidget {
  const CustomAvatarHero({
    Key? key,
    required this.id,
    this.chat,
    required this.size,
    this.isGroup = false,
    this.withOption = false,
    this.widget,
    this.widgetName,
    this.showInitial = false,
    this.showAutoDeleteIcon = true,
    this.fontSize,
  }) : super(key: key);

  final int id;
  final Chat? chat;
  final double size;
  final bool isGroup;
  final bool withOption;
  final Widget? widget;
  final String? widgetName;
  final bool showInitial;
  final bool showAutoDeleteIcon;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return widget != null
        ? GestureDetector(
            child: widget,
          )
        : Stack(
            children: [
              chat != null
                  ? CustomAvatar(
                      uid: id,
                      size: size,
                      isGroup: isGroup,
                      fontSize: 30,
                    )
                  : CustomAvatar(
                      uid: id,
                      size: size,
                      isGroup: isGroup,
                      fontSize: 30,
                    ),
              Positioned(right: 0, bottom: 0, child: autoDeleteIcon()),
            ],
          );
  }

  Widget autoDeleteIcon() {
    if (chat != null && chat!.autoDeleteEnabled && showAutoDeleteIcon) {
      return Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/icon_autodelete.png"),
            fit: BoxFit.cover,
          ),
        ),
        width: 20,
        height: 20,
        child: Center(
            child: Text(
          parseAutoDeleteInterval(chat!.autoDeleteInterval).toUpperCase(),
          style: const TextStyle(fontSize: 8, color: Colors.white),
        )),
      );
    }
    return const SizedBox();
  }
}

///选项的主键
class OptionWidget extends StatelessWidget {
  const OptionWidget({
    super.key,
    this.optionColor = Colors.black,
    this.optionBackground = Colors.white,
    required this.iconData,
    required this.function,
  });

  final Color optionColor;
  final Color optionBackground;
  final IconData iconData;
  final Function() function;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.back();
        function.call();
      },
      child: Container(
        width: 56.h,
        height: 56.h,
        decoration: BoxDecoration(
          color: optionBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          size: 24,
          color: optionColor,
        ),
      ),
    );
  }
}
