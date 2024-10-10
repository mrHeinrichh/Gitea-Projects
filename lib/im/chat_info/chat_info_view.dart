import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/end_to_end_encryption/setting_info/chat_encryption_bottom_sheet.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/components/file_view.dart';
import 'package:jxim_client/im/chat_info/components/group_view.dart';
import 'package:jxim_client/im/chat_info/components/link_view.dart';
import 'package:jxim_client/im/chat_info/components/media_view.dart';
import 'package:jxim_client/im/chat_info/components/voice_view.dart';
import 'package:jxim_client/im/chat_info/group/chat_info_nickname_text.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_view.dart';
import 'package:jxim_client/im/chat_info/group/profile_page.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat_info_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar_hero.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/qr_code.dart';
import 'package:jxim_client/views/contact/qr_code_dialog.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:lottie/lottie.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatInfoView extends GetView<ChatInfoController> {
  ChatInfoView({
    super.key,
  });

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

    return Scaffold(
      backgroundColor: colorBackground,
      body: Obx(() => AnimatedPadding(
          padding: EdgeInsets.only(top: controller.downOffset.value),
          duration: const Duration(milliseconds: 100),
          child: _body(context, backButton))),
    );
  }

  Widget _body(BuildContext context, Widget backButton) {
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

    final shouldAlignStart = controller.singleChatTabOptions.length == 1;
    return controller.isModalBottomSheet.value &&
            (controller.user.value?.relationship == Relationship.stranger ||
                controller.user.value?.relationship ==
                    Relationship.sentRequest ||
                controller.user.value?.relationship ==
                    Relationship.receivedRequest)
        ? createNewContactView(context)
        : isMobile
            ? ProfilePage(
                scrollController: controller.singleChatTabOptions.isNotEmpty
                    ? controller.scrollController
                    : null,
                uid: controller.user.value?.uid,
                img: controller.user.value?.profilePicture,
                defaultImg: Hero(
                    tag: '${controller.user.value?.uid}',
                    child: !controller.isSpecialChat.value &&
                            controller.user.value != null
                        ? CustomAvatar.user(
                            controller.user.value!,
                            size: 100,
                            headMin: Config().headMin,
                          )
                        : buildSpecialChatIcon()),
                onClickProfile: () {
                  if (!controller.chat.value!.isSpecialChat) {
                    showProfileAvatar(
                      controller.user.value?.uid ?? -1,
                      controller.user.value?.uid ?? 0,
                      false,
                    );
                  }
                },
                server: serversUriMgr.download2Uri?.origin ?? '',
                ableEdit: controller.ableEdit.value,
                actions: () {
                  if (controller.ableEdit.value) {
                    if (Get.isRegistered<SearchContactController>()) {
                      if (controller.isModalBottomSheet.value) {
                        Get.back();
                      }
                    }
                    Get.toNamed(
                      RouteName.editContact,
                      arguments: {"uid": controller.user.value?.uid},
                    );
                  }
                },
                isModalBottomSheet: controller.isModalBottomSheet.value,
                isStranger: controller.user.value?.relationship ==
                    Relationship.stranger,
                name: buildNickname(controller.isEncrypted.value),
                description: buildDescription(),
                body: Container(
                  margin: jxDimension.infoViewGridPadding(),
                  color: controller.singleChatTabOptions.isEmpty
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
                        context,
                        controller.singleChatTabOptions[index],
                      ),
                    ),
                  ),
                ),
                stickyTabBar: Container(
                  key: controller.tabBarKey,
                  margin: jxDimension.infoViewTabBarPadding(),
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  color: controller.singleChatTabOptions.isEmpty
                      ? ImColor.systemBg
                      : controller.scrollTabColors.value == 0
                          ? colorWhite
                          : ImColor.systemBg,
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    firstChild: DecoratedBox(
                      decoration: BoxDecoration(
                        border: controller.singleChatTabOptions.isNotEmpty
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
                          labelColor: themeColor,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          labelStyle: jxTextStyle.textStyleBold14().copyWith(
                                fontFamily: appFontfamily,
                                letterSpacing: -0.2,
                              ),
                          unselectedLabelColor: colorTextSecondary,
                          unselectedLabelStyle:
                              jxTextStyle.textStyle14().copyWith(
                                    fontFamily: appFontfamily,
                                    letterSpacing: -0.2,
                                  ),
                          indicatorColor: themeColor,
                          indicatorSize: TabBarIndicatorSize.label,
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              width: 2,
                              color: themeColor,
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
                                localized(
                                  controller
                                      .singleChatTabOptions[index].stringKey,
                                ),
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
                        : CrossFadeState.showFirst,
                  ),
                ),
                features: buildFeature(context),
              )
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
                                Get.toNamed(
                                  RouteName.editContact,
                                  arguments: {
                                    "uid": controller.user.value?.uid,
                                  },
                                  id: id,
                                );
                              }
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
                            handle:
                                NestedScrollView.sliverOverlapAbsorberHandleFor(
                              context,
                            ),
                            sliver: MultiSliver(
                              pushPinnedChildren: true,
                              children: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 40,
                                      right: 40,
                                      top: 40.0,
                                      bottom: 16,
                                    ),
                                    child: ElevatedButtonTheme(
                                      data: ElevatedButtonThemeData(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          surfaceTintColor: colorBorder,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 0.0,
                                        ),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          /// 头像
                                          CustomAvatarHero(
                                            id: controller.user.value?.uid ?? 0,
                                            size: isDesktop ? 128 : 100,
                                          ),

                                          const SizedBox(height: 12),

                                          /// 用户名字
                                          IntrinsicWidth(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
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
                                                  child: NicknameText(
                                                    uid: controller
                                                            .user.value?.uid ??
                                                        -1,
                                                    fontSize:
                                                        MFontSize.size22.value,
                                                    fontWeight:
                                                        MFontWeight.bold7.value,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                          .lastOnline,
                                                    )
                                                  : '',
                                              style: jxTextStyle.textStyle14(
                                                color: colorTextSecondary,
                                              ),
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
                                                  color: colorWhite,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      controller.onChatTap(
                                                    context,
                                                  ),
                                                  child: toolButton(
                                                    'assets/svgs/message.svg',
                                                    localized(homeChat),
                                                    controller.ableChat.value,
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
                                                    color: colorWhite,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                  child: ElevatedButton(
                                                    key: controller
                                                        .notificationKey,
                                                    onPressed: () => controller
                                                        .onNotificationTap(
                                                      context,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: toolButton(
                                                        controller
                                                            .getMuteIcon(),
                                                        controller.isMute.value
                                                            ? localized(
                                                                unmute,
                                                              )
                                                            : localized(
                                                                mute,
                                                              ),
                                                        controller
                                                            .ableMute.value,
                                                        false,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              SizedBox(
                                                width: 100,
                                                height: 60,
                                                child: ElevatedButton(
                                                  key: controller.moreVertKey,
                                                  onPressed: () =>
                                                      controller.onMore(
                                                    context,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: toolButton(
                                                      'assets/svgs/chat_info_more.svg',
                                                      localized(
                                                        searchMore,
                                                      ),
                                                      (controller
                                                              .ableChat.value &&
                                                          !objectMgr.userMgr
                                                              .isMe(
                                                            controller
                                                                    .user
                                                                    .value
                                                                    ?.uid ??
                                                                0,
                                                          )),
                                                      false,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          if (controller
                                                      .user.value?.username !=
                                                  '' ||
                                              controller
                                                      .user.value?.contact !=
                                                  '' ||
                                              controller.user.value?.profileBio !=
                                                  '' ||
                                              controller.ableAddFriend.value ||
                                              controller.ableFriendRequestSent
                                                  .value ||
                                              controller
                                                  .ableAcceptFriend.value ||
                                              controller.ableRejectFriend.value)
                                            const SizedBox(height: 16),

                                          Visibility(
                                            visible:
                                                controller.ableAddFriend.value ||
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
                                                bottom: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorWhite,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: controller.ableAddFriend
                                                          .value ||
                                                      controller
                                                          .ableFriendRequestSent
                                                          .value
                                                  ? ElevatedButton(
                                                      onPressed: () {
                                                        if (controller
                                                            .ableAddFriend
                                                            .value) {
                                                          controller.addFriend(
                                                            context,
                                                          );
                                                        }
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 12,
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            SvgPicture.asset(
                                                              'assets/svgs/add_new_friend_icon.svg',
                                                              width: 20,
                                                              height: 20,
                                                              color: controller
                                                                      .ableFriendRequestSent
                                                                      .value
                                                                  ? themeColor
                                                                      .withOpacity(
                                                                          0.3)
                                                                  : themeColor,
                                                              fit: BoxFit
                                                                  .fitWidth,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                left: 10.0,
                                                              ),
                                                              child: Text(
                                                                localized(
                                                                  controller
                                                                          .ableAddFriend
                                                                          .value
                                                                      ? addFriend
                                                                      : chatInfoRequestSent,
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  color: controller
                                                                          .ableFriendRequestSent
                                                                          .value
                                                                      ? themeColor
                                                                          .withOpacity(
                                                                              0.3)
                                                                      : themeColor,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  : Row(
                                                      children: [
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () =>
                                                                controller
                                                                    .acceptFriend(),
                                                            child: Container(
                                                              height: 45,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                localized(
                                                                  chatInfoAcceptFriend,
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  color:
                                                                      themeColor,
                                                                ),
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
                                                                .grey.shade300,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () =>
                                                                controller
                                                                    .rejectFriend(),
                                                            child: Container(
                                                              height: 45,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                localized(
                                                                  rejectFriendRequestText,
                                                                ),
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorWhite,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                10,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                // Username
                                                Visibility(
                                                  visible: controller.user.value
                                                          ?.username !=
                                                      '',
                                                  child: _buildUserInfo(
                                                    title: localized(
                                                      contactUsername,
                                                    ),
                                                    infoTxt:
                                                        '@${controller.user.value?.username}',
                                                    hasBorder: false,
                                                    onTap: () {
                                                      copyToClipboard(
                                                        '${controller.user.value?.username}',
                                                      );
                                                    },
                                                    rightWidget: Container(),
                                                  ),
                                                ),

                                                // Phone number
                                                Visibility(
                                                  visible: controller.user.value
                                                          ?.contact !=
                                                      '',
                                                  child: _buildUserInfo(
                                                    title: localized(
                                                      psPhoneNumber,
                                                    ),
                                                    infoTxt:
                                                        '${controller.user.value?.countryCode} ${controller.user.value?.contact}',
                                                    onTap: () {
                                                      copyToClipboard(
                                                        '${controller.user.value?.countryCode} ${controller.user.value?.contact}',
                                                      );
                                                    },
                                                  ),
                                                ),

                                                // Description
                                                Visibility(
                                                  visible: controller.user.value
                                                          ?.profileBio !=
                                                      '',
                                                  child: _buildUserInfo(
                                                    title: localized(
                                                      description,
                                                    ),
                                                    infoWidget: LayoutBuilder(
                                                      builder: (
                                                        context,
                                                        constraints,
                                                      ) {
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
                                                              TextDirection.ltr,
                                                        );

                                                        tp.layout(
                                                          maxWidth: constraints
                                                              .maxWidth,
                                                        );

                                                        //get text lines
                                                        final numLines = tp
                                                            .computeLineMetrics()
                                                            .length;
                                                        controller
                                                                .profileTextNumLines =
                                                            numLines;

                                                        return Text(
                                                          controller.user.value!
                                                              .profileBio,
                                                          style: jxTextStyle
                                                              .textStyle16(),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),

                                                // Friend Request Remark
                                                Obx(() {
                                                  return Visibility(
                                                    visible: controller
                                                        .historyFriendRequestRemark
                                                        .isNotEmpty,
                                                    child: Column(
                                                      children:
                                                          getFriendRequestRemarks(),
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
                                      margin:
                                          jxDimension.infoViewTabBarPadding(),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            jxDimension.infoViewTabBarBorder(),
                                      ),
                                      child: Obx(
                                        () {
                                          return AnimatedCrossFade(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            firstChild: DecoratedBox(
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    width: 1.0,
                                                    color: colorBorder,
                                                  ),
                                                ),
                                              ),
                                              child: controller
                                                      .singleChatTabOptions
                                                      .isNotEmpty
                                                  ? TabBar(
                                                      onTap: controller
                                                          .onTabChange,
                                                      isScrollable: false,
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
                                                        borderSide: BorderSide(
                                                          width: 2,
                                                          color: themeColor,
                                                        ),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .only(
                                                          topLeft:
                                                              Radius.circular(
                                                            20,
                                                          ),
                                                          topRight:
                                                              Radius.circular(
                                                            20,
                                                          ),
                                                        ),
                                                      ),
                                                      unselectedLabelColor:
                                                          colorTextSecondary,
                                                      unselectedLabelStyle:
                                                          jxTextStyle
                                                              .textStyle14(),
                                                      labelColor: themeColor,
                                                      labelStyle: jxTextStyle
                                                          .textStyleBold14(),
                                                      controller: controller
                                                          .tabController,
                                                      tabs: controller
                                                          .singleChatTabOptions
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
                                                    )
                                                  : const SizedBox(),
                                            ),
                                            secondChild: onMoreSelectWidget(
                                              context,
                                            ),
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
                              ],
                            ),
                          ),
                        ];
                      },
                      body: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Container(
                          margin: jxDimension.infoViewGridPadding(),
                          height: View.of(context).physicalSize.height,
                          color: Colors.white,
                          child: Obx(
                            () => controller.singleChatTabOptions.isNotEmpty
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
                                        controller.singleChatTabOptions[index],
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

  /*Obx(() {
                                        return Visibility(
                                          visible: controller.isEncrypted.value,
                                          child: _buildEncryptionTile(context),
                                        );
                                      }),*/

  _showRecommendFriendDrawer(context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ForwardContainer(
          isRecommendFriend: true,
          onSend: (chats, name) => controller.recommendFriend(chats, name),
        );
      },
    );
  }

  Widget _actionButton(context) {
    switch (controller.user.value?.relationship) {
      case Relationship.blocked:
      case Relationship.blockByTarget:
      case Relationship.friend:
        return _buildUserInfo(
          verticalPadding: 12,
          infoTxt: localized(recommendToFriend),
          hasBorder: controller.user.value?.contact != '' ||
              controller.user.value?.username != '' ||
              controller.user.value?.email != '' ||
              controller.user.value?.profileBio != '',
          onTap: () {
            _showRecommendFriendDrawer(context);
          },
        );
      case Relationship.stranger:
        return _buildUserInfo(
          verticalPadding: 12,
          infoTxt: localized(sendFriendReq),
          hasBorder: controller.user.value?.contact != '' ||
              controller.user.value?.username != '' ||
              controller.user.value?.email != '' ||
              controller.user.value?.profileBio != '',
          onTap: () {
            controller.addFriend(context);
          },
        );
      case Relationship.sentRequest:
        return _buildUserInfo(
          verticalPadding: 12,
          infoTxt: localized(withdrawFriendReq),
          infoTxtColor: colorRed,
          hasBorder: controller.user.value?.contact != '' ||
              controller.user.value?.username != '' ||
              controller.user.value?.email != '' ||
              controller.user.value?.profileBio != '',
          onTap: () {
            controller.withdrawRequest(context);
          },
        );
      case Relationship.receivedRequest:
        return Column(
          children: [
            _buildUserInfo(
              verticalPadding: 12,
              infoTxt: localized(acceptFriendReq),
              onTap: () {
                controller.acceptFriend();
              },
              hasBorder: controller.user.value?.contact != '' ||
                  controller.user.value?.username != '' ||
                  controller.user.value?.email != '' ||
                  controller.user.value?.profileBio != '',
            ),
            _buildUserInfo(
              verticalPadding: 12,
              infoTxt: localized(rejectFriendReq),
              infoTxtColor: colorRed,
              onTap: () {
                showCustomBottomAlertDialog(
                  context,
                  withHeader: false,
                  cancelTextColor: themeColor,
                  items: [
                    CustomBottomAlertItem(
                      text: localized(rejectFriendInvitation),
                      textColor: colorRed,
                      onClick: () {
                        controller.rejectFriend();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        );
      case Relationship.self:
      case null:
        return const SizedBox();
    }
  }

  /// 多功能选项按钮
  Widget toolButton(
    String imageUrl,
    String text,
    bool enableState,
    bool shouldShowLoading,
  ) {
    if (!controller.isSpecialChat.value &&
        (controller.user.value?.relationship == Relationship.blockByTarget ||
            controller.user.value?.relationship == Relationship.blocked)) {
      enableState = true;
    }
    return ForegroundOverlayEffect(
      radius: const BorderRadius.vertical(
        top: Radius.circular(12),
        bottom: Radius.circular(12),
      ),
      child: Container(
        padding: isDesktop ? null : const EdgeInsets.symmetric(vertical: 8.0),
        width: MediaQuery.of(Get.context!).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            shouldShowLoading
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 10.0,
                    ),
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(color: themeColor),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMenuIcon(
                        imageUrl: imageUrl,
                        text: text,
                        enableState: enableState,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: jxTextStyle.textStyle12(
                          color: enableState
                              ? controller.isMuteOpen.value ||
                                      controller.isMoreOpen.value
                                  ? themeColor.withOpacity(0.3)
                                  : themeColor
                              : themeColor.withOpacity(0.3),
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
        ? '${value.substring(0, 4)} ${value.substring(4, value.length)}'
        : value;
  }

  /// body展示 widget
  Widget tabViews(BuildContext context, ChatInfoModel tabOption) {
    switch (tabOption.tabType) {
      case 'media':
        return MediaView(chat: controller.chat.value, isGroup: false);
      case 'file':
        return FileView(chat: controller.chat.value, isGroup: false);
      case 'audio':
        return VoiceView(chat: controller.chat.value, isGroup: false);
      case 'link':
        return LinkView(chat: controller.chat.value, isGroup: false);
      case 'group':
        return GroupView(
          userId: controller.user.value!.uid,
          chat: controller.chat.value,
        );
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
                color: themeColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              controller.selectedMessageList.length.toString(),
              style: TextStyle(
                color: themeColor,
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
                  color: themeColor,
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
                  color: themeColor,
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

  Widget _buildMenuIcon({
    required String imageUrl,
    required String text,
    required bool enableState,
  }) {
    bool isLottie = imageUrl.endsWith(".json");
    if (isLottie) {
      return Lottie.asset(
        key: ValueKey(imageUrl),
        imageUrl,
        width: isDesktop ? 22.w : 22,
        height: isDesktop ? 22.w : 22,
        repeat: false,
      );
    }
    return SvgPicture.asset(
      imageUrl,
      width: isDesktop ? 22.w : 22,
      height: isDesktop ? 22.w : 22,
      color: enableState
          ? controller.isMuteOpen.value || controller.isMoreOpen.value
              ? themeColor.withOpacity(0.3)
              : themeColor
          : themeColor.withOpacity(0.3),
    );
  }

  Widget _buildUserInfo({
    String? title,
    String? infoTxt,
    Color? infoTxtColor,
    Widget? infoWidget,
    Widget? rightWidget,
    bool hasBorder = true,
    void Function()? onTap,
    void Function()? onLongPress,
    double verticalPadding = 8,
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
              color: colorTextPrimary.withOpacity(0.2),
            ),
          ),
        OverlayEffect(
          withEffect: onTap != null,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: verticalPadding, horizontal: 16),
              color: color,
              child: Row(
                children: [
                  Expanded(
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
                            style: jxTextStyle.textStyle17(
                              color: infoTxtColor ?? themeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (infoWidget != null) infoWidget,
                      ],
                    ),
                  ),
                  // const Spacer(),
                  if (rightWidget != null) rightWidget,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showModalBottomSheet(
    BuildContext context, {
    bool isContact = false,
  }) async {
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: isContact ? _contactOptions() : _emailOptions(),
    );
  }

  List<CustomBottomAlertItem> _contactOptions() {
    return [
      CustomBottomAlertItem(
        text: localized(attachmentCallVoice),
        onClick: () => controller.startCall(needModal: false),
      ),
      CustomBottomAlertItem(
        text: localized(attachmentCallVideo),
        onClick: () => controller.startCall(isAudio: false, needModal: false),
      ),
      CustomBottomAlertItem(
        text: localized(callByTelco),
        onClick: () async {
          String mobile =
              "tel:${controller.user.value!.countryCode}${controller.user.value!.contact}";

          Uri callUri = Uri.parse(mobile);
          if (await canLaunchUrl(callUri)) {
            await launchUrl(callUri);
          } else {
            Toast.showToast(localized(invalidPhoneNumber));
          }
        },
      ),
      CustomBottomAlertItem(
        text: localized(copyPhoneNo),
        onClick: () {
          copyToClipboard(
            "${controller.user.value!.countryCode}${controller.user.value!.contact}",
          );
        },
      ),
    ];
  }

  List<CustomBottomAlertItem> _emailOptions() {
    return [
      CustomBottomAlertItem(
        text: localized(sendEmail),
        onClick: () async {
          String email = "mailto:${controller.user.value!.email}";
          Uri emailUri = Uri.parse(email);
          if (await canLaunchUrl(emailUri)) {
            await launchUrl(emailUri);
          } else {
            Toast.showToast(localized(chatInfoPleaseTryAgainLater));
          }
        },
      ),
      CustomBottomAlertItem(
        text: localized(copyEmail),
        onClick: () => copyToClipboard(controller.user.value!.email),
      ),
    ];
  }

  createNewContactView(context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Text(
                        localized(cancel),
                        style: TextStyle(
                          fontSize: MFontSize.size17.value,
                          color: themeColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: controller.user.value?.relationship ==
                      Relationship.stranger,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      localized(createNewContact),
                      textAlign: TextAlign.center,
                      style: jxTextStyle.textStyleBold17(),
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible:
                  controller.user.value?.relationship == Relationship.stranger,
              child: const SizedBox(height: 46),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10000000),
              child: GestureDetector(
                onTap: () {
                  if (!controller.chat.value!.isSpecialChat) {
                    showProfileAvatar(
                      controller.user.value?.uid ?? -1,
                      controller.user.value?.uid ?? 0,
                      false,
                    );
                  }
                },
                child: controller.user.value != null
                    ? Hero(
                        tag: 'avatarHero',
                        child: CustomAvatar.user(
                          controller.user.value!,
                          size: 100,
                          headMin: Config().headMin,
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: NicknameText(
                uid: controller.user.value?.uid ?? -1,
                fontSize: MFontSize.size17.value,
                fontWeight: MFontWeight.bold6.value,
                overflow: TextOverflow.ellipsis,
                isTappable: false,
              ),
            ),
            controller.user.value != null
                ? Center(
                    child: Text(
                      UserUtils.onlineStatus(controller.user.value!.lastOnline),
                      style: jxTextStyle.textStyle13(color: colorTextSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const SizedBox(),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // Username
                  Visibility(
                    visible: controller.user.value?.username != '' &&
                        !controller.isDeletedAccount.value,
                    child: _buildUserInfo(
                      title: localized(contactUsername),
                      infoTxt: !controller.isDeletedAccount.value
                          ? '@${controller.user.value?.username}'
                          : '-',
                      onLongPress: () {
                        if (!controller.isDeletedAccount.value) {
                          copyToClipboard('${controller.user.value?.username}');
                          vibrate();
                        }
                      },
                      hasBorder: false,
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
                      onLongPress: () {
                        if (!controller.isDeletedAccount.value) {
                          copyToClipboard(
                            '${controller.user.value?.countryCode} ${controller.user.value?.contact}',
                          );
                          vibrate();
                        }
                      },
                      hasBorder: true,
                    ),
                  ),
                  // email
                  Visibility(
                    visible: controller.user.value?.email != '',
                    child: _buildUserInfo(
                      title: localized(emailAddress),
                      infoTxt: !controller.isDeletedAccount.value
                          ? controller.user.value?.email
                          : '-',
                      onLongPress: () {
                        if (!controller.isDeletedAccount.value) {
                          copyToClipboard(controller.user.value!.email);
                          vibrate();
                        }
                      },
                      hasBorder: controller.user.value?.username != '' ||
                          controller.user.value?.contact != '',
                    ),
                  ),

                  // Description
                  Visibility(
                    visible: controller.user.value?.profileBio != '',
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
                            textDirection: TextDirection.ltr,
                          );

                          tp.layout(maxWidth: constraints.maxWidth);

                          //get text lines
                          final numLines = tp.computeLineMetrics().length;
                          controller.profileTextNumLines = numLines;

                          return Text(
                            controller.user.value!.profileBio,
                            style: jxTextStyle.textStyle16(),
                          );
                        },
                      ),
                      hasBorder: controller.user.value?.username != '' ||
                          controller.user.value?.contact != '' ||
                          controller.user.value?.email != '',
                    ),
                  ),

                  // Friend Request Remark
                  Obx(() {
                    return Visibility(
                      visible: controller.historyFriendRequestRemark.isNotEmpty,
                      child: Column(
                        children: getFriendRequestRemarks(),
                      ),
                    );
                  }),

                  if (!objectMgr.userMgr.isMe(controller.user.value!.uid) &&
                      !controller.isDeletedAccount.value)
                    _actionButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  getFriendRequestRemarks() {
    List<Widget> children = [];
    for (int i = 0; i < controller.historyFriendRequestRemark.length; i++) {
      var item = controller.historyFriendRequestRemark[i];
      children.add(
        _buildUserInfo(
          title: localized(sendFriendReqButton),
          infoWidget: LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                text: item['isSent']
                    ? localized(myRemarks, params: [item['remark']])
                    : localized(opponentRemarks, params: [item['remark']]),
                style: jxTextStyle.textStyle16(),
              );

              final tp =
                  TextPainter(text: span, textDirection: TextDirection.ltr);

              tp.layout(maxWidth: constraints.maxWidth);

              //get text lines
              final numLines = tp.computeLineMetrics().length;
              controller.profileTextNumLines = numLines;

              return Text(
                item['isSent']
                    ? localized(myRemarks, params: [item['remark']])
                    : localized(opponentRemarks, params: [item['remark']]),
                style: jxTextStyle.textStyle17(),
              );
            },
          ),
        ),
      );
    }

    return children;
  }

  Widget _buildEncryptionTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          builder: (BuildContext context) {
            // Get.put(GroupInviteLinkController());
            return ChatEncryptionBottomSheet(chat:controller.chat.value!, qrCode: controller.signatureBase64.value ?? "", signatureText: controller.signatureString.value ?? "");
          },
        );
        // .then((_) => Get.delete<GroupInviteLinkController>());
        // controller.updateGroupChatDescExpanded(
        //   !controller.isGroupChatDescExpanded.value,
        // );
      },
      child: OverlayEffect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: isDesktop ? 16 : 16.w, bottom: 12),
              child: Container(
                height: 0.33,
                color: colorTextPrimary.withOpacity(0.2),
              ),
            ),
            //取得簡介文字行數
            Padding(
                padding: EdgeInsets.only(left: isDesktop ? 16 : 16.w, right: isDesktop ? 16 : 16.w, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localized(settingEncryptedConversation),
                      style: jxTextStyle.textStyle17(),
                    ),
                    Row(
                      children: [
                        QRCode(
                          qrData:
                          controller.signatureBase64.value ?? "",
                          qrSize: 24,
                          roundEdges: false,
                          color: colorQrCode,
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/svgs/right_arrow_thick.svg',
                          color: colorTextSupporting,
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                              colorTextPrimary.withOpacity(0.2), BlendMode.srcIn),
                        ),
                      ],
                    )
                  ],
                ),
            ),
          ],
        )
      ),
    );
  }

  Widget buildSpecialChatIcon() {
    Widget widget = const SizedBox();
    if (controller.chat.value != null) {
      if (controller.chat.value!.isSecretary) {
        widget = const SecretaryMessageIcon(size: 100);
      } else if (controller.chat.value!.isSystem) {
        widget = const SystemMessageIcon(size: 100);
      } else if (controller.chat.value!.isSaveMsg) {
        widget = const SavedMessageIcon(size: 100);
      }
    }
    return widget;
  }

  ChatInfoNicknameText buildNickname(bool isEncrypted) {
    bool showIcon = false;
    if (controller.isSpecialChat.value) {
      showIcon = true;
    }
    return ChatInfoNicknameText(
        uid: controller.user.value?.uid ?? -1,
        chatType: controller.chat.value?.typ,
        size: MFontSize.size17.value,
        showIcon: showIcon,
        showEncrypted: isEncrypted,
    );
  }

  String buildDescription() {
    String text = objectMgr
            .onlineMgr.friendOnlineString[controller.chat.value?.friend_id] ??
        '';

    if (controller.chat.value != null) {
      if (controller.chat.value != null &&
          (controller.chat.value!.isSecretary ||
              controller.chat.value!.isSystem ||
              controller.chat.value!.isSaveMsg)) {
        text = localized(officialAccount);
      }
    }
    return text;
  }

  Widget buildFeature(BuildContext context) {
    if (controller.isSpecialChat.value) {
      String text = "";
      if (controller.chat.value!.isSecretary) {
        text = localized(smallSecretaryDescription);
      } else if (controller.chat.value!.isSystem) {
        text = localized(systemMessageDescription, params: [Config().appName]);
      } else if (controller.chat.value!.isSaveMsg) {
        text = localized(saveMessageDescription);
      }
      return Container(
        key: controller.childKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 0).w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Expanded(
                      child: GestureDetector(
                        key: controller.notificationKey,
                        onTap: () => controller.onNotificationTap(context),
                        child: toolButton(
                          controller.getMuteIcon(),
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
                      onTap: () => controller.onChatTap(
                        context,
                        searching: true,
                      ),
                      child: toolButton(
                        'assets/svgs/chat_info_item_search.svg',
                        localized(search),
                        true,
                        false,
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
                        true,
                        false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localized(description),
                    style: jxTextStyle.textStyle14(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: jxTextStyle.textStyle16(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        key: controller.childKey,
        child: Column(
          children: [
            Visibility(
              visible: ((controller.user.value?.relationship ==
                          Relationship.friend ||
                      controller.user.value?.relationship ==
                          Relationship.blocked ||
                      controller.user.value?.relationship ==
                          Relationship.blockByTarget) &&
                  !objectMgr.userMgr.isMe(controller.user.value?.uid ?? 0) &&
                  !controller.isDeletedAccount.value),
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 0).w,
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
                          false,
                          // controller.onCallPressed.value &&
                          //     controller.callingAudio.value,
                        ),
                      ),
                    ),
                    ImGap.hGap8,
                    // 設定靜音
                    Obx(
                      () => Expanded(
                        child: GestureDetector(
                          key: controller.notificationKey,
                          onTap: () => controller.onNotificationTap(context),
                          child: toolButton(
                            controller.getMuteIcon(),
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
                        onTap: () => controller.onChatTap(
                          context,
                          searching: true,
                        ),
                        child: toolButton(
                          'assets/svgs/chat_info_item_search.svg',
                          localized(search),
                          controller.ableCall.value,
                          false,
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
                                controller.user.value?.uid ?? 0,
                              )),
                          false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(top: 24),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // Username
                  Visibility(
                    visible: controller.user.value?.username != '' &&
                        !controller.isDeletedAccount.value,
                    child: _buildUserInfo(
                      title: localized(contactUsername),
                      infoTxt: !controller.isDeletedAccount.value
                          ? '@${controller.user.value?.username}'
                          : '-',
                      onTap: () {
                        if (controller.user.value?.relationship ==
                            Relationship.friend) {
                          _showRecommendFriendDrawer(context);
                        }
                      },
                      onLongPress: () {
                        if (!controller.isDeletedAccount.value) {
                          copyToClipboard(
                            '${controller.user.value?.username}',
                          );
                          vibrate();
                        }
                      },
                      rightWidget: Visibility(
                        visible: !controller.isDeletedAccount.value &&
                            (controller.user.value?.relationship ==
                                    Relationship.friend ||
                                controller.user.value?.relationship ==
                                    Relationship.self),
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTap: () {
                            showQRCodeDialog(
                              context,
                              user: controller.user.value,
                              isFriend: true,
                            );
                          },
                          child: SvgPicture.asset(
                            'assets/svgs/qrCode.svg',
                            width: 28, //4 is from padding
                            height: 28,
                            colorFilter: ColorFilter.mode(
                              themeColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      hasBorder: false,
                    ),
                  ),
                  // Phone number
                  Visibility(
                    visible: controller.user.value?.contact != '',
                    child: _buildUserInfo(
                      title: localized(psPhoneNumber),
                      infoTxt: !controller.isDeletedAccount.value
                          ? '${controller.user.value?.countryCode} ${formatNumber(controller.user.value?.contact ?? "")}'
                          : '-',
                      onTap: () {
                        if (controller.user.value?.relationship ==
                            Relationship.friend) {
                          _showModalBottomSheet(
                            context,
                            isContact: true,
                          );
                        }
                      },
                      onLongPress: () {
                        if (!controller.isDeletedAccount.value) {
                          copyToClipboard(
                            '${controller.user.value?.countryCode} ${controller.user.value?.contact}',
                          );
                          vibrate();
                        }
                      },
                      hasBorder: true,
                    ),
                  ),
                  // email
                  Visibility(
                    visible: controller.user.value?.email != '',
                    child: _buildUserInfo(
                      title: localized(emailAddress),
                      infoTxt: !controller.isDeletedAccount.value
                          ? controller.user.value?.email
                          : '-',
                      onTap: () {
                        if (controller.user.value?.relationship ==
                            Relationship.friend) {
                          _showModalBottomSheet(context);
                        }
                      },
                      onLongPress: () {
                        if (!controller.isDeletedAccount.value) {
                          copyToClipboard(
                            controller.user.value!.email,
                          );
                          vibrate();
                        }
                      },
                      hasBorder: controller.user.value?.username != '' ||
                          controller.user.value?.contact != '',
                    ),
                  ),

                  // Description
                  Visibility(
                    visible: controller.user.value?.profileBio != '',
                    child: _buildUserInfo(
                      title: localized(description),
                      infoWidget: LayoutBuilder(
                        builder: (context, constraints) {
                          //取得簡介文字行數

                          final span = TextSpan(
                            text: controller.user.value?.profileBio ?? '',
                            style: jxTextStyle.textStyle16(),
                          );

                          final tp = TextPainter(
                            text: span,
                            textDirection: TextDirection.ltr,
                          );

                          tp.layout(
                            maxWidth: constraints.maxWidth,
                          );

                          //get text lines
                          final numLines = tp.computeLineMetrics().length;
                          controller.profileTextNumLines = numLines;

                          return Text(
                            controller.user.value?.profileBio ?? '',
                            style: jxTextStyle.textStyle16(),
                          );
                        },
                      ),
                      hasBorder: controller.user.value?.username != '' ||
                          controller.user.value?.contact != '' ||
                          controller.user.value?.email != '',
                    ),
                  ),

                  // Friend Request Remark
                  Obx(() {
                    return Visibility(
                      visible: controller.historyFriendRequestRemark.isNotEmpty,
                      child: Column(
                        children: getFriendRequestRemarks(),
                      ),
                    );
                  }),

                  Obx(() {
                    return Visibility(
                      visible: controller.isEncrypted.value,
                      child: _buildEncryptionTile(context),
                    );
                  }),

                  if (!objectMgr.userMgr
                          .isMe(controller.user.value?.uid ?? 0) &&
                      !controller.isDeletedAccount.value)
                    _actionButton(context),
                ],
              ),
            ),
            if (controller.user.value?.relationship == Relationship.blocked)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: 3.15,
                      child: const Icon(
                        Icons.info_outline,
                        size: 24,
                        color: colorRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        localized(youHaveBlockedUser),
                        style: jxTextStyle.textStyle15(),
                        softWrap: true,
                        maxLines: null,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }
}
