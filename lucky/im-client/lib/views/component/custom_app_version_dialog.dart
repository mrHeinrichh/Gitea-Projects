import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_button.dart';

class CustomAppVersionDialog extends StatelessWidget {
  CustomAppVersionDialog({
    Key? key,
    required this.title,
    required this.content,
    this.subContent = "",
    this.isRecommendUninstall = false,
    required this.callBack,
  }) : super(key: key);

  final String title;
  final String content;
  final String? subContent;
  final bool? isRecommendUninstall;
  final Function() callBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        // color: Colors.red,
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/app_version_icon.png',
            width: 56,
            height: 56,
          ),
          Text(
            title,
            style: jxTextStyle.textStyleBold20(),
          ),
          const SizedBox(height: 16.0),
          Text(
            textAlign: TextAlign.center,
            content,
            style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
          ),
          Visibility(
            visible: (subContent != ""),
            child: Container(
              width: 200,
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localized(newUpdate),
                    style:
                    jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
                  ),
                  Text(
                    "1. ${subContent!}",
                    style:
                        jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isRecommendUninstall!,
            child: Container(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                textAlign: TextAlign.center,
                localized(highlyRecommendToUninstall),
                style:
                jxTextStyle.textStyle14(color: errorColor),
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          getObservableView()

        ],
      ),
    );
  }

  Widget getObservableView(){
    final controller = Get.find<HomeController>();

    return Obx(() {
      final progress = controller.apkDownloadProgress.value;
      return progress > 0 ? _loadBar(progress) : _updateBtn();
    });
  }

  Widget _updateBtn(){
    return CustomButton(
      text: localized(updates),
      callBack: () {
        callBack();
      },
    );
  }

  Widget _loadBar(double progress){
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          color: const Color(0xFFFFFFFF),
          value: progress,
        ),
      ),
    );
  }
}
