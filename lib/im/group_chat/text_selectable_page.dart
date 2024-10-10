import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/group_chat/text_selectable_controller.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/group/customize_selectable_text.dart';

class TextSelectablePage extends GetView<TextSelectableController> {
  const TextSelectablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          controller.onClick(context);
        },
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(
              top: 44,
            ),
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              bottom: 0,
            ),
            alignment: Alignment.center,
            child: CustomizeSelectableText.rich(
              TextSpan(
                children: controller.getTextSpans(),
              ),
              style: jxTextStyle.textStyle28(color: const Color(0xff121212)),
              contextMenuBuilder: controller.textMenuBar,
              onSelectionChanged: (
                TextSelection selection,
                SelectionChangedCause? cause,
                CustomizeTextSpanEditingController editingController,
              ) {
                controller.onSelectionChanged(
                  selection,
                  cause,
                  editingController,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
