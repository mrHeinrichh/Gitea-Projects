import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class FriendRequestConfirm extends StatefulWidget {
  const FriendRequestConfirm({
    super.key,
    required this.user,
    required this.confirmCallback,
    required this.cancelCallback,
  });

  final User user;
  final Function(String) confirmCallback;
  final Function() cancelCallback;

  @override
  State<FriendRequestConfirm> createState() => _FriendRequestConfirmState();
}

class _FriendRequestConfirmState extends State<FriendRequestConfirm> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController textController = TextEditingController();
  final showClearBtn = false.obs;
  final charsLeft = 30.obs;
  String requestRemark = "";

  @override
  void initState() {
    super.initState();
    getName();

    onTextChanged(requestRemark);
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).viewPadding.bottom > 0
              ? MediaQuery.of(context).viewPadding.bottom + 5
              : 16,
          right: 16,
          left: 16,
        ),
        decoration: const BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OpacityEffect(
                      child: GestureDetector(
                        onTap: widget.cancelCallback,
                        child: Text(
                          localized(cancel),
                          style: jxTextStyle.headerText(
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    OpacityEffect(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          String res = textController.text.trim();
                          if (res == "") {
                            res = localized(defaultFriendRemark);
                          }
                          widget.confirmCallback(res);
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        child: Text(
                          localized(send),
                          style: jxTextStyle.headerText(
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  localized(contactFriendRequest),
                  style: jxTextStyle.textStyleBold17(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localized(sendFriendReq),
                    style: jxTextStyle.normalSmallText(
                      color: colorTextLevelTwo,
                    ),
                  ),
                  Obx(() {
                    return Text(
                      '${charsLeft.value}${localized(charactersLeft)}',
                      style: jxTextStyle.normalSmallText(
                        color: colorTextPlaceholder,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              contextMenuBuilder: im.textMenuBar,
              focusNode: focusNode,
              autofocus: true,
              controller: textController,
              style: const TextStyle(
                color: colorTextPrimary,
                fontSize: 17,
                decorationThickness: 0,
              ),
              inputFormatters: [CustomInputFormatter()],
              buildCounter: (
                BuildContext context, {
                required int currentLength,
                required int? maxLength,
                required bool isFocused,
              }) {
                return null;
              },
              minLines: 1,
              maxLines: 3,
              cursorColor: themeColor,
              maxLength: 30,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorWhite,
                isDense: true,
                hintText: requestRemark,
                hintStyle: jxTextStyle.textStyle17(
                  color: colorTextPlaceholder,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: Obx(
                  () => Visibility(
                    visible: showClearBtn.value,
                    child: GestureDetector(
                      onTap: () => clearRemark(),
                      behavior: HitTestBehavior.opaque,
                      child: OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          child: SvgPicture.asset(
                            'assets/svgs/clear_icon.svg',
                            color: colorTextPlaceholder,
                            width: 14,
                            height: 14,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              onTap: () {
                if (textController.text.isEmpty) {
                  setShowClearBtn(false);
                } else {
                  setShowClearBtn(true);
                }
              },
              onChanged: onTextChanged,
            ),
          ],
        ),
      ),
    );
  }

  onTextChanged(String text) {
    // int currentLeft = 30 - text.length;
    // if (currentLeft <= 0) {
    //   textController.text = textController.text.substring(0, 30);
    //   charsLeft.value = 0;
    // } else {
    //   charsLeft.value = currentLeft;
    // }
    // if (textController.text.isEmpty) {
    //   setShowClearBtn(false);
    // } else {
    //   setShowClearBtn(true);
    // }
    charsLeft.value = 30 - text.runes.length;
    setShowClearBtn(text.isNotEmpty);
  }

  clearRemark() {
    textController.clear();
    charsLeft.value = 30;
    setShowClearBtn(false);
  }

  setShowClearBtn(bool value) {
    showClearBtn.value = value;
  }

  getName() {
    String currentRemark = localized(
      sendRequestRemark,
      params: [objectMgr.userMgr.mainUser.nickname],
    );
    if (currentRemark.length <= 30) {
      requestRemark = currentRemark;
    } else {
      requestRemark = currentRemark.substring(0, 30);
    }
    textController.text = requestRemark;
  }
}
