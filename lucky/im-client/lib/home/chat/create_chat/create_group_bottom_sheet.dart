import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/azItem.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/utils/user_utils.dart';

class CreateGroupBottomSheet extends StatelessWidget {
  const CreateGroupBottomSheet({
    Key? key,
    required this.controller,
    required this.cancelCallback,
  }) : super(key: key);

  final CreateGroupBottomSheetController controller;
  final Function() cancelCallback;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: controller.currentPage == 1
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: firstPage(context),
          secondChild: secondPage(context),
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
        ),
      ),
    );
  }

  Widget firstPage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Container(
        color: surfaceBrightColor,
        height: MediaQuery.of(context).size.height * 0.94,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomLeadingIcon(
                    buttonOnPressed: cancelCallback,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          localized(createNewGroup),
                          style: jxTextStyle.appTitleStyle(
                              color: JXColors.primaryTextBlack),
                        ),
                        Text(
                          '${controller.selectedMembers.length}/200',
                          style: jxTextStyle.textStyle12( color: JXColors.secondaryTextBlack).copyWith(height: 1.0),
                        )
                      ],
                    ),
                  ),
                  Obx(
                    () => GestureDetector(
                      onTap: () {
                        if (controller.selectedMembers.length > 0) {
                          controller.switchPage(2);
                        }
                      },
                      child: OpacityEffect(
                        child: Container(
                          alignment: Alignment.centerRight,
                          width: 70,
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Text(
                            localized(buttonNext),
                            style: jxTextStyle.textStyle17(
                                color: (controller.selectedMembers.length > 0)
                                    ? accentColor
                                    : accentColor.withOpacity(0.2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const CustomDivider(),

            /// Search Bar
            Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 40, maxHeight: 120),
                  padding: const EdgeInsets.only(
                    left: 16,
                  ),
                  child: SingleChildScrollView(
                    controller: controller.selectedMembersController,
                    physics: const ClampingScrollPhysics(),
                    child: Wrap(
                      // spacing: 8,
                      children: [
                        ...List.generate(
                          controller.selectedMembers.length,
                          (index) => GestureDetector(
                            onTap: () {
                              if (controller.highlightMember.value !=
                                  controller.selectedMembers[index].uid) {
                                controller.highlightMember.value =
                                    controller.selectedMembers[index].uid;
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                top: 8,
                                left: 0,
                                right: 8,
                              ),
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Stack(
                                key: ValueKey(
                                  controller.selectedMembers[index].uid,
                                ),
                                children: <Widget>[
                                  Container(
                                    // margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: JXColors.bgTertiaryColor,
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomAvatar(
                                          uid: controller
                                              .selectedMembers[index].uid,
                                          size: 22,
                                          headMin: Config().headMin,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4,
                                              bottom: 4,
                                              left: 4,
                                              right: 8),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 116),
                                            child: NicknameText(
                                              uid: controller
                                                  .selectedMembers[index].uid,
                                              fontSize: MFontSize.size14.value,
                                              overflow: TextOverflow.ellipsis,
                                              isTappable: false,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Obx(
                                    () => Visibility(
                                      visible: controller
                                              .highlightMember.value ==
                                          controller.selectedMembers[index].uid,
                                      child: Positioned(
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 0),
                                          constraints: const BoxConstraints(
                                              maxWidth: 150),
                                          child: GestureDetector(
                                            onTap: () => controller.onSelect(
                                              context,
                                              null,
                                              controller.selectedMembers[index],
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: accentColor,
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 6,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4,
                                                            bottom: 4,
                                                            left: 4,
                                                            right: 8),
                                                    child: Container(
                                                      constraints:
                                                          const BoxConstraints(
                                                              maxWidth: 116),
                                                      child: NicknameText(
                                                        color: Colors.white,
                                                        uid: controller
                                                            .selectedMembers[
                                                                index]
                                                            .uid,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontSize: MFontSize
                                                            .size14.value,
                                                        isTappable: false,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: TextField(
                              contextMenuBuilder: textMenuBar,
                              onTap: () => controller.isSearching(true),
                              controller: controller.searchController,
                              onChanged: controller.onSearchChanged,
                              cursorColor: accentColor,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: localized(whoYouWouldLikeToInvite),
                                hintStyle: jxTextStyle.textStyle14(
                                  color: JXColors.supportingTextBlack,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const CustomDivider(),

            /// Contact List
            Obx(
              () => (controller.azFilterList.length > 0)
                  ? Expanded(
                      child: AzListView(
                        noResultFound: localized(noResultFound),
                        data: controller.azFilterList,
                        itemCount: controller.azFilterList.length,
                        itemBuilder: (context, index) {
                          final item = controller.azFilterList[index];
                          return _buildListItem(context, item);
                        },
                        showIndexBar: controller.isSearching.value ||
                            controller.searchParam.isNotEmpty,
                        indexBarData: controller.filterIndexBar(),
                        indexBarItemHeight: (400 / 28),
                        indexBarHeight:
                            MediaQuery.of(context).size.height * 0.95,
                        indexBarOptions: IndexBarOptions(
                          textStyle: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          localized(noResultFound),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget secondPage(BuildContext context) {
    return Container(
      color: surfaceBrightColor,
      height: MediaQuery.of(context).size.height * 0.94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomLeadingIcon(
                  buttonOnPressed: () {
                    controller.switchPage(1);
                  },
                ),
                Center(
                  child: Text(
                    localized(createNewGroup),
                    style: jxTextStyle.appTitleStyle(
                        color: JXColors.primaryTextBlack),
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onTap: () {
                      if (!controller.groupNameIsEmpty.value) {
                        controller.onCreate(context);
                      }
                    },
                    child: OpacityEffect(
                      child: Container(
                        alignment: Alignment.centerRight,
                        width: 70,
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Text(
                          localized(newGroupCreateButton),
                          style: jxTextStyle.textStyle17(
                              color: !controller.groupNameIsEmpty.value
                                  ? accentColor
                                  : JXColors.primaryTextBlack
                                      .withOpacity(0.2)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomDivider(),
          Expanded(
            child: SingleChildScrollView(
              controller: controller.scrollController,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 36, left: 16, right: 16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        /// 群头像
                        Container(
                          alignment: Alignment.center,
                          child: Obx(
                            () => Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      controller.showPickPhotoOption(context),
                                  child: Container(
                                    margin: const EdgeInsets.all(10),
                                    child: ForegroundOverlayEffect(
                                      overlayColor: JXColors.primaryTextBlack
                                          .withOpacity(0.3),
                                      radius: const BorderRadius.vertical(
                                        top: Radius.circular(100),
                                        bottom: Radius.circular(100),
                                      ),
                                      child: controller.groupPhoto.value == null
                                          ? Container(
                                              width: 66,
                                              height: 66,
                                              padding:
                                                  const EdgeInsets.all(18.0),
                                              decoration: BoxDecoration(
                                                color: accentColor
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/svgs/edit_camera_icon.svg',
                                                colorFilter: ColorFilter.mode(
                                                    accentColor,
                                                    BlendMode.srcIn),
                                              ),
                                            )
                                          : Container(
                                              width: 66,
                                              height: 66,
                                              child: ClipOval(
                                                child: Image.file(
                                                  controller.groupPhoto.value!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            contextMenuBuilder: textMenuBar,
                            onChanged: controller.onGroupNameChanged,
                            controller: controller.groupNameTextController,
                            focusNode: controller.focusNode,
                            maxLength: 30,
                            cursorColor: accentColor,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              hintText: localized(enterGroupName),
                              hintStyle: jxTextStyle.textStyle16(
                                color: JXColors.supportingTextBlack,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: !controller.groupNameIsEmpty.value,
                          child: IconButton(
                            onPressed: () {
                              controller.groupNameTextController.clear();
                              controller.groupNameIsEmpty.value = true;
                            },
                            icon: SvgPicture.asset(
                              'assets/svgs/clear_icon.svg',
                              width: 20,
                              height: 20,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 36, left: 16, right: 16),
                    child: Column(
                      children: [
                        ...List.generate(controller.selectedMembers.length,
                            (index) {
                          BorderRadius borderRadius = BorderRadius.zero;

                          if (index == 0) {
                            if (index ==
                                controller.selectedMembers.length - 1) {
                              borderRadius = borderRadius =
                                  const BorderRadius.all(Radius.circular(12));
                            } else {
                              borderRadius = const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(0),
                              );
                            }
                          } else if (index ==
                              controller.selectedMembers.length - 1) {
                            borderRadius = const BorderRadius.only(
                              topLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            );
                          }
                          return Container(
                            key: ValueKey(
                              controller.selectedMembers[index].uid,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: borderRadius,
                              color: Colors.white,
                            ),
                            child: Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                    left: 16,
                                    right: 12,
                                  ),
                                  child: CustomAvatar(
                                    uid: controller.selectedMembers[index].uid,
                                    size: 40,
                                    headMin: Config().headMin,
                                  ),
                                ),
                                //const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                      left: 0,
                                      right: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: (index ==
                                              controller
                                                      .selectedMembers.length -
                                                  1)
                                          ? const Border()
                                          : customBorder,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        NicknameText(
                                          uid: controller
                                              .selectedMembers[index].uid,
                                          fontSize: MFontSize.size16.value,
                                          fontWeight: MFontWeight.bold6.value,
                                          isTappable: false,
                                        ),
                                        Obx(
                                          () => Text(
                                            UserUtils.onlineStatus(controller
                                                .selectedMembers[index]
                                                .lastOnline),
                                            style: jxTextStyle.textStyle12(
                                                color: JXColors
                                                    .secondaryTextBlack),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// create contact card
  Widget _buildListItem(BuildContext context, AZItem item) {
    final tag = item.getSuspensionTag();
    final offstage = !item.isShowSuspension;
    final user = controller.userList
        .where((element) => element.uid == item.user.uid)
        .firstOrNull;
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Offstage(offstage: offstage, child: buildHeader(tag)),
          GestureDetector(
            onTap: () {
              controller.onSelect(
                context,
                null,
                user,
              );
            },
            child: OverlayEffect(
              child: Container(
                child: Row(
                  children: [
                    /// CheckBox
                    Obx(
                      () => Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        child: CheckTickItem(
                          isCheck: controller.selectedMembers.contains(user),
                        ),
                      ),
                    ),

                    /// Contact Info
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          CustomAvatar(
                            key: ValueKey(user?.uid),
                            uid: user!.uid,
                            size: 40,
                            headMin: Config().headMin,
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(
                                // top: 12,
                                // bottom: 12,
                                left: 12,
                                right: 20,
                              ),
                              height: 50,
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                border: offstage
                                    ? const Border(
                                        top: BorderSide(
                                          color: JXColors.borderPrimaryColor,
                                          width: 0.33,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  NicknameText(
                                    key: ValueKey(user.uid),
                                    uid: user.uid,
                                    isTappable: false,
                                    fontSize: MFontSize.size16.value,
                                    fontWeight: MFontWeight.bold6.value,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    UserUtils.onlineStatus(user.lastOnline),
                                    style: jxTextStyle.textStyle12(
                                      color: JXColors.secondaryTextBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) => Container(
        color: surfaceBrightColor,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        alignment: Alignment.centerLeft,
        height: 30,
        child: Text(
          '$tag',
          softWrap: false,
          style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
        ),
      );
}
