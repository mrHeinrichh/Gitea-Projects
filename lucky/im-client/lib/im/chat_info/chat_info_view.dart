import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/components/file_view.dart';
import 'package:jxim_client/im/chat_info/components/group_view.dart';
import 'package:jxim_client/im/chat_info/components/link_view.dart';
import 'package:jxim_client/im/chat_info/components/media_view.dart';
import 'package:jxim_client/im/chat_info/components/voice_view.dart';
import 'package:jxim_client/im/chat_info/group/profile_page.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat_info_model.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/custom_avatar_hero.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_view.dart';

class ChatInfoView extends GetView<ChatInfoController> {
  ChatInfoView({
    Key? key,
  }) : super(key: key);

  final bool isDesktop = objectMgr.loginMgr.isDesktop;
  final bool isMobile = objectMgr.loginMgr.isMobile;

  @override
  Widget build(BuildContext context) {
    controller.context = context;
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

    return Scaffold(
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

          if (controller.user.value == null) {
            return const SizedBox();
          }

          final shouldAlignStart = controller.singleChatTabOptions.length == 1;

          return isMobile
              ? ProfilePage(
                  scrollController: controller.singleChatTabOptions.length > 0
                      ? controller.scrollController
                      : null,
                  uid: controller.user.value?.uid,
                  img: controller.user.value?.profilePicture,
                  defaultImg: CustomAvatar(
                    uid: controller.user.value?.uid ?? 0,
                    size: 100,
                  ),
                  // onClickProfile: () => showProfileAvatar(controller.user.value?.id ?? 0, false),
                  onClickProfile: () {
                    showProfileAvatar(
                      controller.user.value?.uid ?? -1,
                      controller.user.value?.uid ?? 0,
                      false,
                    );
                  },
                  server: serversUriMgr.download2Uri?.origin ?? '',
                  ableEdit: (controller.user.value?.relationship ==
                      Relationship.friend),
                  actions: () {
                    if ((controller.user.value?.relationship ==
                        Relationship.friend)) {
                      Get.toNamed(RouteName.editContact,
                          arguments: {"uid": controller.user.value?.uid});
                    }
                  },
                  name: NicknameText(
                    uid: controller.user.value?.uid ?? -1,
                    fontSize: MFontSize.size17.value,
                    fontWeight: MFontWeight.bold6.value,
                    overflow: TextOverflow.ellipsis,
                    isTappable: false,
                  ),
                  description: controller.user.value != null
                      ? UserUtils.onlineStatus(
                          controller.user.value!.lastOnline)
                      : '',
                  body: Container(
                    margin: jxDimension.infoViewGridPadding(),
                    color: controller.singleChatTabOptions.length == 0
                        ? ImColor.systemBg
                        : Colors.white,
                    child: TabBarView(
                      controller: controller.tabController,
                      physics: controller.onMoreSelect.value ||
                              controller.onAudioPlaying.value
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      children: List.generate(
                          controller.singleChatTabOptions.length,
                          (index) => tabViews(
                              context, controller.singleChatTabOptions[index])),
                    ),
                  ),
                  stickyTabBar: Container(
                    key: controller.tabBarKey,
                    margin: jxDimension.infoViewTabBarPadding(),
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    color: controller.singleChatTabOptions.length == 0
                        ? ImColor.systemBg
                        : controller.scrollTabColors.value == 0
                            ? JXColors.bgSecondaryColor
                            : ImColor.systemBg,
                    child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        firstChild: DecoratedBox(
                          decoration: BoxDecoration(
                            border: controller.singleChatTabOptions.length > 0
                                ? customBorder
                                : null,
                          ),
                          child: Container(
                            alignment:
                                shouldAlignStart ? Alignment.centerLeft : null,
                            child: TabBar(
                              isScrollable: shouldAlignStart,
                              onTap: controller.onTabChange,
                              controller: controller.tabController,
                              labelColor: accentColor,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              labelStyle: jxTextStyle
                                  .textStyleBold14()
                                  .copyWith(
                                      fontFamily: appFontfamily,
                                      letterSpacing: -0.2),
                              unselectedLabelColor: JXColors.secondaryTextBlack,
                              unselectedLabelStyle: jxTextStyle
                                  .textStyle14()
                                  .copyWith(
                                      fontFamily: appFontfamily,
                                      letterSpacing: -0.2),
                              indicatorColor: accentColor,
                              indicatorSize: TabBarIndicatorSize.label,
                              indicator: UnderlineTabIndicator(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: accentColor,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              tabs: List.generate(
                                controller.singleChatTabOptions.length,
                                (index) => Tab(
                                  child: Text(
                                    localized(controller
                                        .singleChatTabOptions[index].stringKey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        secondChild: onMoreSelectWidget(context),
                        firstCurve: Curves.easeInOutCubic,
                        secondCurve: Curves.easeInOutCubic,
                        crossFadeState: controller.onMoreSelect.value
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst),
                  ),
                  features: Container(
                    key: controller.childKey,
                    child: Column(
                      children: [
                        Visibility(
                          visible: ((controller.user.value?.relationship ==
                                  Relationship.friend) &&
                              !objectMgr.userMgr
                                  .isMe(controller.user.value?.uid ?? 0) &&
                              !controller.isDeletedAccount.value),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 16, bottom: 0).w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => controller.onChatTap(context),
                                    child: toolButton(
                                      'assets/svgs/chat_info_chat_icon.svg',
                                      localized(groupChat),
                                      controller.ableCall.value,
                                      false,
                                    ),
                                  ),
                                ),
                                ImGap.hGap8,
                                Expanded(
                                  child: GestureDetector(
                                    onTap: controller.onCallPressed.value
                                        ? null
                                        : controller.startCall,
                                    child: toolButton(
                                      'assets/svgs/chat_info_call_icon.svg',
                                      localized(call),
                                      controller.ableCall.value,
                                      controller.onCallPressed.value &&
                                          controller.callingAudio.value,
                                    ),
                                  ),
                                ),
                                ImGap.hGap8,
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => controller.onCallPressed.value
                                        ? null
                                        : controller.startCall(isAudio: false),
                                    child: toolButton(
                                      'assets/svgs/chat_info_video_call.svg',
                                      localized(video_call),
                                      controller.ableCall.value,
                                      controller.onCallPressed.value &&
                                          !controller.callingAudio.value,
                                    ),
                                  ),
                                ),
                                ImGap.hGap8,
                                // 設定靜音
                                Obx(
                                  () => Expanded(
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
                                        controller.ableMute.value,
                                        false,
                                      ),
                                    ),
                                  ),
                                ),
                                ImGap.hGap8,
                                Expanded(
                                  child: GestureDetector(
                                    key: controller.moreVertKey,
                                    onTap: () => controller.onMore(context),
                                    child: toolButton(
                                      'assets/svgs/chat_info_more.svg',
                                      localized(searchMore),
                                      (controller.ableChat.value &&
                                          !objectMgr.userMgr.isMe(
                                              controller.user.value?.uid ?? 0)),
                                      false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: controller.ableAddFriend.value ||
                              controller.ableFriendRequestSent.value ||
                              controller.ableRejectFriend.value ||
                              controller.ableAcceptFriend.value,
                          child: controller.ableAddFriend.value ||
                                  controller.ableFriendRequestSent.value
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: controller.ableAddFriend.value
                                        ? controller.addFriend
                                        : null,
                                    child: ForegroundOverlayEffect(
                                      withEffect:
                                          controller.ableAddFriend.value,
                                      radius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                        bottom: Radius.circular(8),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: JXColors.bgSecondaryColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.only(
                                            top: 12.5, bottom: 12.5),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/svgs/add_new_friend_icon.svg',
                                              width: 20.w,
                                              height: 20.w,
                                              color: controller
                                                      .ableFriendRequestSent
                                                      .value
                                                  ? accentColor.withOpacity(0.3)
                                                  : accentColor,
                                              fit: BoxFit.fitWidth,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10.0),
                                              child: Text(
                                                localized(controller
                                                        .ableAddFriend.value
                                                    ? addFriend
                                                    : chatInfoRequestSent),
                                                style: TextStyle(
                                                  color: controller
                                                          .ableFriendRequestSent
                                                          .value
                                                      ? accentColor
                                                          .withOpacity(0.3)
                                                      : accentColor,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : ElevatedButtonTheme(
                                  data: ElevatedButtonThemeData(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.white,
                                      splashFactory: NoSplash.splashFactory,
                                      shadowColor: Colors.transparent,
                                      surfaceTintColor: JXColors.outlineColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              controller.acceptFriend(),
                                          child: Text(
                                            localized(chatInfoAcceptFriend),
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: accentColor),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '|',
                                        style: TextStyle(
                                            color: Colors.grey.shade300),
                                      ),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              controller.rejectFriend(),
                                          child: Text(
                                            localized(rejectFriendRequestText),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.red),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: JXColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(top: 24),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              // Username
                              Visibility(
                                visible:
                                    controller.user.value?.username != '' &&
                                        !controller.isDeletedAccount.value,
                                child: _buildUserInfo(
                                  title: localized(contactUsername),
                                  infoTxt: !controller.isDeletedAccount.value
                                      ? '@${controller.user.value?.username}'
                                      : '-',
                                  hasBorder: false,
                                  showCopyIcon:
                                      !controller.isDeletedAccount.value,
                                  onTap: () {
                                    if (!controller.isDeletedAccount.value) {
                                      copyToClipboard(
                                          '${controller.user.value?.username}');
                                    }
                                  },
                                  rightWidget: Visibility(
                                    visible: !controller.isDeletedAccount.value,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.deferToChild,
                                      onTap: () {
                                        Get.toNamed(
                                          RouteName.qrCodeWithoutScanButtonView,
                                          arguments: {
                                            "user": controller.user.value
                                          },
                                        );
                                      },
                                      child: SvgPicture.asset(
                                        'assets/svgs/qrCode.svg',
                                        width: 28, //4 is from padding
                                        height: 28,
                                        colorFilter: ColorFilter.mode(
                                            accentColor, BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Phone number
                              Visibility(
                                visible: controller.user.value?.contact != '',
                                child: _buildUserInfo(
                                    title: localized(psPhoneNumber),
                                    infoTxt: !controller.isDeletedAccount.value
                                        ? '${controller.user.value?.countryCode} ${formatNumber(controller.user.value!.contact)}'
                                        : '-',
                                    showCopyIcon:
                                        !controller.isDeletedAccount.value,
                                    onTap: () {
                                      if (!controller.isDeletedAccount.value) {
                                        copyToClipboard(
                                            '${controller.user.value?.countryCode} ${controller.user.value?.contact}');
                                      }
                                    }),
                              ),

                              // Description
                              Visibility(
                                visible:
                                    controller.user.value?.profileBio != '',
                                child: _buildUserInfo(
                                  title: localized(description),
                                  infoWidget: LayoutBuilder(
                                      builder: (context, constraints) {
                                    //取得簡介文字行數

                                    final span = TextSpan(
                                      text: controller.user.value!.profileBio,
                                      style: jxTextStyle.textStyle16(),
                                    );

                                    final tp = TextPainter(
                                        text: span,
                                        textDirection: TextDirection.ltr);

                                    tp.layout(maxWidth: constraints.maxWidth);

                                    //get text lines
                                    final numLines =
                                        tp.computeLineMetrics().length;
                                    controller.profileTextNumLines = numLines;

                                    return Text(
                                      controller.user.value!.profileBio,
                                      style: jxTextStyle.textStyle16(),
                                    );
                                  }),
                                ),
                              ),

                              // block or unblock user
                              if(controller.user.value?.relationship !=Relationship.stranger)
                              if(!objectMgr.userMgr.isMe(controller.user.value!.uid))
                                controller.user.value?.relationship ==
                                        Relationship.blocked
                                    ? _buildUserInfo(
                                        infoTxt: localized(unblockUser),
                                        infoTxtColor: errorColor,
                                        onTap: () {
                                          controller.doUnblockUser();
                                        },
                                      )
                                    : _buildUserInfo(
                                        infoTxt: localized(blockUser),
                                        infoTxtColor: errorColor,
                                        onTap: () {
                                          controller.doBlockUser();
                                        },
                                      )
                            ],
                          ),
                        )
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
                              onTap: () => controller.exitInfoView(),
                              behavior: HitTestBehavior.opaque,
                              child: backButton,
                            ),
                          ),
                          Text(localized(groupProfile)),
                          OpacityEffect(
                            child: GestureDetector(
                              onTap: () {
                                if (controller.ableEdit.value) {
                                  final id = Get.find<HomeController>()
                                              .pageIndex
                                              .value ==
                                          0
                                      ? 1
                                      : 2;
                                  Get.toNamed(RouteName.editContact,
                                      arguments: {
                                        "uid": controller.user.value?.uid
                                      },
                                      id: id);
                                }
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
                                        padding: const EdgeInsets.only(
                                            left: 40,
                                            right: 40,
                                            top: 40.0,
                                            bottom: 16),
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
                                              CustomAvatarHero(
                                                id: controller
                                                        .user.value?.uid ??
                                                    0,
                                                size: isDesktop ? 128 : 100,
                                              ),

                                              const SizedBox(height: 12),

                                              /// 用户名字
                                              IntrinsicWidth(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: NicknameText(
                                                        uid: controller.user
                                                                .value?.uid ??
                                                            -1,
                                                        fontSize: 22,
                                                        fontWeight: MFontWeight
                                                            .bold7.value,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        isTappable: false,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              /// 在线时间
                                              Obx(
                                                () => Text(
                                                  controller.user.value
                                                              ?.lastOnline !=
                                                          null
                                                      ? UserUtils.onlineStatus(
                                                          controller.user.value!
                                                              .lastOnline)
                                                      : '',
                                                  style: jxTextStyle.textStyle14(
                                                      color: JXColors
                                                          .secondaryTextBlack),
                                                ),
                                              ),
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
                                                        controller
                                                            .ableChat.value,
                                                        false,
                                                      ),
                                                    ),
                                                  ),
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
                                                            controller
                                                                .ableMute.value,
                                                            false,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    width: 100,
                                                    height: 60,
                                                    child: ElevatedButton(
                                                      key: controller
                                                          .moreVertKey,
                                                      onPressed: () =>
                                                          controller
                                                              .onMore(context),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: toolButton(
                                                          'assets/svgs/chat_info_more.svg',
                                                          localized(searchMore),
                                                          (controller.ableChat
                                                                  .value &&
                                                              !objectMgr.userMgr
                                                                  .isMe(controller
                                                                          .user
                                                                          .value
                                                                          ?.uid ??
                                                                      0)),
                                                          false,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              if (controller.user.value
                                                          ?.username !=
                                                      '' ||
                                                  controller
                                                          .user.value?.contact !=
                                                      '' ||
                                                  controller
                                                          .user.value?.profileBio !=
                                                      '' ||
                                                  controller
                                                      .ableAddFriend.value ||
                                                  controller
                                                      .ableFriendRequestSent
                                                      .value ||
                                                  controller
                                                      .ableAcceptFriend.value ||
                                                  controller
                                                      .ableRejectFriend.value)
                                                const SizedBox(height: 16),

                                              Visibility(
                                                visible: controller
                                                        .ableAddFriend.value ||
                                                    controller
                                                        .ableFriendRequestSent
                                                        .value ||
                                                    controller.ableRejectFriend
                                                        .value ||
                                                    controller
                                                        .ableAcceptFriend.value,
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 10,
                                                      right: 10,
                                                      bottom: 16),
                                                  decoration: BoxDecoration(
                                                    color: JXColors
                                                        .bgSecondaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: controller
                                                              .ableAddFriend
                                                              .value ||
                                                          controller
                                                              .ableFriendRequestSent
                                                              .value
                                                      ? ElevatedButton(
                                                          onPressed: controller
                                                                  .ableAddFriend
                                                                  .value
                                                              ? controller
                                                                  .addFriend
                                                              : null,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        12),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                SvgPicture
                                                                    .asset(
                                                                  'assets/svgs/add_new_friend_icon.svg',
                                                                  width: 20,
                                                                  height: 20,
                                                                  color: controller
                                                                          .ableFriendRequestSent
                                                                          .value
                                                                      ? accentColor
                                                                          .withOpacity(
                                                                              0.3)
                                                                      : accentColor,
                                                                  fit: BoxFit
                                                                      .fitWidth,
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              10.0),
                                                                  child: Text(
                                                                    localized(controller
                                                                            .ableAddFriend
                                                                            .value
                                                                        ? addFriend
                                                                        : chatInfoRequestSent),
                                                                    style:
                                                                        TextStyle(
                                                                      color: controller
                                                                              .ableFriendRequestSent
                                                                              .value
                                                                          ? accentColor
                                                                              .withOpacity(0.3)
                                                                          : accentColor,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed: () =>
                                                                      controller
                                                                          .acceptFriend(),
                                                                  child:
                                                                      Container(
                                                                    height: 45,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      localized(
                                                                          chatInfoAcceptFriend),
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          color:
                                                                              accentColor),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                '|',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade300),
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed: () =>
                                                                      controller
                                                                          .rejectFriend(),
                                                                  child:
                                                                      Container(
                                                                    height: 45,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      localized(
                                                                          rejectFriendRequestText),
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          color:
                                                                              Colors.red),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: JXColors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  children: [
                                                    // Username
                                                    Visibility(
                                                      visible: controller
                                                              .user
                                                              .value
                                                              ?.username !=
                                                          '',
                                                      child: _buildUserInfo(
                                                        title: localized(
                                                            contactUsername),
                                                        infoTxt:
                                                            '@${controller.user.value?.username}',
                                                        hasBorder: false,
                                                        showCopyIcon: true,
                                                        onTap: () {
                                                          copyToClipboard(
                                                              '${controller.user.value?.username}');
                                                        },
                                                        rightWidget:
                                                            Container(),
                                                      ),
                                                    ),

                                                    // Phone number
                                                    Visibility(
                                                      visible: controller.user
                                                              .value?.contact !=
                                                          '',
                                                      child: _buildUserInfo(
                                                          title: localized(
                                                              psPhoneNumber),
                                                          infoTxt:
                                                              '${controller.user.value?.countryCode} ${controller.user.value?.contact}',
                                                          showCopyIcon: true,
                                                          onTap: () {
                                                            copyToClipboard(
                                                                '${controller.user.value?.countryCode} ${controller.user.value?.contact}');
                                                          }),
                                                    ),

                                                    // Description
                                                    Visibility(
                                                      visible: controller
                                                              .user
                                                              .value
                                                              ?.profileBio !=
                                                          '',
                                                      child: _buildUserInfo(
                                                        title: localized(
                                                            description),
                                                        infoWidget: LayoutBuilder(
                                                            builder: (context,
                                                                constraints) {
                                                          //取得簡介文字行數

                                                          final span = TextSpan(
                                                            text: controller
                                                                .user
                                                                .value!
                                                                .profileBio,
                                                            style: jxTextStyle
                                                                .textStyle16(),
                                                          );

                                                          final tp = TextPainter(
                                                              text: span,
                                                              textDirection:
                                                                  TextDirection
                                                                      .ltr);

                                                          tp.layout(
                                                              maxWidth:
                                                                  constraints
                                                                      .maxWidth);

                                                          //get text lines
                                                          final numLines = tp
                                                              .computeLineMetrics()
                                                              .length;
                                                          controller
                                                                  .profileTextNumLines =
                                                              numLines;

                                                          return Text(
                                                            controller
                                                                .user
                                                                .value!
                                                                .profileBio,
                                                            style: jxTextStyle
                                                                .textStyle16(),
                                                          );
                                                        }),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
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
                                          margin: jxDimension
                                              .infoViewTabBarPadding(),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: jxDimension
                                                .infoViewTabBarBorder(),
                                          ),
                                          child: Obx(
                                            () {
                                              return AnimatedCrossFade(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                firstChild: DecoratedBox(
                                                  decoration:
                                                      const BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        width: 1.0,
                                                        color: JXColors
                                                            .outlineColor,
                                                      ),
                                                    ),
                                                  ),
                                                  child: controller
                                                              .singleChatTabOptions
                                                              .length >
                                                          0
                                                      ? TabBar(
                                                          onTap: controller
                                                              .onTabChange,
                                                          isScrollable: false,
                                                          labelPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8),
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
                                                              color:
                                                                  accentColor,
                                                            ),
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .only(
                                                              topLeft: Radius
                                                                  .circular(20),
                                                              topRight: Radius
                                                                  .circular(20),
                                                            ),
                                                          ),
                                                          unselectedLabelColor:
                                                              JXColors
                                                                  .secondaryTextBlack,
                                                          unselectedLabelStyle:
                                                              jxTextStyle
                                                                  .textStyle14(),
                                                          labelColor:
                                                              accentColor,
                                                          labelStyle: jxTextStyle
                                                              .textStyleBold14(),
                                                          controller: controller
                                                              .tabController,
                                                          tabs: controller
                                                              .singleChatTabOptions
                                                              .map(
                                                                (e) => Tab(
                                                                  child: Text(
                                                                    localized(e
                                                                        .stringKey),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                        )
                                                      : const SizedBox(),
                                                ),
                                                secondChild:
                                                    onMoreSelectWidget(context),
                                                firstCurve:
                                                    Curves.easeInOutCubic,
                                                secondCurve:
                                                    Curves.easeInOutCubic,
                                                crossFadeState: controller
                                                        .onMoreSelect.value
                                                    ? CrossFadeState.showSecond
                                                    : CrossFadeState.showFirst,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                          ];
                        },
                        body: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            margin: jxDimension.infoViewGridPadding(),
                            height: View.of(context).physicalSize.height,
                            color: Colors.white,
                            child: Obx(
                              () => controller.singleChatTabOptions.length > 0
                                  ? TabBarView(
                                      controller: controller.tabController,
                                      physics: controller.onMoreSelect.value ||
                                              controller.onAudioPlaying.value
                                          ? const NeverScrollableScrollPhysics()
                                          : null,
                                      children: List.generate(
                                        controller.singleChatTabOptions.length,
                                        (index) => tabViews(
                                          context,
                                          controller
                                              .singleChatTabOptions[index],
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
        },
      ),
    );
  }

  Widget _buildUserInfo({
    String? title,
    String? infoTxt,
    Color? infoTxtColor,
    Widget? infoWidget,
    Widget? rightWidget,
    bool hasBorder = true,
    bool showCopyIcon = false,
    void Function()? onTap,
  }) {
    final isDesktop = objectMgr.loginMgr.isDesktop;

    Color color = Colors.transparent;
    return Column(
      children: [
        if (hasBorder)
          Padding(
            padding: EdgeInsets.only(left: isDesktop ? 16 : 16.w),
            child: Container(
              height: 0.33,
              color: JXColors.borderPrimaryColor,
            ),
          ),
        OverlayEffect(
          withEffect: onTap != null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: color,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null) ...[
                          Text(
                            title,
                            style: jxTextStyle.textStyle14(),
                          ),
                        ],
                        if (infoTxt != null)
                          Text(
                            infoTxt,
                            style: jxTextStyle.textStyle16(
                              color: infoTxtColor ?? accentColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (infoWidget != null) infoWidget
                      ],
                    ),
                  ),
                ),
                // const Spacer(),
                if (rightWidget != null) rightWidget,
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 多功能选项按钮
  Widget toolButton(
    String imageUrl,
    String text,
    bool enableState,
    bool shouldShowLoading,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            shouldShowLoading
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 10.0),
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(color: accentColor),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        imageUrl,
                        width: 22,
                        height: 22,
                        color: enableState
                            ? controller.isMuteOpen.value ||
                                    controller.isMoreOpen.value
                                ? accentColor.withOpacity(0.3)
                                : accentColor
                            : accentColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: jxTextStyle.textStyle12(
                          color: enableState
                              ? controller.isMuteOpen.value ||
                                      controller.isMoreOpen.value
                                  ? accentColor.withOpacity(0.3)
                                  : accentColor
                              : accentColor.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  String formatNumber(String value) {
    return value.length > 4
        ? value.substring(0, 4) + ' ' + value.substring(4, value.length)
        : value;
  }

  /// body展示 widget
  Widget tabViews(BuildContext context, ChatInfoModel tabOption) {
    switch (tabOption.tabType) {
      case 'media':
        controller.chat.value?.setValue("typ", chatTypeSingle);
        return MediaView(chat: controller.chat.value, isGroup: false);
      case 'file':
        return FileView(chat: controller.chat.value, isGroup: false);
      case 'audio':
        return VoiceView(chat: controller.chat.value, isGroup: false);
      case 'link':
        return LinkView(chat: controller.chat.value, isGroup: false);
      case 'group':
        return GroupView(
            userId: controller.user.value!.uid, chat: controller.chat.value);
      default:
        return Container();
    }
  }

  Widget onMoreSelectWidget(BuildContext context) {
    final key = GlobalKey();
    return Obx(
      () => Row(
        children: <Widget>[
          GestureDetector(
            onTap: controller.onMoreCancel,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: objectMgr.loginMgr.isDesktop ? 13 : 13.0.w,
                horizontal: objectMgr.loginMgr.isDesktop ? 20 : 20.w,
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
              onTap: () => controller
                  .onMoreSelectCallback!(controller.selectedMessageList.first),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: objectMgr.loginMgr.isDesktop ? 13 : 13.0.w,
                  horizontal: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                ),
                child: Icon(
                  Icons.image_search_outlined,
                  color: accentColor,
                  size: objectMgr.loginMgr.isDesktop ? 24 : 24.w,
                ),
              ),
            ),
          if (controller.currentTabIndex.value != 2 &&
              controller.currentTabIndex.value != 3)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => controller.onForwardMessage(context),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: objectMgr.loginMgr.isDesktop ? 13 : 13.0.w,
                  horizontal: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                ),
                child: Icon(
                  CupertinoIcons.arrowshape_turn_up_right,
                  color: accentColor,
                  size: objectMgr.loginMgr.isDesktop ? 24 : 24.w,
                  weight: objectMgr.loginMgr.isDesktop ? 10 : 10.w,
                ),
              ),
            ),
          if (controller.currentTabIndex.value != 3)
            GestureDetector(
              key: key,
              onTap: () => controller.onDeleteMessage(context, key),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: objectMgr.loginMgr.isDesktop ? 13 : 13.0.w,
                  horizontal: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
