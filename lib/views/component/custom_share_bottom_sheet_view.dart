import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomShareBottomSheetView extends StatelessWidget {
  const CustomShareBottomSheetView({
    super.key,
    this.title = '',
    this.leading,
    this.showDoneButton = true,
    this.showMainHeader = true,
    this.topWidget,
    this.headerText,
    this.subHeaderText,
    this.showLink = true,
    this.showSecondaryButton= true,
    this.link = '',
    this.onCopyLink,
    this.primaryButtonOnTap,
    this.primaryButtonText,
    this.secondaryButtonOnTap,
    this.secondaryButtonText,
    this.secondaryButtonTextColor,
    this.titlePadding,
  });

  final String title;
  final Widget? leading;
  final bool showDoneButton;
  final bool showMainHeader;
  final Widget? topWidget;
  final String? headerText;
  final String? subHeaderText;
  final bool showLink;
  final bool showSecondaryButton;
  final String link;
  final Function? onCopyLink;
  final Function()? primaryButtonOnTap;
  final String? primaryButtonText;
  final Function()? secondaryButtonOnTap;
  final String? secondaryButtonText;
  final Color? secondaryButtonTextColor;
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
            if (showMainHeader) ...[
              topWidget ??
                  Container(
                    height: 100,
                    width: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeColor,
                    ),
                    child: const CustomImage(
                      'assets/svgs/invite_link_outlined.svg',
                      size: 52,
                      color: colorWhite,
                    ),
                  ),
              const SizedBox(height: 16),
              Text(
                headerText ?? localized(invitationLink),
                style: jxTextStyle.textStyleBold28(),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Padding(
                padding: EdgeInsets.only(top: 8, bottom: showLink ? 16 : 0),
                child: Text(
                  subHeaderText ?? localized(anyoneJoinGroupViaLink),
                  style: jxTextStyle.textStyle17(color: colorTextSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (showLink)
              Container(
                decoration: BoxDecoration(
                  color: colorTextPrimary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        style: jxTextStyle.textStyle17(),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    CustomImage(
                      'assets/svgs/copyURL_icon.svg',
                      size: 24,
                      color: colorTextPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      onClick: () {
                        onCopyLink?.call();
                      },
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CustomButton(
                text: primaryButtonText ?? localized(shareGroupLink),
                height: 48,
                callBack: primaryButtonOnTap,
              ),
            ),
            if (showSecondaryButton)
              CustomTextButton(
                secondaryButtonText ?? localized(manageInviteLinks),
                isBold: true,
                color: secondaryButtonTextColor ?? themeColor,
                padding: const EdgeInsets.all(13),
                onClick: secondaryButtonOnTap,
              ),
          ],
        ),
      ),
    );
  }
}
