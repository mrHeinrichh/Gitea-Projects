import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_image.dart';
import 'package:jxim_client/views/component/hover_click_builder.dart';

class DesktopImagePicker extends StatelessWidget {
  final Offset offset;
  final void Function()? onFilePicker;
  final void Function()? onDelete;

  const DesktopImagePicker({
    super.key,
    required this.offset,
    this.onFilePicker,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          key: GlobalKey(),
          left: offset.dx,
          top: offset.dy,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          child: Material(
            elevation: 8,
            clipBehavior: Clip.hardEdge,
            color: colorWhite,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 180),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.75),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: colorTextPrimary.withOpacity(0.15),
                  )
                ],
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.5, sigmaY: 8.5),
                child: Column(
                  children: [
                    imagePickerItem(
                      text: localized(groupEditFromGallery),
                      icon: 'assets/svgs/gallery_album.svg',
                      iconColor: colorTextPrimary,
                      onTap: onFilePicker,
                    ),
                    imagePickerItem(
                      text: localized(groupEditDeletePhoto),
                      textColor: colorRed,
                      icon: 'assets/svgs/delete_icon_new.svg',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget imagePickerItem({
    required String text,
    Color? textColor,
    required String icon,
    Color? iconColor,
    required void Function()? onTap,
  }) {
    return HoverClickBuilder(
      builder: (bool isHovered, bool isPressed) {
        return Transform.scale(
            scale: isPressed ? 0.95 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: isHovered || isPressed ? colorBackground6 : null,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        text,
                        style: jxTextStyle.slidableTextStyle(
                          color: textColor,
                        ),
                      ),
                      CustomImage(
                        icon,
                        color: iconColor,
                        size: 17,
                      )
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }
}
