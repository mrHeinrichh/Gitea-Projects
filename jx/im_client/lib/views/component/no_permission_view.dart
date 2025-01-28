import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:permission_handler/permission_handler.dart';

class NoPermissionView extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String? mainContent;
  final String? subContent;

  const NoPermissionView({
    super.key,
    required this.title,
    required this.imageUrl,
    this.mainContent = "",
    this.subContent = "",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(
              top: 16.0,
              bottom: 16.0,
              left: 18.0,
              right: 18.0,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: colorBackground6,
                ),
              ),
            ),
            child: Text(
              title,
              style: jxTextStyle.textStyleBold16(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    imageUrl,
                    width: 148,
                    height: 148,
                  ),
                  const SizedBox(height: 16),
                  if (mainContent != "")
                    Text(
                      mainContent ?? "",
                      style: jxTextStyle.textStyleBold16(),
                    ),
                  const SizedBox(height: 4),
                  if (subContent != "")
                    Text(
                      subContent ?? "",
                      style: jxTextStyle.textStyle14(
                        color: colorTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      openAppSettings();
                      Get.back();
                    },
                    child: Text(
                      localized(openSettings),
                      style: jxTextStyle.textStyleBold16(color: themeColor),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
