import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';

import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_content_container.dart';

import 'package:jxim_client/object/message/share_image.dart';

import 'package:jxim_client/views/message/share/new_share_chat_controller.dart';

import 'package:jxim_client/views/component/search_empty_state.dart';

class ShareChatContainer extends StatefulWidget {
  final ShareImage? shareImage;
  final ScrollController? scrollController;
  final DraggableScrollableController? draggableScrollableController;

  const ShareChatContainer({
    super.key,
    this.shareImage,
    this.scrollController,
    this.draggableScrollableController,
  });

  @override
  State<ShareChatContainer> createState() => _ShareChatContainerState();
}

class _ShareChatContainerState extends State<ShareChatContainer> {
  final NewShareChatController controller = Get.find<NewShareChatController>();
  @override
  void initState() {
    super.initState();
    controller.initData(
      widget.scrollController,
      widget.draggableScrollableController,
      widget.shareImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SafeArea(
        child: AnimatedContainer(
          curve: Curves.easeIn,
          duration: Duration(
            milliseconds:
                (MediaQuery.of(Get.context!).viewInsets.bottom != 0) ? 0 : 200,
          ),
          margin: EdgeInsets.only(
            top: MediaQuery.of(Get.context!).viewPadding.top,
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
            left: 10,
            right: 10,
          ),
          color: Colors.transparent,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: !controller.isSearching.value
                                ? NavigationToolbar(
                                    leading: GestureDetector(
                                      onTap: () {
                                        controller.isSearching(true);
                                        controller.searchFocus.requestFocus();
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: OpacityEffect(
                                        child: Image.asset(
                                          'assets/icons/search_icon2.png',
                                          width: 24,
                                          height: 24,
                                          color: themeColor,
                                        ),
                                      ),
                                    ),
                                    middle: Padding(
                                      padding: const EdgeInsets.only(top: 11),
                                      child: Column(
                                        children: [
                                          Text(
                                            localized(shareTo),
                                            style: jxTextStyle.textStyleBold17(
                                              fontWeight:
                                                  MFontWeight.bold6.value,
                                            ),
                                          ),
                                          Text(
                                            controller.selectedChats.isNotEmpty
                                                ? controller.setUsername()
                                                : localized(selectChat),
                                            style: jxTextStyle.textStyle10(
                                              color: colorTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SearchingAppBar(
                                    hintText: localized(search),
                                    onChanged: (value) async {
                                      controller.onSearch(value);
                                    },
                                    onCancelTap: () {
                                      controller.searchFocus.unfocus();
                                      controller.clearSearching();
                                    },
                                    isSearchingMode:
                                        controller.isSearching.value,
                                    isAutoFocus: false,
                                    focusNode: controller.searchFocus,
                                    controller: controller.searchController,
                                    suffixIcon: Visibility(
                                      visible: controller
                                          .searchParam.value.isNotEmpty,
                                      child: GestureDetector(
                                        onTap: () {
                                          controller.searchController.clear();
                                          controller.searchParam.value = '';
                                          controller.onSearch(
                                            controller.searchParam.value,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/svgs/close_round_icon.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: const ColorFilter.mode(
                                              colorTextSupporting,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: controller.filterChatList.isEmpty
                              ? SearchEmptyState(
                                  searchText: controller.searchController.text,
                                  emptyMessage: localized(
                                    oppsNoResultFoundTryNewSearch,
                                    params: [
                                      (controller.searchController.text),
                                    ],
                                  ),
                                )
                              : ForwardContentContainer(
                                  scrollController:
                                      controller.scrollController ??
                                          ScrollController(),
                                  chatList: controller.filterChatList.toList(),
                                  clickCallback: (value) {
                                    if (value.isNotEmpty) {
                                      controller.validSend.value = true;
                                    } else {
                                      controller.validSend.value = false;
                                    }
                                    controller.selectedChats.value = value;
                                  },
                                ),
                        ),
                      ),
                      ClipRRect(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.bottomCenter,
                          curve: Curves.easeInOutCubic,
                          heightFactor: controller.validSend.value ? 1 : 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: colorBorder,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    if (controller
                                        .captionController.text.isEmpty)
                                      Align(
                                        alignment: Alignment.center,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            22,
                                            12,
                                            22,
                                          ),
                                          child: Text(
                                            controller.captionController.text
                                                    .isEmpty
                                                ? localized(writeACaption)
                                                : '',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: colorTextPrimary
                                                  .withOpacity(0.24),
                                              height: 1.25,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 8.0,
                                      ),
                                      child: TextField(
                                        contextMenuBuilder: textMenuBar,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        textAlign: TextAlign.left,
                                        maxLines: 2,
                                        minLines: 1,
                                        focusNode: controller.captionFocus,
                                        controller:
                                            controller.captionController,
                                        keyboardType: TextInputType.multiline,
                                        scrollPhysics:
                                            const ClampingScrollPhysics(),
                                        maxLength: 4096,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(
                                            4096,
                                          ),
                                        ],
                                        cursorColor: themeColor,
                                        style: const TextStyle(
                                          decoration: TextDecoration.none,
                                          fontSize: 16.0,
                                          color: colorTextPrimary,
                                          height: 1.25,
                                          textBaseline: TextBaseline.alphabetic,
                                        ),
                                        enableInteractiveSelection: true,
                                        decoration: InputDecoration(
                                          hintStyle: TextStyle(
                                            fontSize: 16.0,
                                            color: colorTextPrimary
                                                .withOpacity(0.24),
                                            height: 1.25,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                          ),
                                          isDense: true,
                                          fillColor: colorTextPrimary
                                              .withOpacity(0.03),
                                          filled: true,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          isCollapsed: true,
                                          counterText: '',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 16,
                                          ),
                                          suffixIcon: (controller
                                                      .captionController
                                                      .text
                                                      .isNotEmpty ||
                                                  controller
                                                      .captionFocus.hasFocus)
                                              ? IconButton(
                                                  onPressed: () {
                                                    controller.captionController
                                                        .clear();
                                                    setState(() {});
                                                  },
                                                  icon: SvgPicture.asset(
                                                    'assets/svgs/clear.svg',
                                                    width: 14,
                                                    height: 14,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        onTapOutside: (event) {
                                          controller.captionFocus.unfocus();
                                        },
                                        onChanged: (text) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                OverlayEffect(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      controller.onForwardAction(
                                        context,
                                        controller.selectedChats,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            localized(send),
                                            style: jxTextStyle.textStyle16(
                                              color: themeColor,
                                            ),
                                          ),
                                          ImGap.hGap4,
                                          if (controller
                                              .selectedChats.isNotEmpty)
                                            ClipOval(
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                alignment: Alignment.center,
                                                color: themeColor,
                                                child: Text(
                                                  controller
                                                      .selectedChats.length
                                                      .toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Visibility(
                visible: !controller.searchFocus.hasFocus,
                child: OverlayEffect(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Text(
                        localized(buttonCancel),
                        style: jxTextStyle.textStyle16(color: themeColor),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.onDispose();
    super.dispose();
  }
}
