import 'dart:math';

import 'package:agora/agora_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/components/file_view.dart';
import 'package:jxim_client/im/chat_info/components/link_view.dart';
import 'package:jxim_client/im/chat_info/components/media_view.dart';
import 'package:jxim_client/im/chat_info/components/member_view.dart';
import 'package:jxim_client/im/chat_info/components/red_packet_transaction_view.dart';
import 'package:jxim_client/im/chat_info/components/task_section.dart';
import 'package:jxim_client/im/chat_info/components/voice_view.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/profile_page.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat_info_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../../../object/chat/message.dart';
import '../../../utils/utility.dart';
import '../../../views/component/click_effect_button.dart';
import '../../../views/component/custom_avatar_hero.dart';

class GroupChatInfoView extends GetView<GroupChatInfoController> {
  GroupChatInfoView({Key? key}) : super(key: key);
  final bool isMobile = objectMgr.loginMgr.isMobile;

  @override
  Widget build(BuildContext context) {
    controller.context = context;

    ///頂部SafeArea不要拿掉,否則上滑置頂後UI在ios會跑掉
    return Container(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Obx(
            () {
              if (controller.isLoading.value) {
                return BallCircleLoading(
                  radius: 10,
                  ballStyle: BallStyle(
                    size: 4,
                    color: accentColor,
                    ballType: BallType.solid,
                    borderWidth: 5,
                    borderColor: accentColor,
                  ),
                );
              }

              return isMobile
                  ? ProfilePage(
                      img: controller.group.value == null
                          ? ''
                          : objectMgr.myGroupMgr
                              .getGroupById(controller.group.value?.id)
                              ?.icon,
                      server: serversUriMgr.download2Uri?.origin ?? '',
                      scrollController: controller.scrollController,
                      ableEdit: controller.editEnable.value,
                      actions: () {
                        if (controller.editEnable.value) {
                          Get.toNamed(RouteName.groupChatEdit, arguments: {
                            'group': controller.group.value,
                            'groupMemberListData':
                                controller.groupMemberListData,
                            'permission': controller.group.value!.permission
                          });
                        }
                      },

                      ///显示首字母的头像
                      defaultImg: CustomAvatar(
                        uid: controller.group.value?.id ?? 0,
                        size: 100,
                        isGroup: true,
                      ),
                      onClickProfile: () {
                        showProfileAvatar(
                          controller.group.value?.uid ??
                              controller.chat.value!.id,
                          controller.group.value?.id ?? 0,
                          true,
                        );
                      },
                      name: NicknameText(
                        uid: controller.group.value?.uid ??
                            controller.chat.value!.id,
                        isGroup: true,
                        displayName: notBlank(controller.chat.value!.name)
                            ? controller.chat.value!.name
                            : '',
                        fontSize: MFontSize.size17.value,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: MFontWeight.bold6.value,
                        isTappable: false,
                      ),
                      description: UserUtils.groupMembersLengthInfo(
                          controller.groupMemberListData.length),
                      body: Container(
                        margin: jxDimension.infoViewGridPadding(),
                        color: controller.groupTabOptions.length == 0
                            ? ImColor.systemBg
                            : Colors.white,
                        child: Obx(
                          () => controller.groupTabOptions.length > 0
                              ? TabBarView(
                                  controller: controller.tabController,
                                  physics: controller.onMoreSelect.value ||
                                          controller.onAudioPlaying.value
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                                  children: List.generate(
                                    controller.tabController.length,
                                    (index) => tabViews(
                                      context,
                                      controller.groupTabOptions[index],
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ),
                      stickyTabBar: Container(
                        key: controller.tabBarKey,
                        margin: jxDimension.infoViewTabBarPadding(),
                        width: double.infinity,
                        height: 46.0,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: controller.groupTabOptions.length == 0
                              ? ImColor.systemBg
                              : controller.scrollTabColors.value == 0
                                  ? JXColors.bgSecondaryColor
                                  : ImColor.systemBg,
                          // borderRadius: jxDimension.infoViewTabBarBorder(),
                          border: customBorder,
                        ),
                        child: Obx(
                          () {
                            final shouldAlignStart = controller.setScrollable();
                            return AnimatedCrossFade(
                              duration: const Duration(milliseconds: 200),
                              firstChild: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: customBorder,
                                ),
                                child: controller.groupTabOptions.length > 0
                                    ? Container(
                                        alignment: shouldAlignStart
                                            ? Alignment.centerLeft
                                            : null,
                                        child: TabBar(
                                          //只有一個tab去掉左邊多餘offset
                                          // tabAlignment: controller.groupTabOptions.length == 1 || controller.setScrollable()
                                          //     ? TabAlignment.start : null,
                                          onTap: controller.onTabChange,
                                          isScrollable: shouldAlignStart,
                                          indicatorColor: accentColor,
                                          indicatorSize:
                                              TabBarIndicatorSize.label,
                                          indicator: UnderlineTabIndicator(
                                            borderSide: BorderSide(
                                              width: 2.5,
                                              color: accentColor,
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(6),
                                              topRight: Radius.circular(6),
                                            ),
                                          ),
                                          unselectedLabelColor:
                                              JXColors.secondaryTextBlack,
                                          unselectedLabelStyle:
                                              jxTextStyle.textStyle14(),
                                          labelColor: accentColor,
                                          labelPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                          labelStyle:
                                              jxTextStyle.textStyleBold14(),
                                          controller: controller.tabController,
                                          tabs: [
                                            if (controller
                                                    .groupTabOptions.length >
                                                0)
                                              Tab(
                                                text: localized(controller
                                                    .groupTabOptions[0]
                                                    .stringKey),
                                              ),
                                            if (controller
                                                    .groupTabOptions.length >
                                                1)
                                              Tab(
                                                text: localized(controller
                                                    .groupTabOptions[1]
                                                    .stringKey),
                                              ),
                                            if (controller
                                                    .groupTabOptions.length >
                                                2)
                                              Tab(
                                                text: localized(controller
                                                    .groupTabOptions[2]
                                                    .stringKey),
                                              ),
                                            if (controller
                                                    .groupTabOptions.length >
                                                3)
                                              Tab(
                                                text: localized(controller
                                                    .groupTabOptions[3]
                                                    .stringKey),
                                              ),
                                            if (controller
                                                    .groupTabOptions.length >
                                                4)
                                              Tab(
                                                text: localized(controller
                                                    .groupTabOptions[4]
                                                    .stringKey),
                                              ),
                                            if (controller
                                                    .groupTabOptions.length >
                                                5)
                                              Tab(
                                                text: localized(controller
                                                    .groupTabOptions[5]
                                                    .stringKey),
                                              ),
                                            if (controller
                                                    .groupTabOptions.length >
                                                6)
                                              Tab(
                                                text: localized(controller
                                                    .groupTabOptions[6]
                                                    .stringKey),
                                              ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                              secondChild: onMoreSelectWidget(context),
                              firstCurve: Curves.easeInOutCubic,
                              secondCurve: Curves.easeInOutCubic,
                              crossFadeState: controller.onMoreSelect.value
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                            );
                          },
                        ),
                      ),
                      features: Container(
                        key: controller.childKey,
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16.0, bottom: 0),
                              child: Row(
                                children: [
                                  Visibility(
                                    visible: controller.isOwner.value ||
                                        controller.adminList.contains(
                                            objectMgr.userMgr.mainUser.uid),
                                    child: Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (controller.chat.value!.isValid) {
                                            if (objectMgr.callMgr
                                                    .getCurrentState() !=
                                                CallState.Idle) {
                                              Toast.showToast(
                                                  localized(toastEndCall));
                                            } else {
                                              audioManager
                                                  .audioStateBtnClick(context);
                                            }
                                          } else {
                                            Toast.showToast(localized(
                                                youAreNoLongerInThisGroup));
                                          }
                                        },
                                        child: toolButton(
                                          'assets/svgs/chat_info_call_icon.svg',
                                          localized(call),
                                          controller.chat.value!.isValid,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                      visible: controller.isOwner.value ||
                                          controller.adminList.contains(
                                              objectMgr.userMgr.mainUser.uid),
                                      child: ImGap.hGap8),
                                  Expanded(
                                    child: GestureDetector(
                                      key: controller.notificationKey,
                                      onTap: () =>
                                          controller.onNotificationTap(context),
                                      child: toolButton(
                                        controller.isMute.value
                                            ? 'assets/svgs/chat_info_unmute.svg'
                                            : 'assets/svgs/chat_info_mute.svg',
                                        controller.isMute.value
                                            ? localized(cancelUnmute)
                                            : localized(mute),
                                        controller.chat.value!.isValid,
                                      ),
                                    ),
                                  ),
                                  ImGap.hGap8,
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!controller.chat.value!.isDisband) {
                                          controller.onChatTap(
                                            context,
                                            searching: true,
                                          );
                                        }
                                      },
                                      child: toolButton(
                                        'assets/svgs/chat_info_search.svg',
                                        localized(search),
                                        !controller.chat.value!.isDisband,
                                      ),
                                    ),
                                  ),
                                  ImGap.hGap8,
                                  Expanded(
                                    child: GestureDetector(
                                      key: controller.moreVertKey,
                                      onTap: () => controller
                                          .showMoreOptionPopup(context),
                                      child: toolButton(
                                        'assets/svgs/chat_info_more.svg',
                                        localized(searchMore),
                                        true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible:
                                  notBlank(controller.group.value?.profile),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ).w,
                                margin:
                                    const EdgeInsets.fromLTRB(0, 24, 0, 0).w,
                                decoration: BoxDecoration(
                                  color: JXColors.bgSecondaryColor,
                                  borderRadius: BorderRadius.circular(12.w),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localized(description),
                                      style: jxTextStyle.textStyle12(
                                        color: JXColors.secondaryTextBlack,
                                      ),
                                    ),
                                    SizedBox(height: 4.w),
                                    //取得簡介文字行數
                                    ///TODO: need to add more text button if text line exceeds 3
                                    GestureDetector(
                                      onTap: () {
                                        controller.updateGroupChatDescExpanded(
                                            !controller
                                                .isGroupChatDescExpanded.value);
                                      },
                                      child: OverlayEffect(
                                        radius: const BorderRadius.vertical(
                                          top: Radius.circular(8),
                                          bottom: Radius.circular(8),
                                        ),
                                        child: LayoutBuilder(
                                            builder: (context, constraints) {
                                          final span = TextSpan(
                                            text: controller
                                                    .group.value?.profile ??
                                                "",
                                            style: jxTextStyle.textStyle17(),
                                          );

                                          final tp = TextPainter(
                                            text: span,
                                            textDirection: TextDirection.ltr,
                                          );
                                          tp.layout(
                                              maxWidth: constraints.maxWidth);

                                          //get text lines
                                          int numLines =
                                              tp.computeLineMetrics().length;
                                          numLines =
                                              numLines < 3 ? numLines : 3;
                                          controller.profileTextNumLines =
                                              numLines;

                                          return Obx(
                                            () => Text(
                                              controller.group.value?.profile ??
                                                  "",
                                              style: jxTextStyle.textStyle17(),
                                              maxLines: controller
                                                      .isGroupChatDescExpanded
                                                      .value
                                                  ? null
                                                  : numLines,
                                              overflow: controller
                                                      .isGroupChatDescExpanded
                                                      .value
                                                  ? TextOverflow.visible
                                                  : TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          height: 52,
                          padding: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: const Border(
                              bottom: BorderSide(
                                color: JXColors.outlineColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            /// 普通界面
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              OpacityEffect(
                                child: GestureDetector(
                                  onTap: () {
                                    controller.exitInfoView();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: backButton,
                                ),
                              ),
                              Text(localized(groupProfile)),
                              OpacityEffect(
                                child: GestureDetector(
                                  onTap: () {
                                    Get.toNamed(RouteName.groupChatEdit,
                                        arguments: {
                                          'group': controller.group.value,
                                          'groupMemberListData':
                                              controller.groupMemberListData,
                                          'permission':
                                              controller.group.value!.permission
                                        },
                                        id: 1);
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      localized(buttonEdit),
                                      style: TextStyle(
                                        color: JXColors.blue,
                                        fontSize: MFontSize.size13.value,
                                        fontWeight: MFontWeight.bold5.value,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              // moreOption,
                            ],
                          ),
                        ),
                        Expanded(
                            child: NestedScrollView(
                          controller: controller.scrollController,
                          headerSliverBuilder:
                              (BuildContext context, bool innerBoxIsScrolled) {
                            return [
                              SliverOverlapAbsorber(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                                sliver: MultiSliver(
                                  pushPinnedChildren: true,
                                  children: [
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 40.0),
                                        child: ElevatedButtonTheme(
                                          data: ElevatedButtonThemeData(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  Colors.white,
                                              shadowColor: Colors.transparent,
                                              surfaceTintColor:
                                                  JXColors.outlineColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              elevation: 0.0,
                                            ),
                                          ),
                                          child: Column(
                                            children: <Widget>[
                                              /// 头像
                                              Obx(
                                                () => CustomAvatarHero(
                                                  id: controller
                                                          .group.value?.id ??
                                                      controller.chat.value!.id,
                                                  size: 100,
                                                  isGroup: true,
                                                  showInitial: controller
                                                      .chat.value!.isDisband,
                                                ),
                                              ),
                                              const SizedBox(height: 12),

                                              /// 群组名字
                                              DesktopGeneralButton(
                                                onPressed: () {},
                                                child: IntrinsicWidth(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          controller.group.value
                                                                  ?.name ??
                                                              controller.chat
                                                                  .value!.name,
                                                          style: TextStyle(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                MFontWeight
                                                                    .bold7
                                                                    .value,
                                                            color: JXColors
                                                                .primaryTextBlack,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              /// 群组人数
                                              controller.chat.value!.isValid
                                                  ? Obx(
                                                      () => Text(
                                                        UserUtils
                                                            .groupMembersLengthInfo(
                                                                controller
                                                                    .groupMemberListData
                                                                    .length),
                                                        style: jxTextStyle
                                                            .textStyle14(
                                                                color: JXColors
                                                                    .secondaryTextBlack),
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                              const SizedBox(height: 16),

                                              /// 4 features
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 100,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      color: JXColors
                                                          .bgSecondaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          controller.onChatTap(
                                                              context),
                                                      child: toolButton(
                                                          'assets/svgs/message.svg',
                                                          localized(homeChat),
                                                          true),
                                                    ),
                                                  ),
                                                  // Expanded(
                                                  //   child: GestureDetector(
                                                  //     onTap: () {
                                                  //       audioManager
                                                  //           .audioStateBtnClick(context);
                                                  //     },
                                                  //     child: toolButton(
                                                  //         'assets/svgs/call.svg',
                                                  //         localized(call),
                                                  //         controller.chat.value!.isValid),
                                                  //   ),
                                                  // ),
                                                  const SizedBox(width: 10),
                                                  Obx(
                                                    () => Container(
                                                      width: 100,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        color: JXColors
                                                            .bgSecondaryColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: ElevatedButton(
                                                        key: controller
                                                            .notificationKey,
                                                        onPressed: () => controller
                                                            .onNotificationTap(
                                                                context),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: toolButton(
                                                            controller.isMute
                                                                    .value
                                                                ? 'assets/svgs/chat_info_unmute.svg'
                                                                : 'assets/svgs/chat_info_mute.svg',
                                                            controller.isMute
                                                                    .value
                                                                ? localized(
                                                                    unmute)
                                                                : localized(
                                                                    mute),
                                                            controller.chat
                                                                .value!.isValid,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    width: 100,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      color: JXColors
                                                          .bgSecondaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          8.0,
                                                                      horizontal:
                                                                          0.0)),
                                                      onPressed: () {
                                                        if (!controller.chat
                                                            .value!.isDisband) {
                                                          controller.onChatTap(
                                                            context,
                                                            searching: true,
                                                          );
                                                        }
                                                      },
                                                      child: toolButton(
                                                        'assets/svgs/Search.svg',
                                                        localized(search),
                                                        !controller.chat.value!
                                                            .isDisband,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    width: 100,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      color: JXColors
                                                          .bgSecondaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: ElevatedButton(
                                                      key: controller
                                                          .moreVertKey,
                                                      onPressed: () => controller
                                                          .showMoreOptionPopup(
                                                              context),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: toolButton(
                                                          'assets/svgs/chat_info_more.svg',
                                                          localized(searchMore),
                                                          true,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              Visibility(
                                                visible: notBlank(controller
                                                        .group
                                                        .value
                                                        ?.profile) &&
                                                    !controller
                                                        .chat.value!.isDisband,
                                                child: Card(
                                                  margin: const EdgeInsets.only(
                                                      top: 16,
                                                      left: 50,
                                                      right: 50),
                                                  elevation: 0.0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                  ),
                                                  color: Colors.white,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 12,
                                                      bottom: 12,
                                                      left: 16,
                                                      right: 16,
                                                    ),
                                                    decoration:
                                                        const BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: JXColors
                                                              .outlineColor,
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          localized(
                                                              description),
                                                          style: jxTextStyle
                                                              .textStyle14(
                                                                  color: JXColors
                                                                      .secondaryTextBlack),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          controller.group.value
                                                                  ?.profile ??
                                                              "",
                                                          style: jxTextStyle
                                                              .textStyle16(),
                                                        )
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
                                    makeHeader(
                                        Container(
                                          color: backgroundColor,
                                        ),
                                        20),
                                    makeHeader(
                                      Container(
                                        key: controller.tabBarKey,
                                        color: backgroundColor,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 650,
                                            minWidth: 300,
                                          ),
                                          margin: jxDimension
                                              .infoViewTabBarPadding(),
                                          // width: double.infinity
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: jxDimension
                                                .infoViewTabBarBorder(),
                                          ),
                                          child: Obx(
                                            () {
                                              return controller.groupTabOptions
                                                          .length >
                                                      0
                                                  ? AnimatedCrossFade(
                                                      duration: const Duration(
                                                          milliseconds: 200),
                                                      firstChild: TabBar(
                                                        onTap: controller
                                                            .onTabChange,
                                                        isScrollable: controller
                                                            .setScrollable(),
                                                        labelPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8),
                                                        indicatorColor:
                                                            accentColor,
                                                        indicatorSize:
                                                            TabBarIndicatorSize
                                                                .label,
                                                        indicator:
                                                            UnderlineTabIndicator(
                                                          borderSide:
                                                              BorderSide(
                                                            width: 2,
                                                            color: accentColor,
                                                          ),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    20),
                                                            topRight:
                                                                Radius.circular(
                                                                    20),
                                                          ),
                                                        ),
                                                        unselectedLabelColor:
                                                            JXColors
                                                                .secondaryTextBlack,
                                                        unselectedLabelStyle:
                                                            jxTextStyle
                                                                .textStyle14(),
                                                        labelColor: accentColor,
                                                        labelStyle: jxTextStyle
                                                            .textStyleBold14(),
                                                        controller: controller
                                                            .tabController,
                                                        tabs:
                                                            controller
                                                                .groupTabOptions
                                                                .map(
                                                                  (e) => Tab(
                                                                    child: Text(
                                                                      localized(
                                                                          e.stringKey),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                      ),
                                                      secondChild:
                                                          onMoreSelectWidget(
                                                              context),
                                                      firstCurve:
                                                          Curves.easeInOutCubic,
                                                      secondCurve:
                                                          Curves.easeInOutCubic,
                                                      crossFadeState: controller
                                                              .onMoreSelect
                                                              .value
                                                          ? CrossFadeState
                                                              .showSecond
                                                          : CrossFadeState
                                                              .showFirst,
                                                    )
                                                  : const SizedBox();
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          },
                          body: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              margin: jxDimension.infoViewGridPadding(),
                              constraints: const BoxConstraints(
                                maxWidth: 650,
                                minWidth: 300,
                              ),
                              height: View.of(context).physicalSize.height,
                              color: Colors.white,
                              child: Obx(
                                () => controller.groupTabOptions.length > 0
                                    ? TabBarView(
                                        controller: controller.tabController,
                                        physics: controller
                                                    .onMoreSelect.value ||
                                                controller.onAudioPlaying.value
                                            ? const NeverScrollableScrollPhysics()
                                            : null,
                                        children: List.generate(
                                          controller.tabController.length,
                                          (index) => tabViews(
                                            context,
                                            controller.groupTabOptions[index],
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                            ),
                          ),
                        )),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  final Widget backButton = Container(
    alignment: Alignment.center,
    child: Row(
      children: [
        SvgPicture.asset(
          'assets/svgs/Back.svg',
          width: 18,
          height: 18,
          color: JXColors.blue,
        ),
        const SizedBox(width: 6),
        Text(
          localized(buttonBack),
          style: const TextStyle(
            fontSize: 13,
            color: JXColors.blue,
          ),
        ),
      ],
    ),
  );

  final Widget moreOption = Container(
    padding: const EdgeInsets.only(right: 20),
    alignment: Alignment.center,
    child: Text(
      localized(buttonEdit),
      style: const TextStyle(
        fontSize: 13,
        color: JXColors.blue,
      ),
    ),
  );

  /// 多功能选项按钮
  Widget toolButton(
    String imageUrl,
    String text,
    bool enableState,
  ) {
    return ForegroundOverlayEffect(
      radius: const BorderRadius.vertical(
        top: Radius.circular(12),
        bottom: Radius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        width: MediaQuery.of(Get.context!).size.width,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              imageUrl,
              width: objectMgr.loginMgr.isDesktop ? 22 : 22.w,
              height: objectMgr.loginMgr.isDesktop ? 22 : 22.w,
              color: enableState
                  ? controller.isMuteOpen.value || controller.isMoreOpen.value
                      ? accentColor.withOpacity(0.3)
                      : accentColor
                  : accentColor.withOpacity(0.3),
            ),
            SizedBox(height: objectMgr.loginMgr.isDesktop ? 2 : 2.w),
            Text(
              text,
              style: jxTextStyle.textStyle12(
                color: enableState
                    ? controller.isMuteOpen.value || controller.isMoreOpen.value
                        ? accentColor.withOpacity(0.3)
                        : accentColor
                    : accentColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// body展示 widget
  Widget tabViews(BuildContext context, ChatInfoModel tabOption) {
    switch (tabOption.tabType) {
      case 'member':
        return MemberView(groupController: controller);
      case 'media':
        return MediaView(chat: controller.chat.value!, isGroup: true);
      case 'file':
        return FileView(chat: controller.chat.value!, isGroup: true);
      case 'audio':
        return VoiceView(chat: controller.chat.value!, isGroup: true);
      case 'link':
        return LinkView(chat: controller.chat.value!, isGroup: true);
      case 'redPacket':
        return RedPacketTransactionView(chat: controller.chat.value!);
      case 'tasks':
        return TaskSection(isGroup: true, chat: controller.chat.value);
      default:
        return Container();
    }
  }

  Widget onMoreSelectWidget(BuildContext context) {
    final key = GlobalKey();
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          border: customBorder,
        ),
        child: Row(
          children: <Widget>[
            GestureDetector(
              onTap: controller.onMoreCancel,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 13.0,
                  horizontal: 20,
                ),
                child: Icon(
                  Icons.close,
                  color: accentColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                controller.selectedMessageList.length.toString(),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
            ),
            if (controller.selectedMessageList.length == 1)
              GestureDetector(
                onTap: () {
                  dynamic msg = controller.selectedMessageList.first;
                  if (msg is Message) {
                    controller.onMoreSelectCallback!(msg);
                  } else if (msg is AlbumDetailBean) {
                    controller.onMoreSelectCallback!(msg.currentMessage);
                  } else {
                    throw "不知道的类型数据";
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13.0,
                    horizontal: 12,
                  ),
                  child: Icon(
                    Icons.image_search_outlined,
                    color: accentColor,
                    size: 24,
                  ),
                ),
              ),
            if (controller.currentTabIndex != 3 &&
                controller.currentTabIndex != 4 &&
                controller.currentTabIndex != 5)
              Obx(() {
                return Visibility(
                  visible: controller.forwardEnable.value,
                  child: GestureDetector(
                    onTap: () => controller.onForwardMessage(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 13.0,
                        horizontal: 12,
                      ),
                      child: Icon(
                        CupertinoIcons.arrowshape_turn_up_right,
                        color: accentColor,
                        size: 24,
                        weight: 10,
                      ),
                    ),
                  ),
                );
              }),
            if (controller.currentTabIndex != 3)
              GestureDetector(
                key: key,
                onTap: () => controller.onDeleteMessage(context, key),
                child: const Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13.0,
                    horizontal: 12,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: JXColors.red,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

SliverPersistentHeader makeHeader(Widget header, [double? height]) {
  return SliverPersistentHeader(
    pinned: true,
    delegate: _SliverAppBarDelegate(
      minHeight: height ?? 50.0,
      maxHeight: height ?? 50.0,
      child: header,
    ),
  );
}
