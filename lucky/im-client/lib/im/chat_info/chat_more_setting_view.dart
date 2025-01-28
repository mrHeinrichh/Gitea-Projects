import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_setting_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class ChatMoreSettingView extends GetView<MoreSettingController> {
  const ChatMoreSettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(homeSetting),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
            top: 0.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Card(
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: Colors.white,
          child: Obx(
            () => ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: controller.moreVertOptions.length,
              itemBuilder: (context, index) {
                return Visibility(
                  visible: controller.moreVertOptions[index].isShow,
                  child: GestureDetector(
                    onTap: () {
                      controller.onTap(context,
                          controller.moreVertOptions[index].optionType);
                    },
                    child: ListTile(
                      title: Text(controller.moreVertOptions[index].title,
                          style: jxTextStyle.textStyle16(
                            color: controller.moreVertOptions[index].color ??
                                primaryTextColor,
                          )),
                      trailing: Visibility(
                        visible:
                            controller.moreVertOptions[index].trailing ?? false,
                        child: SvgPicture.asset(
                          'assets/svgs/right_arrow.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider(height: 0);
              },
            ),
          ),
        ),
      ),
    );
  }
}
