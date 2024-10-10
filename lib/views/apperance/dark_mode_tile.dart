import 'package:get/get.dart';
import 'package:jxim_client/views/apperance/appearance_controller.dart';
import 'package:flutter/material.dart';

class DarkModeTile extends GetWidget<AppearanceController> {
  const DarkModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppearanceController>(
      init: controller,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1, color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              const Text('Night Mode'),
              const Spacer(),
              Switch(
                value: controller.isDarkMode,
                activeColor: const Color(0xFF57C055),
                onChanged: controller.updateDarkMode,
              ),
            ],
          ),
        );
      },
    );
  }
}