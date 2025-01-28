import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/search_overlay.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';

class CreateGroupBottomSheet extends StatelessWidget {
  const CreateGroupBottomSheet({
    super.key,
    required this.controller,
    required this.cancelCallback,
  });

  final CreateGroupBottomSheetController controller;
  final Function() cancelCallback;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: controller.currentPage.value == 1
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
        color: colorBackground,
        height: MediaQuery.of(context).size.height * 0.94,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                          localized(controller.groupType.value == GroupType.TMP
                              ? newTemporaryGroup
                              : createNewGroup),
                          style: jxTextStyle.appTitleStyle(),
                        ),
                        Text(
                          '${controller.selectedMembers.length}/200',
                          style: jxTextStyle
                              .normalSmallText(color: colorTextSecondary)
                              .copyWith(height: 1.0),
                        )
                      ],
                    ),
                  ),
                  Obx(
                    () => GestureDetector(
                      onTap: () {
                        if (controller.selectedMembers.isNotEmpty) {
                          controller.switchPage(2);
                        }
                      },
                      child: OpacityEffect(
                        child: Container(
                          alignment: Alignment.centerRight,
                          width: 70,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Text(
                            localized(buttonNext),
                            style: jxTextStyle.headerText(
                                color: (controller.selectedMembers.isNotEmpty)
                                    ? themeColor
                                    : colorTextPlaceholder),
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
            Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
              padding: const EdgeInsets.only(left: 16),
              child: SingleChildScrollView(
                controller: controller.selectedMembersController,
                physics: const ClampingScrollPhysics(),
                child: Obx(() {
                  return Wrap(
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
                            margin: const EdgeInsets.only(top: 8, right: 8),
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Stack(
                              key: ValueKey(
                                controller.selectedMembers[index].uid,
                              ),
                              children: <Widget>[
                                Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colorBackground6,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 1),
                                        child: CustomAvatar.user(
                                          controller.selectedMembers[index],
                                          size: 22,
                                          headMin: Config().headMin,
                                        ),
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
                                    visible: controller.highlightMember.value ==
                                        controller.selectedMembers[index].uid,
                                    child: Positioned(
                                      child: Container(
                                        height: 24,
                                        constraints:
                                            const BoxConstraints(maxWidth: 150),
                                        decoration: BoxDecoration(
                                          color: themeColor,
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                        ),
                                        child: GestureDetector(
                                          onTap: () => controller.onSelect(
                                            context,
                                            null,
                                            controller.selectedMembers[index],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 7,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: colorSurface,
                                                  size: 16,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4,
                                                    bottom: 4,
                                                    left: 4,
                                                    right: 8),
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 116),
                                                  child: NicknameText(
                                                    color: colorBrightPrimary,
                                                    uid: controller
                                                        .selectedMembers[index]
                                                        .uid,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontSize:
                                                        MFontSize.size14.value,
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      IntrinsicWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: TextField(
                            contextMenuBuilder: im.textMenuBar,
                            onTap: () {
                              controller.isSearching(true);
                              if (controller.searchParam.value == '') {
                                controller.showSearchOverlay.value = true;
                              }
                            },
                            controller: controller.searchController,
                            onChanged: controller.onSearchChanged,
                            cursorColor: themeColor,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: localized(whoYouWouldLikeToInvite),
                              hintStyle: jxTextStyle.normalText(
                                color: colorTextSupporting,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const CustomDivider(),

            /// Contact List
            Obx(
              () => (controller.azFilterList.isNotEmpty)
                  ? Expanded(
                      child: Stack(
                        children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification notification) {
                              if (notification is ScrollStartNotification) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              }
                              return false;
                            },
                            child: AzListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
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
                                textStyle: jxTextStyle.tinyText(
                                  color: themeColor,
                                  fontWeight: MFontWeight.bold5.value,
                                ),
                              ),
                            ),
                          ),

                          /// search overlay
                          Obx(() {
                            return SearchOverlay(
                              isVisible: controller.showSearchOverlay.value,
                              onTapCallback: () {
                                controller.isSearching.value = false;
                                controller.showSearchOverlay.value = false;
                              },
                            );
                          }),
                        ],
                      ),
                    )
                  : Center(
                      child: SearchEmptyState(
                        searchText: controller.searchController.text,
                        emptyMessage: localized(
                          oppsNoResultFoundTryNewSearch,
                          params: [(controller.searchController.text)],
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
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Container(
        color: colorBackground,
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
                      style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
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
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Text(
                            localized(newGroupCreateButton),
                            style: jxTextStyle.textStyle17(
                                color: !controller.groupNameIsEmpty.value
                                    ? themeColor
                                    : colorTextPrimary.withOpacity(0.2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller.scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin:
                          const EdgeInsets.only(top: 24, left: 16, right: 16),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        color: colorSurface,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              /// 群头像
                              Container(
                                alignment: Alignment.center,
                                child: Obx(
                                  () => Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      GestureDetector(
                                        onTap: () => controller
                                            .showPickPhotoOption(context),
                                        child: Container(
                                          margin: const EdgeInsets.fromLTRB(
                                              16, 12, 0, 12),
                                          child: OpacityEffect(
                                            opacity: 0.4,
                                            child: controller
                                                        .groupPhoto.value ==
                                                    null
                                                ? Container(
                                                    width: 60,
                                                    height: 60,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            18),
                                                    decoration: BoxDecoration(
                                                      color: themeColor
                                                          .withOpacity(0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                    ),
                                                    child: SvgPicture.asset(
                                                      'assets/svgs/edit_camera_icon.svg',
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                              themeColor,
                                                              BlendMode.srcIn),
                                                    ),
                                                  )
                                                : SizedBox(
                                                    width: 60,
                                                    height: 60,
                                                    child: ClipOval(
                                                      child: Image.file(
                                                        controller
                                                            .groupPhoto.value!,
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
                                  contextMenuBuilder: im.textMenuBar,
                                  onChanged: controller.onGroupNameChanged,
                                  controller:
                                      controller.groupNameTextController,
                                  focusNode: controller.focusNode,
                                  maxLength: 30,
                                  cursorColor: themeColor,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintText: localized(enterGroupName),
                                    hintStyle: jxTextStyle.titleSmallText(
                                      color: colorTextSupporting,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: jxTextStyle.titleSmallText(),
                                ),
                              ),
                              Visibility(
                                visible: !controller.groupNameIsEmpty.value,
                                child: OpacityEffect(
                                  child: IconButton(
                                    onPressed: () {
                                      controller.groupNameTextController
                                          .clear();
                                      controller.groupNameIsEmpty.value = true;
                                    },
                                    icon: SvgPicture.asset(
                                      'assets/svgs/clear_icon.svg',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.fill,
                                      color: colorTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Obx(
                            () => Visibility(
                              visible:
                                  controller.groupType.value == GroupType.TMP,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () =>
                                    controller.showExpiredTimePopup(context),
                                child: OverlayEffect(
                                  radius: const BorderRadius.vertical(
                                      bottom: Radius.circular(12)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: colorDivider,
                                          width: 0.3,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            localized(groupExpiry),
                                            style: jxTextStyle.headerText(),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Obx(
                                              () => Text(
                                                controller.expiryTimeText.value,
                                                style: jxTextStyle.headerText(
                                                    color: colorTextSecondary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SvgPicture.asset(
                                              'assets/svgs/right_arrow_thick.svg',
                                              width: 16,
                                              height: 16,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                      colorTextSecondary,
                                                      BlendMode.srcIn),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.groupType.value == GroupType.TMP,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, left: 32, right: 32),
                          child: Text(
                            localized(
                                theTemporaryGroupWillBeAutomaticallyDisbanded,
                                params: ['23:59:59']),
                            style: jxTextStyle.normalSmallText(
                                color: colorTextLevelTwo),
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => Container(
                        margin:
                            const EdgeInsets.only(top: 32, left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  color: colorSurface,
                                ),
                                child: Column(
                                  children: [
                                    SettingItem(
                                      titleWidget: Text(
                                        localized(settingTempGroup),
                                        style: jxTextStyle.headerText(),
                                      ),
                                      rightWidget: CustomCupertinoSwitch(
                                        value: controller.groupType.value ==
                                            GroupType.TMP,
                                        callBack: (value) {
                                          controller.toggleTMP();
                                        },
                                      ),
                                      withArrow: false,
                                      withBorder:
                                          controller.showEncryptionButton.value,
                                      withEffect: false,
                                    ),
                                    if (controller.showEncryptionButton.value)
                                      SettingItem(
                                        titleWidget: Text(
                                          localized(
                                              settingEncryptedConversation),
                                          style: TextStyle(
                                              fontSize: MFontSize.size16.value),
                                        ),
                                        rightWidget: CustomCupertinoSwitch(
                                          value: controller
                                              .encryptionSetting.value,
                                          callBack: (value) {
                                            controller
                                                .toggleEncryption(context);
                                          },
                                        ),
                                        withBorder: false,
                                        withArrow: false,
                                        withEffect: false,
                                      ),
                                  ],
                                )),
                            if (controller.showEncryptionButton.value)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, top: 8),
                                child: Text(
                                  localized(settingEncryptionTips),
                                  style: jxTextStyle.normalSmallText(
                                      color: colorTextLevelTwo),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 32, left: 16, right: 16, bottom: 16),
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
                                    child: CustomAvatar.user(
                                      controller.selectedMembers[index],
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
                                                controller.selectedMembers
                                                        .length -
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
                                            fontSize: MFontSize.size17.value,
                                            fontWeight: MFontWeight.bold6.value,
                                            isTappable: false,
                                          ),
                                          Visibility(
                                            visible: UserUtils.onlineStatus(
                                                    controller
                                                        .selectedMembers[index]
                                                        .lastOnline) !=
                                                '',
                                            child: Obx(
                                              () => Text(
                                                UserUtils.onlineStatus(
                                                    controller
                                                        .selectedMembers[index]
                                                        .lastOnline),
                                                style:
                                                    jxTextStyle.normalSmallText(
                                                        color:
                                                            colorTextSecondary),
                                              ),
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
                        if (user != null)
                          CustomAvatar.user(
                            key: ValueKey(user.uid),
                            user,
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
                                  ? Border(
                                      top: BorderSide(
                                        color:
                                            colorTextPrimary.withOpacity(0.2),
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
                                  key: ValueKey(user!.uid),
                                  uid: user.uid,
                                  isTappable: false,
                                  fontSize: MFontSize.size17.value,
                                  fontWeight: MFontWeight.bold5.value,
                                ),
                                Visibility(
                                  visible:
                                      UserUtils.onlineStatus(user.lastOnline) !=
                                          '',
                                  child: Text(
                                    UserUtils.onlineStatus(user.lastOnline),
                                    style: jxTextStyle.normalSmallText(
                                      color: colorTextSecondary,
                                    ),
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
        ],
      ),
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) => Container(
        color: colorBackground,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        alignment: Alignment.centerLeft,
        height: 30,
        child: Text(
          tag,
          softWrap: false,
          style: jxTextStyle.textStyle14(color: colorTextSecondary),
        ),
      );
}
