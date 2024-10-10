import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_content/red_packet/red_packet_leaderboard_controller.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class RedPacketLeaderboard extends GetView<RedPacketLeaderboardController> {
  const RedPacketLeaderboard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.arguments['toast_function'] != null) {
        Get.arguments['toast_function']();
      }
    });

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: controller.messageRed!.rpType.name.redPacketName,
      ),
      body: Obx(
        () => controller.isLoading.value
            ? Center(child: CircularProgressIndicator(color: themeColor))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    CustomAvatar.normal(
                      controller.redPacketData.value.userID ?? 0,
                      size: 60,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        NicknameText(
                          isTappable: false,
                          uid: controller.redPacketData.value.userID ?? 0,
                          fontWeight: MFontWeight.bold5.value,
                          fontSize: MFontSize.size17.value,
                          fontLineHeight: 1.3,
                          overflow: TextOverflow.ellipsis,
                          groupId: controller.chat != null
                              ? controller.chat!.isGroup
                                  ? controller.chat!.chat_id
                                  : null
                              : null,
                        ),
                        Text(
                          ' ${localized(redEnvelopesSent).toLowerCase()}',
                          style: jxTextStyle.textStyleBold17(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ' ${controller.messageRed!.remark}',
                      style: jxTextStyle.textStyle12(color: colorTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (controller.isMeRedPacketAmountClaimed.isNotEmpty &&
                        controller.redPacketStatus == rpReceived)
                      RichText(
                        text: TextSpan(
                          text: double.parse(
                                  controller.isMeRedPacketAmountClaimed)
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: MFontWeight.bold5.value,
                            color: colorPrimaryYellow,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${controller.redPacketData.value.currencyType}',
                              style:
                                  TextStyle(fontSize: MFontSize.size12.value),
                            ),
                          ],
                        ),
                      ),
                    if (controller.redPacketStatus == rpReceived)
                      GestureDetector(
                        onTap: () async => Get.toNamed(RouteName.walletView),
                        child: OpacityEffect(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  localized(redPacketDepositedIntoMyWallet),
                                  style: jxTextStyle.textStyle14(
                                      color: colorPrimaryYellow),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: colorPrimaryYellow,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              '${localized(redPacketClaimed)}${controller.redPacketData.value.receiveNum}/'
                              '${controller.redPacketData.value.totalNum}${localized(redPacketUnit)}，${localized(redPacketTotal)}'
                              '${controller.redPacketData.value.receiveAmt != '0.00' ? '${controller.redPacketData.value.receiveAmt}/' : ''}'
                              '${controller.redPacketData.value.totalAmt} ${controller.redPacketData.value.currencyType}',
                              style: jxTextStyle.textStyle14(
                                  color: colorTextSecondary),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              child: CustomRoundContainer(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: controller.leaderBoardList.length,
                                  itemBuilder: (_, int index) {
                                    User user =
                                        controller.leaderBoardList[index];
                                    ReceiveInfo? info = controller
                                        .redPacketData.value.receiveInfos
                                        .firstWhereOrNull((element) =>
                                            element.userId == user.uid);

                                    return _buildInfoItem(info, index);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 16,
                        bottom: 16 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Text(
                        localized(redPacketUnclaimed24HrRefund),
                        textAlign: TextAlign.center,
                        style:
                            jxTextStyle.textStyle14(color: colorTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
      ),

      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF613200)),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      //   title: Obx(
      //     () => Text(
      //       controller.messageRed!.rpType.name.redPacketName,
      //       style: TextStyle(
      //         color: controller.redPacketData.value.rpType.titleColor,
      //         fontSize: 18.0,
      //         fontWeight: MFontWeight.bold5.value,
      //       ),
      //     ),
      //   ),
      //   centerTitle: true,
      //   elevation: 0.0,
      // ),
      // body: Container(
      //   margin: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
      //   child: Stack(
      //     children: <Widget>[
      //       Positioned(
      //         top: 0.0,
      //         left: 0.0,
      //         right: 0.0,
      //         child: Image.asset(
      //           'assets/images/red_packet/${controller.redPacketBackground}.png',
      //           fit: BoxFit.fitWidth,
      //         ),
      //       ),
      //       Positioned(
      //         bottom: 0.0,
      //         top: 0.0,
      //         left: 0.0,
      //         right: 0.0,
      //         child: DraggableScrollableSheet(
      //           initialChildSize: 0.75,
      //           maxChildSize: 0.92,
      //           minChildSize: 0.75,
      //           builder:
      //               (BuildContext context, ScrollController scrollController) {
      //             return Container(
      //               decoration: const BoxDecoration(
      //                 color: Colors.white,
      //                 borderRadius: BorderRadius.only(
      //                   topLeft: Radius.circular(20.0),
      //                   topRight: Radius.circular(20.0),
      //                 ),
      //               ),
      //               child: Column(
      //                 children: [
      //                   TabBar(
      //                     controller: controller.tabController,
      //                     indicatorColor: const Color(0xFF613200),
      //                     labelStyle: const TextStyle(color: Color(0xFF613200)),
      //                     unselectedLabelStyle: const TextStyle(color: colorTextSecondary),
      //                     tabs: <Widget>[
      //                       Tab(
      //                         child: Text(
      //                           localized(leaderboard),
      //                         ),
      //                       ),
      //                       Tab(
      //                         child: Text(
      //                           localized(details),
      //                         ),
      //                       ),
      //                     ],
      //                   ),
      //                   Expanded(
      //                     child: Padding(
      //                       padding: const EdgeInsets.all(10.0),
      //                       child: Obx(
      //                         () => controller.isLoading.value
      //                             ? const Center(
      //                                 child: CircularProgressIndicator(
      //                                   color: colorWhite,
      //                                 ),
      //                               )
      //                             : TabBarView(
      //                                 controller: controller.tabController,
      //                                 children: [
      //                                   if (controller.leaderBoardList.length ==
      //                                           0 &&
      //                                       !connectivityMgr.hasNetwork())
      //                                     Center(
      //                                       child: OfflineState(
      //                                         onTap: controller.getRpDetail,
      //                                       ),
      //                                     )
      //                                   else
      //                                     ListView.builder(
      //                                       controller: scrollController,
      //                                       padding: EdgeInsets.zero,
      //                                       itemCount: controller
      //                                           .leaderBoardList.length,
      //                                       itemBuilder:
      //                                           (BuildContext _, int index) {
      //                                         User user = controller
      //                                             .leaderBoardList[index];
      //                                         ReceiveInfo? info = controller
      //                                             .redPacketData
      //                                             .value
      //                                             .receiveInfos
      //                                             .firstWhereOrNull((element) =>
      //                                                 element.userId ==
      //                                                 user.uid);
      //                                         return infoItem(info, index);
      //                                       },
      //                                     ),
      //                                   SingleChildScrollView(
      //                                     controller: scrollController,
      //                                     child: RedPacketDetailView(
      //                                       controller: controller,
      //                                     ),
      //                                   ),
      //                                 ],
      //                               ),
      //                       ),
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             );
      //           },
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildInfoItem(ReceiveInfo? info, int index) {
    int userId = controller.leaderBoardList[index].uid;
    int receiveTime = controller.userReceiveTime[userId]!;
    String dateTime = FormatTime.getTime(receiveTime ~/ 1000);

    return SizedBox(
      height: 56,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: CustomAvatar.user(
              controller.leaderBoardList[index],
              size: 40.0,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(right: 16.0),
              decoration: BoxDecoration(
                border: controller.leaderBoardList.length - 1 == index
                    ? null
                    : customBorder,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        objectMgr.userMgr.isMe(userId)
                            ? Text(
                                localized(chatInfoYou),
                                style: jxTextStyle.textStyle17(),
                              )
                            : NicknameText(
                                uid: userId,
                                isTappable: false,
                                fontSize: MFontSize.size17.value,
                                overflow: TextOverflow.ellipsis,
                                groupId: controller.chat != null
                                    ? controller.chat!.isGroup
                                        ? controller.chat!.chat_id
                                        : null
                                    : null,
                              ),
                        if (controller.userReceiveTime.containsKey(userId) &&
                            controller.userReceiveTime[userId]! > 0)
                          Text(
                            dateTime,
                            style: jxTextStyle.textStyle12(
                                color: colorTextSecondary),

                            // TextStyle(
                            //   color: (controller.redPacketData.value.rpType ==
                            //                   RedPacketType.luckyRedPacket &&
                            //               index == 0) ||
                            //           index == 0
                            //       ? Colors.white
                            //       : colorTextSecondary,
                            //   fontSize: 12,
                            // ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  if (info != null && info.receiveFlag!)
                    Text(
                      double.parse(info.amount ?? '0').toStringAsFixed(2),
                      style: jxTextStyle.textStyle17(color: colorTextSecondary),
                    )
                  else
                    Center(
                      child: Text(
                        localized(unclaimed),
                        style: const TextStyle(
                          color: Colors.black,
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

class RedPacketDetailView extends StatelessWidget {
  final RedPacketLeaderboardController controller;

  const RedPacketDetailView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    bool redPacketStatus = true;

    if (controller.redPacketStatus == rpExpired ||
        controller.messageRed!.expireTime <
            DateTime.now().millisecondsSinceEpoch) {
      redPacketStatus = false;
    }

    if (redPacketStatus) {
      if (controller.redPacketData.value.receiveNum ==
          controller.redPacketData.value.totalNum) {
        redPacketStatus = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localized(RedPacketStatusTitle),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            redPacketStatus ? localized(walletOutgoing) : localized(ended),
            style: TextStyle(
              color: redPacketStatus ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25.0),
          Text(
            localized(validTill),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            FormatTime.getTime(
              controller.messageRed!.expireTime ~/ 1000,
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25.0),
          Text(
            localized(redPacketClaimedTotalRedPackets),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            '${controller.redPacketData.value.receiveNum} / ${controller.redPacketData.value.totalNum}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25.0),
          Text(
            localized(amountClaimedTotalAmount),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            '${controller.redPacketData.value.receiveAmt} / ${controller.redPacketData.value.totalAmt} ${controller.redPacketData.value.currencyType}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25.0),
          Text(
            localized(sender),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 5.0),
          NicknameText(
            isTappable: false,
            uid: controller.redPacketData.value.userID ?? 0,
            fontWeight: FontWeight.bold,
            groupId: controller.chat != null
                ? controller.chat!.isGroup
                    ? controller.chat!.chat_id
                    : null
                : null,
          ),
          const SizedBox(height: 25.0),
          Text(
            localized(comments),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            controller.messageRed!.remark.isEmpty
                ? '-'
                : controller.messageRed!.remark,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25.0),
        ],
      ),
    );
  }
}
