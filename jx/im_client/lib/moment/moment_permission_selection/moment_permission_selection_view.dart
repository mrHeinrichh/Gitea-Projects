import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/models/permission_selection_composite.dart';
import 'package:jxim_client/moment/moment_permission_selection/moment_permission_selection_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class MomentPermissionSelectionView
    extends GetView<MomentPermissionSelectionController> {
  const MomentPermissionSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async{
          controller.back(context);
          return false;
        },
        child: Scaffold(
          backgroundColor: colorBackground,
          appBar: PrimaryAppBar(
            isBackButton: false,
            title: localized(momentVisibleTo),
            leading: GestureDetector(
              onTap:()=> controller.back(context),
              child: OpacityEffect(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 10.0,
                    bottom: 10.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_outlined,
                        size: 28.0,
                        color: themeColor,
                      ),
                      Text(
                        localized(chatInfoBack),
                        style: jxTextStyle.textStyle17(color: themeColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            trailing: <Widget>[
              GestureDetector(
                onTap: controller.onTapFinish,
                child: OpacityEffect(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 16.0,
                      top: 10.0,
                      bottom: 10.0,
                    ),
                    child: Text(
                      localized(buttonDone),
                      style: jxTextStyle.textStyle17(color: themeColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: GetBuilder(
              init: controller,
              id: 'permissionSelection',
              builder: (_) {
                return ListView.builder(
                  itemCount: controller.permissionSelection.value.getPermissionItem().length,
                  itemBuilder: (BuildContext context, int index)
                  {
                    PermissionSelectionComposite pi = controller.permissionSelection.value.getPermissionItem()[index];

                    //當選擇的不是部分可見項目，不顯示好友與標籤兩個選項。
                    if ((pi.momentVisibility == MomentVisibility.subLabel) ||
                        (controller.selectedPermissionSelection.value!.momentVisibility != MomentVisibility.specificFriends) &&
                            (pi.momentVisibility == MomentVisibility.specificBest || pi.momentVisibility == MomentVisibility.specificLabel) ||
                        (controller.selectedPermissionSelection.value!.momentVisibility != MomentVisibility.hideFromSpecificFriends) &&
                            (pi.momentVisibility == MomentVisibility.hideBest || pi.momentVisibility == MomentVisibility.hideLabel)
                    ) {
                      return const SizedBox();
                    }

                    PermissionSelection? subLabel;
                    if (pi.momentVisibility == MomentVisibility.specificLabel || pi.momentVisibility == MomentVisibility.hideLabel) {
                      subLabel = controller.selectedPermissionSelection.value as PermissionSelection;
                    }

                    return GestureDetector(
                      onTap: () {
                        controller.onItemTap(pi);
                      },
                      child: Container(
                        padding: index == 0
                            ? const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 5,)
                            : const EdgeInsets.only(left: 5, right: 5, top: 3, bottom: 5,),
                        decoration: BoxDecoration(borderRadius: index == 0
                            ? const BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(15.0),)
                            : index == controller.permissionSelection.value.getPermissionItem().length - 1
                            ? const BorderRadius.only(
                          bottomLeft: Radius.circular(15.0),
                          bottomRight: Radius.circular(15.0),)
                            : null,
                          color: Colors.white,
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ///Title
                                            Container(
                                              padding: pi.momentVisibility == MomentVisibility.specificBest  ||
                                                  pi.momentVisibility == MomentVisibility.specificLabel ||
                                                  pi.momentVisibility == MomentVisibility.hideBest  ||
                                                  pi.momentVisibility == MomentVisibility.hideLabel
                                                  ? const EdgeInsets.only(left: 32)
                                                  : const EdgeInsets.only(left: 10),
                                              child: Text(
                                                  pi.momentVisibility.title,
                                                  style: jxTextStyle.textStyle17(color: pi.momentVisibility == MomentVisibility.specificBest  ||
                                                      pi.momentVisibility == MomentVisibility.specificLabel ||
                                                      pi.momentVisibility == MomentVisibility.hideBest ||
                                                      pi.momentVisibility == MomentVisibility.hideLabel?themeColor:colorTextPrimary,)
                                              ),
                                            ),
                                            const SizedBox(height: 2.0),

                                            ///subTitle
                                            Container(
                                              padding:pi.momentVisibility == MomentVisibility.specificBest  ||
                                                  pi.momentVisibility == MomentVisibility.specificLabel ||
                                                  pi.momentVisibility == MomentVisibility.hideBest  ||
                                                  pi.momentVisibility == MomentVisibility.hideLabel
                                                  ? const EdgeInsets.only(left: 32)
                                                  : const EdgeInsets.only(left: 10),
                                              child: Text(pi.momentVisibility == MomentVisibility.public
                                                  ? localized(momentPermissionPublic,)
                                                  : pi.momentVisibility == MomentVisibility.private
                                                  ? localized(momentPermissionPrivate,)
                                                  : pi.momentVisibility == MomentVisibility.specificFriends
                                                  ? localized(momentPermissionVisibleTo,)
                                                  : pi.momentVisibility == MomentVisibility.hideFromSpecificFriends
                                                  ? pi.getSelectFriends().isEmpty
                                                  ? localized(momentPermissionExcludedFrom,)
                                                  : pi.getSelectFriends()
                                                  .map((e) => e.nickname,)
                                                  .toList()
                                                  .join(", ")
                                                  : pi.momentVisibility == MomentVisibility.specificBest
                                                  ? pi.getSelectFriends().isEmpty
                                                  ? localized(momentPermissionSelectFriends,)
                                                  : pi.getSelectFriends()
                                                  .map((e) => e.alias.isNotEmpty?e.alias:e.nickname,)
                                                  .toList()
                                                  .join(", ",)
                                                  : pi.momentVisibility == MomentVisibility.specificLabel
                                                  ? subLabel!.getSelectLabel().isEmpty
                                                  ? localized(momentPermissionSelectTags,)
                                                  : subLabel.getSelectLabel()
                                                  .map((e) => e,)
                                                  .toList()
                                                  .join(", ")
                                                  : pi.momentVisibility == MomentVisibility.hideBest
                                                  ? pi.getSelectFriends().isEmpty
                                                  ? localized(momentPermissionSelectFriends,)
                                                  : pi.getSelectFriends()
                                                  .map((e) => e.alias.isNotEmpty?e.alias:e.nickname,)
                                                  .toList()
                                                  .join(", ",)
                                                  : pi.momentVisibility == MomentVisibility.hideLabel
                                                  ? subLabel!.getSelectLabel().isEmpty
                                                  ? localized(momentPermissionSelectTags,)
                                                  : subLabel.getSelectLabel()
                                                  .map((e) => e,)
                                                  .toList()
                                                  .join(", ")
                                                  :"",
                                                style: jxTextStyle.textStyle13(color:
                                                (pi.momentVisibility == MomentVisibility.hideBest && pi.getSelectFriends().isNotEmpty) ||
                                                    (pi.momentVisibility == MomentVisibility.hideLabel && subLabel!.getSelectLabel().isNotEmpty)
                                                    ? const Color(0xffeb4b35)
                                                    : colorTextSecondary,),
                                                maxLines: null,
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (controller.selectedPermissionSelection.value!.momentVisibility == pi.momentVisibility)
                                  Container(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Center(
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(controller.selectedPermissionSelection.value!.momentVisibility == MomentVisibility.hideFromSpecificFriends
                                              ? const Color(0xffeb4b35)
                                              : themeColor
                                              ,BlendMode.srcIn),
                                          child:  SvgPicture.asset(
                                            'assets/svgs/check1.svg',
                                            height: 24.0,
                                            width: 24.0,
                                          ),
                                        ),
                                      )
                                  ),

                                if (pi.momentVisibility == MomentVisibility.specificBest ||
                                    pi.momentVisibility == MomentVisibility.specificLabel ||
                                    pi.momentVisibility == MomentVisibility.hideBest ||
                                    pi.momentVisibility == MomentVisibility.hideLabel
                                )
                                  Container(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/svgs/arrow_right.svg',
                                        width: 20.0,
                                        height: 20.0,
                                        colorFilter: const ColorFilter.mode(
                                          colorTextSecondary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            index != controller.permissionSelection.value.getPermissionItem().length - 1
                                ? Padding(
                              padding: pi.momentVisibility == MomentVisibility.specificBest || pi.momentVisibility == MomentVisibility.specificLabel
                                  ? const EdgeInsets.only(left: 32, top: 2)
                                  : const EdgeInsets.only(left: 10, top: 2),
                              child: const Align(
                                alignment: Alignment.bottomCenter,
                                child: Divider(
                                  height: 6,
                                  color: colorTextPlaceholder,
                                ),
                              ),
                            )
                                : const SizedBox(height: 3,),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ), );
  }
}
