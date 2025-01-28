import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/views/contact/local_contact_controller.dart';
import 'package:jxim_client/views/contact/local_contact_view.dart';
import '../../home/component/custom_divider.dart';
import '../../object/user.dart';
import '../../utils/loading/ball_circle_loading.dart';
import '../../utils/color.dart';
import '../../utils/loading/ball.dart';
import '../../utils/loading/ball_style.dart';
import '../../utils/user_utils.dart';
import 'components/contact_card.dart';

class DeviceContactView extends GetView<LocalContactController> {
  const DeviceContactView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (state) {
        return Container(
          child: Obx(
            () => controller.deviceContactList.isNotEmpty
                ? ListView.separated(
                    itemCount: controller.deviceContactList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final User user = controller.deviceContactList[index];
                      return ContactCard(
                        user: user,
                        subTitle: UserUtils.onlineStatus(user.lastOnline),
                        trailing: [controller.getTrailing(user)],
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
          ),
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
              color: accentColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: accentColor,
            ),
          ),
        ),
      ),
    );
  }
}
