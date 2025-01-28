import 'dart:math';

import 'package:agora/agora_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/components/detail_view.dart';
import 'package:jxim_client/im/chat_info/components/file_view.dart';
import 'package:jxim_client/im/chat_info/components/game_view.dart';
import 'package:jxim_client/im/chat_info/components/link_view.dart';
import 'package:jxim_client/im/chat_info/components/media_view.dart';
import 'package:jxim_client/im/chat_info/components/red_packet_transaction_view.dart';
import 'package:jxim_client/im/chat_info/components/voice_view.dart';
import 'package:jxim_client/im/chat_info/group/game_profile_page.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat_info_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_text.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import '../../../home/setting/setting_item.dart';
import '../../../network/servers_uri_mgr.dart';
import '../../../object/chat/message.dart';
import '../../../utils/im_toast/im_gap.dart';
import '../../../utils/user_utils.dart';
import '../../../views/component/click_effect_button.dart';
import '../../../views/component/custom_avatar.dart';
import '../../../views/component/custom_avatar_hero.dart';
import '../more_vert/more_vert_controller.dart';
import 'group_play_setting_view.dart';

class GroupChatGameInfoView extends GetView<GroupChatInfoController> {
  GroupChatGameInfoView({Key? key}) : super(key: key);

  final bool isDesktop = objectMgr.loginMgr.isDesktop;
  final bool isMobile = objectMgr.loginMgr.isMobile;
  late final onlineCount = controller.groupMemberListData
      .map((user) => FormatTime.isOnline(user.lastOnline) ? 1 : 0)
      .reduce((value, element) => value + element);
  final moreVertController = Get.find<MoreVertController>();
  final closeTip = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    controller.context = context;
    controller.isGroupCertified.value = common.SharedDataManager.shared.isCertified;
    controller.checkCollect();
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
              int len =  controller.groupTabOptions.length;
              final membersCount = controller.groupMemberListData.length;
              final description = controller.isGroupCertified.value?
              '$membersCount位成员，$onlineCount在线':UserUtils.groupMembersLengthInfo(membersCount);
              return isMobile
                  ? GameProfilePage(
                    isShowTab: len>0,
                    // description: description,
                isGroupCertified: controller.isGroupCertified.value,
                      membersCount: controller.groupMemberListData.length,
                      onlineCount: onlineCount,
                      img: controller.group.value == null
                          ? ''
                          : objectMgr.myGroupMgr
                              .getGroupById(controller.group.value?.id)
                              ?.icon,
                      server: serversUriMgr.download2Uri?.origin??"",
                      scrollController: controller.scrollController,
                      ableEdit: common.sharedDataManager.isOwnerAdmin,
                      actions: () {
                        if (common.sharedDataManager.isOwnerAdmin) {
                          Get.toNamed(RouteName.groupChatEdit, arguments: {
                            'group': controller.group.value,
                            'groupMemberListData':
                                controller.groupMemberListData,
                            'permission': controller.group.value!.permission
                          });
                        }
                      },

                      ///显示首字母的头像
                      defaultImg: CustomAvatarHero(
                        id: controller.group.value?.id ?? 0,
                        chat: controller.chat.value,
                        size: 100,
                        isGroup: true,
                        showAutoDeleteIcon: false,
                      ),
                      name: NicknameText(
                        uid: controller.group.value?.uid ??
                            controller.chat.value!.id,
                        isGroup: true,
                        displayName: notBlank(controller.chat.value!.name)
                            ? controller.chat.value!.name
                            : '',
                        fontSize: MFontSize.size20.value,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                        isTappable: false,
                      ),

                      features: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButtonTheme(
                            data: ElevatedButtonThemeData(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ImColor.white,
                                disabledBackgroundColor: ImColor.white,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: JXColors.outlineColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0.0,
                              ),
                            ),
                            child: Container(
                              key: controller.childKey,
                              child: Row(
                                children: [
                                  Visibility(
                                    visible: controller.isOwner.value ||
                                    controller.adminList.contains(
                                    objectMgr.userMgr.mainUser.uid),
                                    child: Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0,
                                                horizontal: 0.0)),
                                        onPressed: () {
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
                                 if(controller.isOwner.value ||
                                     controller.adminList.contains(
                                         objectMgr.userMgr.mainUser.uid)) ImGap.hGap8,
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 0.0)),
                                      key: controller.notificationKey,
                                      onPressed: () => controller
                                          .onNotificationTap(context),
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
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 0.0)),
                                      onPressed: () {
                                        if (controller.isCollect.value) {
                                          controller.unCollectGroup();
                                        }else{
                                          controller.collectGroup();
                                        }
                                      },
                                      child: toolButton(
                                        'assets/svgs/chat_info_favorite_icon.svg',
                                        controller.isCollect.value
                                            ? localized(collected)
                                            : localized(shareCollection),
                                        !controller.chat.value!.isDisband,
                                      ),
                                    ),
                                  ),
                                  ImGap.hGap8,
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 0.0)),
                                      onPressed: () {
                                        if (!controller
                                            .chat.value!.isDisband) {
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
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 0.0)),
                                      key: controller.moreVertKey,
                                      onPressed: () => controller
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
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).w,
                            margin: const EdgeInsets.symmetric(vertical: 24).w,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: ImColor.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ImText(
                                  localized(groupDescription),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.96,
                                ),
                                Obx(() => controller.group.value?.profile !=
                                        ""
                                    ? MarkdownParse(
                                        data:
                                            controller.group.value!.profile,
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        onTapLink: (String text,
                                            String? href, String title) {
                                          print("$text $href");
                                          if (text.startsWith("@")) {
                                            //代表是at
                                            goToMemberPageByUserName(
                                                href ?? "");
                                          } else {
                                            //代表是網頁
                                            Get.toNamed(
                                                RouteName.groupManagement,
                                                arguments: {
                                                  'url': href,
                                                });
                                          }
                                        },
                                        onTapMention:
                                            (String name, String match) {
                                          print("$name $match");
                                          goToMemberPageByUserName(
                                              match ?? "");
                                        },
                                      )
                                    : ImText(
                                        notBlank(controller
                                                .group.value?.profile)
                                            ? '${controller.group.value?.profile}'
                                            : localized(
                                                groupNoDescriptionAvailable),
                                        fontWeight: FontWeight.w400,
                                        color: notBlank(controller
                                                .group.value?.profile)
                                            ? ImColor.black
                                            : ImColor.grey52,
                                        maxLines: 10,
                                      ))
                              ],
                            ),
                          ),
                          if(controller.isGroupCertified.value)
                          ...(common.sharedDataManager.isGroupPermission || controller.isOwner.value||common.sharedDataManager.isCurrentUserShareholder)?
                          [
                            // _buildGroupTutorial(),
                            _buildGroupFunction()
                          ]:
                          [Padding(
                            padding: const EdgeInsets.only(bottom: 24).w,
                            child: GestureDetector(
                              onTap: () {
                                if (!objectMgr.loginMgr.isLogin) return;
                                imMiniAppManager.goToPromotionCenterPage(context);
                              },
                              child: Image.asset(
                                'assets/images/game_banner.png',
                                width: double.infinity,
                                height: 120.h,
                                fit: BoxFit.fill,
                              ),
                            ),
                          )],
                          if(!controller.isGroupCertified.value && controller.isOwner.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24).w,
                            child: Container(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: () {
                                   controller.gotoGroupOfficialPage(context);
                                },
                                child: Image.asset(
                                  'assets/images/group_owner_banner.png',
                                  width: double.infinity,
                                  height: 80.h,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),

                      body: Container(
                        margin: jxDimension.infoViewGridPadding(),
                        color: Colors.white,
                        child: Obx(
                          () {
                            final tabPages = controller.isGroupCertified.value?controller.gameTabController.length:controller.tabController.length;
                            if(tabPages == 0) return const SizedBox();
                            return TabBarView(
                              controller: controller.gameTabController,
                              physics: controller.onMoreSelect.value ||
                                      controller.onAudioPlaying.value
                                  ? const NeverScrollableScrollPhysics()
                                  : null,
                              children: List.generate(
                                tabPages,
                                (index) {
                                  final tab =  controller.isGroupCertified.value?controller.groupGameTabOptions[index]:controller.groupTabOptions[index];
                                  return gameTabViews(context,
                                      tab,
                                      child: index == 0
                                          ? Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.fromLTRB(
                                                      0, 24, 0, 0)
                                                  .w,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ImText(
                                                    localized(groupDescription),
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  SizedBox(height: 8.w),
                                                  Obx(() => controller.group
                                                              .value?.profile !=
                                                          ""
                                                      ? MarkdownParse(
                                                          data: controller.group
                                                              .value!.profile,
                                                          shrinkWrap: true,
                                                          physics:
                                                              const NeverScrollableScrollPhysics(),
                                                          onTapLink: (String
                                                                  text,
                                                              String? href,
                                                              String title) {
                                                            print(
                                                                "$text $href");
                                                            if (text.startsWith(
                                                                "@")) {
                                                              //代表是at
                                                              goToMemberPageByUserName(
                                                                  href ?? "");
                                                            } else {
                                                              //代表是網頁
                                                              Get.toNamed(
                                                                  RouteName
                                                                      .groupManagement,
                                                                  arguments: {
                                                                    'url': href,
                                                                  });
                                                            }
                                                          },
                                                          onTapMention: (String
                                                                  name,
                                                              String match) {
                                                            print(
                                                                "$name $match");
                                                            goToMemberPageByUserName(
                                                                match ?? "");
                                                          },
                                                        )
                                                      : ImText(
                                                          notBlank(controller
                                                                  .group
                                                                  .value
                                                                  ?.profile)
                                                              ? '${controller.group.value?.profile}'
                                                              : localized(
                                                                  groupNoDescriptionAvailable),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: notBlank(
                                                                  controller
                                                                      .group
                                                                      .value
                                                                      ?.profile)
                                                              ? ImColor.black
                                                              : ImColor.grey52,
                                                          maxLines: 10,
                                                        ))
                                                ],
                                              ),
                                            )
                                          : null);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      stickyTabBar: Container(
                        key: controller.tabBarKey,
                        margin: jxDimension.infoViewTabBarPadding(),
                        width: double.infinity,
                        // alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: controller.scrollTabColors.value == 0
                              ? JXColors.bgSecondaryColor
                              : ImColor.systemBg,
                          // borderRadius: jxDimension.infoViewTabBarBorder(),
                          border: customBorder,
                        ),
                        child: Obx(
                          () {
                            final tabPages = controller.isGroupCertified.value?controller.gameTabController.length:controller.tabController.length;
                            return AnimatedCrossFade(
                              duration: const Duration(milliseconds: 200),
                              firstChild: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        width: 0.3, color: ImColor.grey20),
                                  ),
                                ),
                                child: tabPages==0? SizedBox():TabBar(
                                  // tabAlignment: TabAlignment.fill,
                                  dividerColor: Colors.transparent,
                                  onTap: controller.onTabChange,
                                  isScrollable: tabPages == 1,
                                  indicatorColor: accentColor,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  indicator: UnderlineTabIndicator(
                                    borderSide: BorderSide(
                                      width: 3.w,
                                      color: accentColor,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(6.w),
                                      topRight: Radius.circular(6.w),
                                    ),
                                  ),
                                  unselectedLabelColor:
                                      JXColors.secondaryTextBlack,
                                  unselectedLabelStyle:
                                      jxTextStyle.textStyle14(),
                                  labelColor: accentColor,
                                  labelPadding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 8 : 8.w),
                                  labelStyle: jxTextStyle.textStyleBold14(),
                                  controller: controller.gameTabController,
                                  tabs:
                                  List.generate(tabPages,
                                  (index) {
                                    final tab =  controller.isGroupCertified.value?controller.groupGameTabOptions[index]:controller.groupTabOptions[index];
                                    return Tab(text:localized(tab.stringKey));
                                  }),
                                ),
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
                                        fontWeight: FontWeight.w500,
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
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40.0),
                                  child: ElevatedButtonTheme(
                                    data: ElevatedButtonThemeData(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        surfaceTintColor: JXColors.outlineColor,
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
                                            id: controller.group.value?.id ??
                                                controller.chat.value!.id,
                                            size: isDesktop ? 128 : 92.w,
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
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    controller.group.value
                                                            ?.name ??
                                                        controller
                                                            .chat.value!.name,
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: JXColors
                                                          .primaryTextBlack,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                  '${controller.groupMemberListData.length} ${localized(chatInfoMembers)}',
                                                  style: jxTextStyle.textStyle14(
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
                                                color:
                                                    JXColors.bgSecondaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ElevatedButton(
                                                onPressed: () => controller
                                                    .onChatTap(context),
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
                                                  color:
                                                      JXColors.bgSecondaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: ElevatedButton(
                                                  key: controller
                                                      .notificationKey,
                                                  onPressed: () => controller
                                                      .onNotificationTap(
                                                          context),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: toolButton(
                                                      controller.isMute.value
                                                          ? 'assets/svgs/unmute.svg'
                                                          : 'assets/svgs/Mute.svg',
                                                      controller.isMute.value
                                                          ? localized(unmute)
                                                          : localized(mute),
                                                      controller
                                                          .chat.value!.isValid,
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
                                                color:
                                                    JXColors.bgSecondaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 0.0)),
                                                onPressed: () {
                                                  if (!controller
                                                      .chat.value!.isDisband) {
                                                    controller.onChatTap(
                                                      context,
                                                      searching: true,
                                                    );
                                                  }
                                                },
                                                child: toolButton(
                                                  'assets/svgs/Search.svg',
                                                  localized(search),
                                                  !controller
                                                      .chat.value!.isDisband,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              width: 100,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color:
                                                    JXColors.bgSecondaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ElevatedButton(
                                                key: controller.moreVertKey,
                                                onPressed: () => controller
                                                    .showMoreOptionPopup(
                                                        context),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: toolButton(
                                                    'assets/svgs/settingsMore.svg',
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
                                                  .group.value?.profile) &&
                                              !controller.chat.value!.isDisband,
                                          child: Container(
                                            alignment: Alignment.topLeft,
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                              bottom: 12,
                                            ),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: JXColors.outlineColor,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  localized(description),
                                                  style: jxTextStyle.textStyle14(
                                                      color: JXColors
                                                          .secondaryTextBlack),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  controller.group.value
                                                          ?.profile ??
                                                      "",
                                                  style:
                                                      jxTextStyle.textStyle16(),
                                                )
                                              ],
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
                                    margin: jxDimension.infoViewTabBarPadding(),
                                    // width: double.infinity
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          jxDimension.infoViewTabBarBorder(),
                                    ),
                                    child: Obx(
                                      () {
                                        return AnimatedCrossFade(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          firstChild: TabBar(
                                            onTap: controller.onTabChange,
                                            isScrollable:
                                                controller.setScrollable(),
                                            labelPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8),
                                            indicatorColor: accentColor,
                                            indicatorSize:
                                                TabBarIndicatorSize.label,
                                            indicator: UnderlineTabIndicator(
                                              borderSide: BorderSide(
                                                width: 2,
                                                color: accentColor,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20),
                                              ),
                                            ),
                                            unselectedLabelColor:
                                                JXColors.secondaryTextBlack,
                                            unselectedLabelStyle:
                                                jxTextStyle.textStyle14(),
                                            labelColor: accentColor,
                                            labelStyle:
                                                jxTextStyle.textStyleBold14(),
                                            controller:
                                                controller.gameTabController,
                                            tabs: controller.groupGameTabOptions
                                                .map(
                                                  (e) => Tab(
                                                    child: Text(
                                                      localized(e.stringKey),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                          secondChild:
                                              onMoreSelectWidget(context),
                                          firstCurve: Curves.easeInOutCubic,
                                          secondCurve: Curves.easeInOutCubic,
                                          crossFadeState:
                                              controller.onMoreSelect.value
                                                  ? CrossFadeState.showSecond
                                                  : CrossFadeState.showFirst,
                                        );
                                      },
                                    ),
                                  ),
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
                                () {
                                  final tabPages = controller.isGroupCertified.value?controller.gameTabController.length:controller.tabController.length;
                                  return tabPages==0?SizedBox(): TabBarView(
                                  controller: controller.gameTabController,
                                  physics: controller.onMoreSelect.value ||
                                          controller.onAudioPlaying.value
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                                  children: List.generate(
                                    tabPages,
                                    (index) {
                                      final tab =  controller.isGroupCertified.value?controller.groupGameTabOptions[index]:controller.groupTabOptions[index];
                                      return tabViews(
                                      context,
                                      tab,
                                    );
                                    },
                                  ),
                                );
                                },
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

  _buildGroupFunction() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24).w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: common.ImText(
              localized(groupFeature),
              fontSize: 13,
              color: JXColors.black48,
            ),
          ),
          common.ImGap.vGap4,
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingItem(
                  // onTap: () => controller.onSettingOptionTap(
                  //     context,
                  //     SettingOption.notificationAndSound.type),
                  onTap: () => goGroupOperate(controller.context),
                  iconName: 'group_operation',
                  title: localized(groupOperation),
                ),
                SettingItem(
                  onTap: () => goPromoteCenter(controller.context),
                  iconName: 'extension_center',
                  title: localized(promoteCenter),
                  withBorder: false,
                ),
                // SettingItem(
                //   onTap: () => Get.to(GroupPlaySettingView()),
                //   iconName: 'group_play',
                //   title: '群组玩法',
                //   rightWidget: const common.ImText(
                //     '新手教程',
                //     color: JXColors.black48,
                //     fontSize: 16,
                //   ),
                //   withBorder: false,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildGroupTutorial() {
    return ValueListenableBuilder(
      valueListenable: closeTip,
      builder: (context, value, child) => Offstage(offstage: value, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24).w,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                const common.ImText(
                  '如何管理您的群组',
                  fontSize: 16,
                  color: JXColors.blue,
                  fontWeight: FontWeight.w600,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => closeTip.value ^= true,
                  child: const Icon(Icons.close,
                      color: JXColors.black48, size: 8 * 2),
                )
              ],
            ),
            common.ImGap.vGap8,
            Row(
              children: [
                const common.ImText(
                  '游戏管理 追加投资 资金管理 如何盈利？',
                  fontSize: 12,
                  color: JXColors.black48,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Get.to(GroupPlaySettingView());
                  },
                  child: Row(
                    children: [
                      const common.ImText(
                        '用户教程',
                        fontSize: 12,
                        color: JXColors.orange,
                      ),
                      common.ImGap.hGap4,
                      SvgPicture.asset(
                        'assets/svgs/tutorial_arrow_right.svg',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  goToMemberPageByUserName(String userName) {
    User? user = objectMgr.userMgr.getUserByUserName(userName);
    if (user != null) {
      controller.onMemberClicked(user.uid);
    } else {
      common.showWarningToast("查无该会员$userName");
    }
  }

  final Widget backButton = Container(
    alignment: Alignment.center,
    child: Row(
      children: [
        SvgPicture.asset(
          'assets/svgs/Back.svg',
          width: 24,
          height: 24,
          color: JXColors.blue,
        ),
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
    return Column(
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
    );
  }

  /// body展示 widget
  Widget tabViews(BuildContext context, ChatInfoModel tabOption) {
    switch (tabOption.tabType) {
      case 'member':
        return MemberTab(groupController: controller);
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
      default:
        return Container();
    }
  }

  Widget gameTabViews(BuildContext context, ChatInfoModel tabOption,
      {Widget? child}) {
    switch (tabOption.tabType) {
      case 'details':
        return DetailView(chat: controller.chat.value!, featureBtn: child!);
      case 'member':
        return MemberTab(groupController: controller);
      case 'game':
        return GameView(chat: controller.chat.value!);
      default:
        return tabViews(context, tabOption);
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
                  fontWeight: FontWeight.w500,
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
            if (controller.currentTabIndex != 5)
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

class MemberTab extends StatefulWidget {
  final GroupChatInfoController groupController;

  const MemberTab({super.key, required this.groupController});

  @override
  State<MemberTab> createState() => _MemberTabState();
}

class _MemberTabState extends State<MemberTab>
    with AutomaticKeepAliveClientMixin {
  late final controller = widget.groupController;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!controller.chat.value!.isValid) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svgs/empty_state.svg',
            width: 60,
            height: 60,
          ),
          const SizedBox(height: 16),
          Text(
            localized(noHistoryYet),
            style: jxTextStyle.textStyleBold16(),
          ),
          Text(
            localized(yourHistoryIsEmpty),
            style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Visibility(
            visible: controller.addMemberEnable.value,
            child: GestureDetector(
              onTap: controller.onAddMemberTap,
              child: Container(
                color: JXColors.bgSecondaryColor,
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: objectMgr.loginMgr.isDesktop
                          ? const EdgeInsets.symmetric(horizontal: 12)
                          : const EdgeInsets.symmetric(horizontal: 12).w,
                      child: SvgPicture.asset(
                        'assets/svgs/add_friends_plus.svg',
                        width: objectMgr.loginMgr.isDesktop ? 40 : 40.w,
                        height: objectMgr.loginMgr.isDesktop ? 40 : 40.w,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: objectMgr.loginMgr.isDesktop ? 11 : 11.w),
                        decoration: BoxDecoration(
                          border: customBorder,
                        ),
                        child: Text(
                          localized(addNewMember),
                          style: jxTextStyle.textStyle16(color: accentColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final _key = ValueKey(controller.groupMemberListData[index].id);
              return Builder(builder: (BuildContext context) {
                return GestureDetector(
                  key: _key,
                  onTap: () => controller.onMemberClicked(
                      controller.groupMemberListData[index].id),
                  onLongPress: () {
                    if ((controller.isOwner.value ||
                            controller.isAdmin.value) &&
                        !objectMgr.userMgr
                            .isMe(controller.groupMemberListData[index].id)) {
                      RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                      controller.onMemberItemLongPress(
                        context,
                        renderBox,
                        index,
                        target: memberItem(index),
                      );
                    }
                  },
                  child: memberItem(index),
                );
              });
            },
            childCount: controller.groupMemberListData.length,
          ),
        ),
      ],
    );
  }

  Widget memberItem(int index) {
    return Container(
      height: 50,
      color: JXColors.bgSecondaryColor,
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: objectMgr.loginMgr.isDesktop
                ? const EdgeInsets.symmetric(horizontal: 12)
                : const EdgeInsets.symmetric(horizontal: 12).w,
            child: CustomAvatar(
              uid: controller.groupMemberListData[index].id,
              size: objectMgr.loginMgr.isDesktop ? 40 : 40.w,
            ),
          ),
          Expanded(
            child: Container(
              padding: objectMgr.loginMgr.isDesktop
                  ? const EdgeInsets.only(
                      top: 8,
                      bottom: 8,
                      right: 16,
                    )
                  : const EdgeInsets.only(
                      right: 16,
                    ).w,
              decoration: BoxDecoration(
                border: customBorder,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        objectMgr.userMgr
                                .isMe(controller.groupMemberListData[index].id)
                            ? Text(
                                localized(chatInfoYou),
                                style: objectMgr.loginMgr.isDesktop
                                    ? TextStyle(
                                        fontSize: MFontSize.size13.value,
                                        fontWeight: FontWeight.w400,
                                      )
                                    : jxTextStyle.textStyleBold16(
                                        fontWeight: FontWeight.w600,
                                      ),
                              )
                            : NicknameText(
                                isTappable: false,
                                uid: controller.groupMemberListData[index].id,
                                fontSize: objectMgr.loginMgr.isDesktop
                                    ? MFontSize.size13.value
                                    : MFontSize.size16.value,
                                fontWeight: objectMgr.loginMgr.isDesktop
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),

                        ///TODO: change text color of online users
                        Obx(
                          () => Text(
                            '${localized(chatInfoLastSeen, params: [
                                  '${FormatTime.formatTimeFun(controller.groupMemberListData[index].lastOnline, useOnline: false)}'
                                ])}',
                            style: jxTextStyle.textStyle14(
                              color: controller.groupMemberListData[index]
                                          .displayLastOnline ==
                                      localized(myChatJustNow)
                                  ? accentColor
                                  : JXColors.secondaryTextBlack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.group.value?.owner ==
                          controller.groupMemberListData[index].id,
                      child: Text(
                        localized(chatInfoOwner),
                        style: jxTextStyle.textStyle14(
                          color: JXColors.secondaryTextBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.adminList
                          .contains(controller.groupMemberListData[index].id),
                      child: Text(
                        localized(chatInfoAdmin),
                        style: jxTextStyle.textStyle14(
                          color: JXColors.secondaryTextBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
