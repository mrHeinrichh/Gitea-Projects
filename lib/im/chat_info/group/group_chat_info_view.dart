import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/setting_info/group_chat_encryption_bottom_sheet.dart';
import 'package:jxim_client/im/chat_info/components/file_view.dart';
import 'package:jxim_client/im/chat_info/components/link_view.dart';
import 'package:jxim_client/im/chat_info/components/media_view.dart';
import 'package:jxim_client/im/chat_info/components/member_view.dart';
import 'package:jxim_client/im/chat_info/components/red_packet_transaction_view.dart';
import 'package:jxim_client/im/chat_info/components/task_section.dart';
import 'package:jxim_client/im/chat_info/components/voice_view.dart';
import 'package:jxim_client/im/chat_info/group/chat_info_nickname_text.dart';
import 'package:jxim_client/im/chat_info/group/components/group_info_menu_widget.dart';
import 'package:jxim_client/im/chat_info/group/components/group_info_more_select_widget.dart';
import 'package:jxim_client/im/chat_info/group/components/group_info_tabbar.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/profile_page.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat_info_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar_hero.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:sliver_tools/sliver_tools.dart';

class GroupChatInfoView extends GetView<GroupChatInfoController> {
  GroupChatInfoView({super.key});
  final bool isMobile = objectMgr.loginMgr.isMobile;

  @override
  Widget build(BuildContext context) {
    controller.context = context;

    ///頂部SafeArea不要拿掉,否則上滑置頂後UI在ios會跑掉
    return Container(
      color: colorBackground,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: colorBackground,
          body: Obx(() => AnimatedPadding(
              padding: EdgeInsets.only(top: controller.downOffset.value),
              duration: const Duration(milliseconds: 100),
              child: _body(context)
          )),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value) {
      return BallCircleLoading(
        radius: 10,
        ballStyle: BallStyle(
          size: 4,
          color: themeColor,
          ballType: BallType.solid,
          borderWidth: 5,
          borderColor: themeColor,
        ),
      );
    }
    return isMobile
        ? Obx(() {
      return ProfilePage(
        img: controller.group.value == null
            ? ''
            : objectMgr.myGroupMgr
            .getGroupById(controller.group.value?.id)
            ?.icon,
        server: serversUriMgr.download2Uri?.origin ?? '',
        scrollController: controller.scrollController,
        ableEdit: controller.editEnable.value,
        actions: () async {
          if (controller.editEnable.value) {
            Get.toNamed(
              RouteName.groupChatEdit,
              arguments: {
                'group': controller.group.value,
                'groupMemberListData':
                controller.groupMemberListData,
                'permission':
                controller.group.value!.permission,
              },
            );
          }
        },

        ///显示首字母的头像
        defaultImg: Obx(() {
          return Hero(
            tag: '${controller.group.value?.uid}',
            child: CustomAvatar.group(
              key: ValueKey(controller.group.value!.id),
              controller.group.value!,
              size: 100,
              headMin: Config().headMin,
            ),
          );
        }),
        onClickProfile: () {
          showProfileAvatar(
            controller.group.value?.uid ??
                controller.chat.value!.id,
            controller.group.value?.id ?? 0,
            true,
          );
        },
        name: ChatInfoNicknameText(
          uid:controller.group.value?.uid ?? controller.chat.value!.id,
          chatType: controller.chat.value!.typ,
          size: MFontSize.size17.value,
          showIcon: false,
          showEncrypted: controller.isEncrypted.value,
        ),
        description: UserUtils.groupMembersLengthInfo(
          controller.groupMemberListData.length,
        ),
        body: Obx(() {
          return Container(
            margin: jxDimension.infoViewGridPadding(),
            color: controller.groupTabOptions.isEmpty
                ? ImColor.systemBg
                : Colors.white,
            child: Obx(
                  () => controller.groupTabOptions.isNotEmpty
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
          );
        }),
        stickyTabBar: GroupInfoTabBar(controller: controller),
        features: GroupInfoMenuWidget(controller: controller),
      );
    })
        : Column(
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.only(left: 10),
          decoration: const BoxDecoration(
            color: colorBackground,
            border: Border(
              bottom: BorderSide(
                color: colorBorder,
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
                  onTap: () async {
                    Get.toNamed(
                      RouteName.groupChatEdit,
                      arguments: {
                        'group': controller.group.value,
                        'groupMemberListData':
                        controller.groupMemberListData,
                        'permission':
                        controller.group.value!.permission,
                      },
                      id: 1,
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      localized(buttonEdit),
                      style: TextStyle(
                        color: themeColor,
                        fontSize: MFontSize.size13.value,
                        fontWeight: MFontWeight.bold5.value,
                      ),
                    ),
                  ),
                ),
              ),
              // moreOption,
            ],
          ),
        ),
        Expanded(
          child: NestedScrollView(
            controller: controller.scrollController,
            headerSliverBuilder: (
                BuildContext context,
                bool innerBoxIsScrolled,
                ) {
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
                                surfaceTintColor: colorBorder,
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
                                        controller
                                            .chat.value!.id,
                                    size: 100,
                                    isGroup: true,
                                    showInitial: controller.chat.value!.isDisband,
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
                                        Obx(() => Visibility(
                                          visible: controller.isEncrypted.value,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 4.0),
                                            child: SvgPicture.asset(
                                              'assets/svgs/chatroom_icon_encrypted.svg',
                                              width: 22,
                                              height: 22,
                                            ),
                                          ),
                                        ),),
                                        Expanded(
                                          child: Text(
                                            controller
                                                .group
                                                .value
                                                ?.name ??
                                                controller
                                                    .chat
                                                    .value!
                                                    .name,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight:
                                              MFontWeight
                                                  .bold7
                                                  .value,
                                              color:
                                              colorTextPrimary,
                                            ),
                                            overflow:
                                            TextOverflow
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
                                          .length,
                                    ),
                                    style: jxTextStyle
                                        .textStyle14(
                                      color:
                                      colorTextSecondary,
                                    ),
                                  ),
                                )
                                    : const SizedBox(),
                                const SizedBox(height: 16),

                                /// 4 features
                                GroupInfoMenuWidget(
                                  controller: controller,
                                ),

                                Obx(() => Visibility(
                                  visible: (notBlank(
                                    controller.group.value
                                        ?.profile,
                                  ) || controller.isEncrypted.value) &&
                                      !controller.chat.value!
                                          .isDisband,
                                  child: Card(
                                    margin:
                                    const EdgeInsets.only(
                                      top: 16,
                                      left: 50,
                                      right: 50,
                                    ),
                                    elevation: 0.0,
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                        12.0,
                                      ),
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
                                            color: colorBorder,
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          if (notBlank(controller.group.value?.profile))
                                          Text(
                                            localized(
                                              description,
                                            ),
                                            style: jxTextStyle
                                                .textStyle14(
                                              color:
                                              colorTextSecondary,
                                            ),
                                          ),
                                          if (notBlank(controller.group.value?.profile))
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          if (notBlank(controller.group.value?.profile))
                                          Text(
                                            controller
                                                .group
                                                .value
                                                ?.profile ??
                                                "",
                                            style: jxTextStyle
                                                .textStyle16(),
                                          ),
                                          Visibility(
                                            visible: controller.isEncrypted.value,
                                            child: _buildEncryptionTile(context, hasBorder: (notBlank(controller.group.value?.profile))),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),),
                              ],
                            ),
                          ),
                        ),
                      ),
                      makeHeader(
                        Container(
                          color: colorBackground,
                        ),
                        20,
                      ),
                      makeHeader(
                        Container(
                          key: controller.tabBarKey,
                          color: colorBackground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                          ),
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
                                return controller
                                    .groupTabOptions.isNotEmpty
                                    ? AnimatedCrossFade(
                                  duration:
                                  const Duration(
                                    milliseconds: 200,
                                  ),
                                  firstChild: TabBar(
                                    onTap: controller
                                        .onTabChange,
                                    isScrollable: controller
                                        .setScrollable(),
                                    labelPadding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 8,
                                    ),
                                    indicatorColor:
                                    themeColor,
                                    indicatorSize:
                                    TabBarIndicatorSize
                                        .label,
                                    indicator:
                                    UnderlineTabIndicator(
                                      borderSide:
                                      BorderSide(
                                        width: 2,
                                        color: themeColor,
                                      ),
                                      borderRadius:
                                      const BorderRadius
                                          .only(
                                        topLeft: Radius
                                            .circular(
                                          20,
                                        ),
                                        topRight: Radius
                                            .circular(
                                          20,
                                        ),
                                      ),
                                    ),
                                    unselectedLabelColor:
                                    colorTextSecondary,
                                    unselectedLabelStyle:
                                    jxTextStyle
                                        .textStyle14(),
                                    labelColor:
                                    themeColor,
                                    labelStyle: jxTextStyle
                                        .textStyleBold14(),
                                    controller: controller
                                        .tabController,
                                    tabs: controller
                                        .groupTabOptions
                                        .map(
                                          (e) => Tab(
                                        child: Text(
                                          localized(
                                            e.stringKey,
                                          ),
                                          overflow:
                                          TextOverflow
                                              .ellipsis,
                                        ),
                                      ),
                                    )
                                        .toList(),
                                  ),
                                  secondChild:
                                  GroupInfoMoreSelectWidget(
                                    controller:
                                    controller,
                                  ),
                                  firstCurve: Curves
                                      .easeInOutCubic,
                                  secondCurve: Curves
                                      .easeInOutCubic,
                                  crossFadeState:
                                  controller
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
              padding:
              const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                margin: jxDimension.infoViewGridPadding(),
                constraints: const BoxConstraints(
                  maxWidth: 650,
                  minWidth: 300,
                ),
                height: View.of(context).physicalSize.height,
                color: Colors.white,
                child: Obx(
                      () => controller.groupTabOptions.isNotEmpty
                      ? TabBarView(
                    controller: controller.tabController,
                    physics: controller
                        .onMoreSelect.value ||
                        controller
                            .onAudioPlaying.value
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
          ),
        ),
      ],
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
          color: themeColor,
        ),
        const SizedBox(width: 6),
        Text(
          localized(buttonBack),
          style: TextStyle(
            fontSize: 13,
            color: themeColor,
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
      style: TextStyle(
        fontSize: 13,
        color: themeColor,
      ),
    ),
  );

  Widget _buildEncryptionTile(BuildContext context, {bool hasBorder = true}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            // Get.put(GroupInviteLinkController());
            return const GroupChatEncryptionBottomSheet();
          },
        );
      },
      child: OpacityEffect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasBorder)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  height: 0.33,
                  color: colorTextPrimary.withOpacity(0.2),
                ),
              ),
            //取得簡介文字行數
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localized(settingEncryptedConversation),
                  style: jxTextStyle.textStyle17(),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SvgPicture.asset(
                    'assets/svgs/right_arrow_thick.svg',
                    color: colorTextSupporting,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                        colorTextPrimary.withOpacity(0.2), BlendMode.srcIn),
                  ),
                )
              ],
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
        return MemberView(
          chat: controller.chat.value!,
          groupController: controller,
        );
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
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
