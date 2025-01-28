import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_form_slider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class GroupInviteLinkForm extends StatefulWidget {
  const GroupInviteLinkForm({
    super.key,
    this.isEdit = true,
    this.isSliderEnabled = true,
  });

  final bool isEdit;
  final bool isSliderEnabled;

  @override
  State<GroupInviteLinkForm> createState() => _GroupInviteLinkFormState();
}

class _GroupInviteLinkFormState extends State<GroupInviteLinkForm> {
  final controller = Get.find<GroupInviteLinkController>();

  double get effectiveTimeSliderValue {
    return widget.isEdit
        ? GroupLinkEffectiveTime.getTypeByValue(
                controller.selectedGroupInviteLink.duration!)
            .toDouble()
        : GroupLinkEffectiveTime.noLimit.type.toDouble();
  }

  double get usageLimitSliderValue {
    return widget.isEdit
        ? GroupLinkUsageLimit.getTypeByValue(
                controller.selectedGroupInviteLink.limited!)
            .toDouble()
        : GroupLinkUsageLimit.noLimit.type.toDouble();
  }

  String get linkAliasInputValue {
    return widget.isEdit ? controller.selectedGroupInviteLink.name ?? '' : '';
  }

  void initFormValue() {
    controller.linkAliasInputController.text = linkAliasInputValue;
    controller.setIsSaveButtonEnabled = widget.isSliderEnabled;

    controller.selectedEffectiveTime =
        GroupLinkEffectiveTime.getValueByType(effectiveTimeSliderValue.toInt());
    controller.selectedUsageLimit =
        GroupLinkUsageLimit.getValueByType(usageLimitSliderValue.toInt());
    controller.calcEffectiveTimeSliderSubValue();
    controller.calcUsageLimitSliderSubValue();
  }

  @override
  void initState() {
    controller.isEdit = widget.isEdit;
    initFormValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      title: localized(invitationLink),
      leading: CustomLeadingIcon(
        needPadding: false,
        buttonOnPressed: () =>
            Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null),
      ),
      trailing: Obx(
        () => CustomTextButton(
          !widget.isEdit ? localized(buttonCreate) : localized(saveButton),
          isDisabled: !controller.isSaveButtonEnabled,
          onClick: () {
            if (widget.isEdit) {
              if (!widget.isSliderEnabled) {
                controller.updatePermalink();
              } else {
                controller.updateGroupShareLink();
              }
            } else {
              controller.createGroupShareLink();
            }
          },
        ),
      ),
      useTopSafeArea: true,
      useBottomSafeArea: false,
      middleChild: CustomScrollableListView(
        children: [
          CustomInput(
            maxLength: 32,
            controller: controller.linkAliasInputController,
            title: localized(linkName),
            hintText: localized(linkNameOptional),
            keyboardType: TextInputType.text,
            onChanged: (value) {
              if (!widget.isSliderEnabled) {
                controller.setIsSaveButtonEnabled =
                    value != linkAliasInputValue;
              }
            },
            onTapClearButton: () {
              if (!widget.isSliderEnabled) {
                controller.setIsSaveButtonEnabled =
                    linkAliasInputValue.isNotEmpty;
              }
            },
            descriptionWidget: Text(
              localized(invitationLinkWillDisplayName),
              style: jxTextStyle.textStyle13(color: colorTextLevelTwo),
            ),
          ),
          Obx(
            () => GroupInviteLinkFormSlider(
              sliderHeaderList: controller.effectiveTimeLimitHeaderList,
              sliderValue: effectiveTimeSliderValue,
              bottomSubtitle: controller.effectiveTimeSliderSubValue.value,
              isEnabled: widget.isSliderEnabled,
              onChanged: controller.onEffectiveTimeSliderChanged,
            ),
          ),
          Obx(
            () => GroupInviteLinkFormSlider(
              title: localized(usageLimit),
              sliderHeaderList: controller.usageLimitHeaderList,
              sliderValue: usageLimitSliderValue,
              bottomTitle: localized(remainingTimes),
              bottomSubtitle: controller.usageLimitSliderSubValue.value == 0
                  ? localized(none)
                  : controller.usageLimitSliderSubValue.value.toString(),
              instructionText: localized(linkExpireCertainTimes),
              isEnabled: widget.isSliderEnabled,
              onChanged: controller.onUsageLimitSliderChanged,
            ),
          ),
          if (widget.isEdit && widget.isSliderEnabled)
            CustomButton(
              text: localized(unLinkGroup),
              textColor: colorRed,
              color: colorWhite,
              callBack: controller.revokeGroupLink,
            ),
        ],
      ),
    );
  }
}
