import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomEncryptionBottomSheetView extends StatelessWidget {
  const CustomEncryptionBottomSheetView({
    super.key,
    this.title = '',
    this.leading,
    this.showDoneButton = true,
    this.showMainHeader = true,
    this.listItems,
    this.headerText,
    this.subHeaderText,
    this.primaryButtonOnTap,
    this.primaryButtonText,
    this.titlePadding,
    this.content,
  });

  final String title;
  final Widget? leading;
  final bool showDoneButton;
  final bool showMainHeader;
  final String? headerText;
  final String? subHeaderText;
  final List<String>? listItems;
  final Widget? content;
  final Function()? primaryButtonOnTap;
  final String? primaryButtonText;
  final EdgeInsetsGeometry? titlePadding;

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      headerHeight: 64,
      title: title,
      titlePadding: titlePadding,
      leading: leading,
      trailing: showDoneButton
          ? CustomTextButton(
              localized(buttonDone),
              onClick: Get.back,
            )
          : const SizedBox.shrink(),
      middleChild: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (content != null)
              content!,
            if (showMainHeader) ...[
              const SizedBox(height: 16),
              Text(
                headerText ?? localized(invitationLink),
                style: jxTextStyle.textStyleBold28(),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Padding(
                padding:
                    EdgeInsets.only(left: 8, top: 16, bottom: listItems != null ? 16 : 0, right: 8),
                child: Text(
                  subHeaderText ?? localized(anyoneJoinGroupViaLink),
                  style: jxTextStyle.textStyle17(color: colorTextSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (listItems != null)
              ...List.generate(
                listItems!.length,
                (index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "\u2022 ${listItems![index]}",
                        style: jxTextStyle.textStyle15(color: Colors.black).copyWith(height: 1.75),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  );
                },
              ),
            if (primaryButtonOnTap != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CustomButton(
                text: primaryButtonText ?? localized(shareGroupLink),
                height: 48,
                callBack: primaryButtonOnTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
