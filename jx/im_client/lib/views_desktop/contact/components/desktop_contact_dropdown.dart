import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';

class DesktopContactDropdown extends GetWidget<ContactController> {
  const DesktopContactDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      //controller: controller.controller,
      pressType: PressType.singleClick,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.menu, color: themeColor),
      ),
      menuBuilder: () => ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: Colors.white,
          width: 500,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Get.toNamed(RouteName.searchUserView,
                      arguments: {'isModalBottomSheet': false});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 40),
                      Text('ADD FRIEND BY PHONE NUMBER'),
                      Icon(Icons.phone),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Get.toNamed(RouteName.searchUserView,
                      arguments: {'isModalBottomSheet': false});
                  //controller.controller.hideMenu();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 40),
                      Text('ADD FRIEND BY USERNAME'),
                      Icon(Icons.alternate_email),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
