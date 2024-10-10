import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/media_detail/media_pre_send_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:photo_view/photo_view.dart';

class MediaPreSendView extends GetView<MediaPreSendViewController> {
  const MediaPreSendView({super.key});


  bool keyboardEnabled(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 200;

  @override
  Widget build(BuildContext context) {
    double appBarHeight =
        kToolbarHeight + MediaQuery.of(context).viewPadding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onTap: controller.captionFocus.unfocus,
          child: Stack(
            children: <Widget>[
              Obx(
                    () {
                  // 检查图片数据是否为空
                  if (controller.imageDataList.value.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    return PhotoViewGesturePageView.builder(
                      reverse: false,
                      scrollDirection: Axis.horizontal,
                      controller: controller.photoPageController,
                      itemCount: controller.imageDataList.value.length,
                      onPageChanged: controller.onPageChange,
                      itemBuilder: (BuildContext context, int index) {
                        return PhotoView.file(
                          File(controller.imageDataList.value[index][0]),
                          fit: BoxFit.contain,
                          constraints: const BoxConstraints.expand(),
                        );
                      },
                    );
                  }
                },
              ),
              Obx(
                    () => AnimatedPositioned(
                  top: 0.0 +
                      (controller.showToolOption.value ? 0.0 : -appBarHeight),
                  left: 0.0,
                  right: 0.0,
                  duration: const Duration(milliseconds: 170),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).viewPadding.top,
                    ),
                    height: appBarHeight,
                    color: colorMediaBarBg,
                    child: NavigationToolbar(
                      leading: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: Get.back,
                        child: OpacityEffect(
                          child: SizedBox(
                            width: 90,
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    localized(buttonBack),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      height: 1.25,
                                      fontFamily: appFontfamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      centerMiddle: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0.0,
                right: 0.0,
                child: Obx(()=>selectedBackdrop(context)),
              ),
              Obx(
                    () => AnimatedPositioned(
                  bottom:
                  0.0 + (controller.showToolOption.value ? 0.0 : -250.0),
                  left: 0.0,
                  right: 0.0,
                  duration: const Duration(milliseconds: 170),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: controller.showToolOption.value ? 6.0 : 0.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? max(
                        MediaQuery.of(context).viewInsets.bottom,
                        MediaQuery.of(context).viewPadding.bottom,
                      )
                          : MediaQuery.of(context).viewPadding.bottom,
                    ),
                    color: colorMediaBarBg,
                    child: Column(children: <Widget>[...assetInput(context)]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  List<Widget> assetInput(BuildContext context) {
    return [
      // Show caption
      GetBuilder(
        init: controller,
        id: 'captionChanged',
        builder: (_) {
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: TextField(
                contextMenuBuilder: textMenuBar,
                autocorrect: false,
                enableSuggestions: false,
                textAlignVertical: TextAlignVertical.center,
                textAlign: controller.captionController.text.isNotEmpty ||
                    controller.captionFocus.hasFocus
                    ? TextAlign.left
                    : TextAlign.center,
                maxLines: 4,
                minLines: 1,
                focusNode: controller.captionFocus,
                controller: controller.captionController,
                keyboardType: TextInputType.multiline,
                scrollPhysics: const ClampingScrollPhysics(),
                maxLength: 4096,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4096),
                ],
                cursorColor: Colors.white,
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 16.0,
                  color: colorWhite,
                  height: 1.25,
                  textBaseline: TextBaseline.alphabetic,
                ),
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: localized(writeACaption),
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    color: keyboardEnabled(context)
                        ? colorWhite
                        : colorWhite.withOpacity(0.6),
                    height: 1.25,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                  isDense: true,
                  fillColor: colorWhite.withOpacity(0.2),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  isCollapsed: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                onTapOutside: (event) {
                  controller.captionFocus.unfocus();
                },
              ),
            ),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        height: controller.bottomBarHeight,
        padding:
        const EdgeInsets.only(left: 16.0, right: 16, top: 4.0, bottom: 4.0),
        margin: const EdgeInsets.only(bottom: 6.0),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // GestureDetector(
            //   behavior: HitTestBehavior.translucent,
            //   onTap: () => controller.editAsset(),
            //   child: OpacityEffect(
            //     child: Image.asset(
            //       'assets/images/pen_edit2.png',
            //       width: 24,
            //       height: 24,
            //       color: Colors.white,
            //     ),
            //   ),
            // ),
            OpacityEffect(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.sendImage,
                child: Row(
                  children: [
                    ClipOval(
                      child: Container(
                        color: themeColor,
                        width: 28,
                        height: 28,
                        padding: const EdgeInsets.all(6.0),
                        child: SvgPicture.asset(
                          'assets/svgs/send_arrow.svg',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget selectedBackdrop(BuildContext context) {

    final bool isSelected;
    final int index;

    if(controller.selectedState.value.isNotEmpty && controller.countNumber.value.isNotEmpty) {
      isSelected = controller.selectedState.value[controller.currentPage.value];
      index = controller.countNumber.value[controller.currentPage.value];
    } else {
      isSelected = true;
      index = 1;
    }


    const Duration duration = Duration(milliseconds: 200);

    final Widget innerSelector = AnimatedContainer(
      duration: duration,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 30 / 25,
        ),
        color: isSelected ? themeColor : null,
        shape: BoxShape.circle,
      ),
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        child: isSelected
            ? Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            decoration: TextDecoration.none,
            fontSize: 16,
          ),
        )
            : const SizedBox.shrink(),
      ),
    );
    return Container(
      color: Colors.black.withOpacity(0),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).viewPadding.top + 10.0,
        right: 12.0,
        bottom: 10.0,
      ),
      child: OpacityEffect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (){
            controller.toggleSelection();
          },
          child: Container(
            width: 32,
            height: 32,
            alignment: AlignmentDirectional.topEnd,
            child: innerSelector,
          ),
        ),
      ),
    );
  }
}
