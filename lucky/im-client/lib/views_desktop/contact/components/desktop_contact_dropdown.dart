import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes.dart';
import '../../../utils/color.dart';
import '../../../views/contact/contact_controller.dart';

class DesktopContactDropdown extends GetWidget<ContactController> {
  const DesktopContactDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      //controller: controller.controller,
      pressType: PressType.singleClick,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.menu, color: accentColor),
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
                  Get.toNamed(RouteName.searchUserView);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      const Text('ADD FRIEND BY PHONE NUMBER'),
                      const Icon(Icons.phone),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Get.toNamed(RouteName.searchUserView);
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      const Text('ADD FRIEND BY USERNAME'),
                      const Icon(Icons.alternate_email),
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
