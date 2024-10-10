import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/message/chat/face/sticker_controller.dart';

class EditStickerView extends GetView<StickerController> {
  const EditStickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_sharp),
        ),
        title: const Text(
          "Edit Sticker",
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.all(10.h),
                child: Text(
                  "Create your own sticker",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          } else if (index == 1) {
            return GestureDetector(
              onTap: () async {},
              child: Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: EdgeInsets.all(10.h),
                  child: Image.asset(
                    'assets/images/message_new/add_expression1.png',
                    width: 125,
                    height: 125,
                  ),
                ),
              ),
            );
          } else if (index == 2) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.all(10.h),
                child: Text(
                  localized(stickersInThePack),
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
