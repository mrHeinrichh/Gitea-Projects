import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/contact/local_contact_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:jxim_client/views/contact/local_contact_controller.dart';

class AppContactView extends GetView<LocalContactController> {
  const AppContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (state) {
        return Obx(
          () => controller.appContactList.isNotEmpty
              ? ListView.separated(
                  itemCount: controller.appContactList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final User user = controller.appContactList[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: ContactCard(
                        user: user,
                        subTitle: UserUtils.onlineStatus(user.lastOnline),
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 80.w),
                      child: const CustomDivider(),
                    );
                  },
                )
              : const FriendEmptyState(),
        );
      },
      onLoading: Center(
        child: SizedBox(
          width: 75,
          height: 75,
          child: BallCircleLoading(
            radius: 25,
            ballStyle: BallStyle(
              size: 10,
              color: themeColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: themeColor,
            ),
          ),
        ),
      ),
    );
  }
}
