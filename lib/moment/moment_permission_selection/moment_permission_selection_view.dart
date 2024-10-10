import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/models/permission_selection_composite.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import 'package:jxim_client/moment/moment_permission_selection/moment_permission_selection_controller.dart';

class MomentPermissionSelectionView
    extends GetView<MomentPermissionSelectionController> {
  const MomentPermissionSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        isBackButton: false,
        title: localized(momentVisibleTo),
        leading: GestureDetector(
          onTap: Get.back,
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
            onTap: () {},
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
              itemCount: controller.permissionSelection.value
                  .getPermissionItem()
                  .length,
              itemBuilder: (BuildContext context, int i) {
                PermissionSelectionComposite pi =
                    controller.permissionSelection.value.getPermissionItem()[i];
                //當選擇的不是部分可見項目，不顯示好友與標籤兩個選項。
                if (pi.momentVisibility == MomentVisibility.subLabel ||
                    controller.selectedPermissionSelection.value!
                                .momentVisibility !=
                            MomentVisibility.specificFriends &&
                        (pi.momentVisibility == MomentVisibility.best ||
                            pi.momentVisibility == MomentVisibility.label)) {
                  return const SizedBox();
                }

                PermissionSelectionComposite? subLabel;
                if (pi.momentVisibility == MomentVisibility.label) {
                  subLabel = controller.selectedPermissionSelection.value
                      as PermissionSelection;
                }

                return GestureDetector(
                  onTap: () {
                    controller.onItemTap(pi);
                  },
                  child: Container(
                    padding: i == 0
                        ? const EdgeInsets.only(
                            left: 5,
                            right: 5,
                            top: 10,
                            bottom: 5,
                          )
                        : const EdgeInsets.only(
                            left: 5,
                            right: 5,
                            top: 3,
                            bottom: 5,
                          ),
                    decoration: BoxDecoration(
                      borderRadius: i == 0
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(15.0),
                              topRight: Radius.circular(15.0),
                            )
                          : i ==
                                  controller.permissionSelection.value
                                          .getPermissionItem()
                                          .length -
                                      1
                              ? const BorderRadius.only(
                                  bottomLeft: Radius.circular(15.0),
                                  bottomRight: Radius.circular(15.0),
                                )
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: pi.momentVisibility ==
                                                      MomentVisibility.best ||
                                                  pi.momentVisibility ==
                                                      MomentVisibility.label
                                              ? const EdgeInsets.only(left: 32)
                                              : const EdgeInsets.only(left: 10),
                                          child: Text(
                                            pi.momentVisibility.title,
                                            style: pi.momentVisibility ==
                                                        MomentVisibility.best ||
                                                    pi.momentVisibility ==
                                                        MomentVisibility.label
                                                ? jxTextStyle.textStyle17(
                                                    color: themeColor,
                                                  )
                                                : jxTextStyle.textStyle17(
                                                    color: colorTextPrimary,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 2.0),
                                        Container(
                                          padding: pi.momentVisibility ==
                                                      MomentVisibility.best ||
                                                  pi.momentVisibility ==
                                                      MomentVisibility.label
                                              ? const EdgeInsets.only(left: 32)
                                              : const EdgeInsets.only(left: 10),
                                          child: Text(
                                            pi.momentVisibility ==
                                                    MomentVisibility.public
                                                ? localized(
                                                    momentPermissionPublic,
                                                  )
                                                : pi.momentVisibility ==
                                                        MomentVisibility.private
                                                    ? localized(
                                                        momentPermissionPrivate,
                                                      )
                                                    : pi.momentVisibility ==
                                                            MomentVisibility
                                                                .specificFriends
                                                        ? localized(
                                                            momentPermissionPartiallyVisible,
                                                          )
                                                        : pi.momentVisibility ==
                                                                MomentVisibility
                                                                    .hideFromSpecificFriends
                                                            ? pi
                                                                    .getSelectFriends()
                                                                    .isEmpty
                                                                ? localized(
                                                                    momentPermissionHiddenFrom,
                                                                  )
                                                                : pi
                                                                    .getSelectFriends()
                                                                    .map(
                                                                      (e) => e
                                                                          .nickname,
                                                                    )
                                                                    .toList()
                                                                    .join(", ")
                                                            : pi.momentVisibility ==
                                                                    MomentVisibility
                                                                        .best
                                                                ? pi
                                                                        .getSelectFriends()
                                                                        .isEmpty
                                                                    ? localized(
                                                                        momentPermissionSelectFriends,
                                                                      )
                                                                    : pi
                                                                        .getSelectFriends()
                                                                        .map(
                                                                          (e) =>
                                                                              e.nickname,
                                                                        )
                                                                        .toList()
                                                                        .join(
                                                                          ", ",
                                                                        )
                                                                : pi.momentVisibility ==
                                                                        MomentVisibility
                                                                            .label
                                                                    ? subLabel!
                                                                            .getSelectLabel()
                                                                            .isEmpty
                                                                        ? localized(
                                                                            momentPermissionSelectTags,
                                                                          )
                                                                        : subLabel
                                                                            .getSelectLabel()
                                                                            .map(
                                                                              (e) => e,
                                                                            )
                                                                            .toList()
                                                                            .join(", ")
                                                                    : "",
                                            style: jxTextStyle.textStyle15(
                                              color: colorTextSecondary,
                                            ),
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
                            if (controller.selectedPermissionSelection.value!
                                    .momentVisibility ==
                                pi.momentVisibility)
                              Container(
                                padding: const EdgeInsets.only(right: 10),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/svgs/check.svg',
                                    width: 20.0,
                                    height: 20.0,
                                  ),
                                ),
                              ),
                            if (pi.momentVisibility == MomentVisibility.best ||
                                pi.momentVisibility == MomentVisibility.label)
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
                        i !=
                                controller.permissionSelection.value
                                        .getPermissionItem()
                                        .length -
                                    1
                            ? Padding(
                                padding: pi.momentVisibility ==
                                            MomentVisibility.best ||
                                        pi.momentVisibility ==
                                            MomentVisibility.label
                                    ? const EdgeInsets.only(left: 32, top: 2)
                                    : const EdgeInsets.only(left: 10, top: 2),
                                child: const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Divider(
                                    height: 6,
                                    color: colorBorder,
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 3,
                              ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget selectedFriends(PermissionItem pi) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: pi.getSelectFriends().length,
      itemBuilder: (BuildContext context, int i) {
        User user = pi.getSelectFriends()[i];
        return Container(
          margin: const EdgeInsets.only(right: 5),
          child: Text(user.nickname),
        );
      },
    );
  }
}
