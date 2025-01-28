import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/red_packet/red_packet_leaderboard_controller.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/offline_state.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import '../../../utils/theme/text_styles.dart';

class RedPacketLeaderboard extends GetView<RedPacketLeaderboardController> {
  const RedPacketLeaderboard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: controller.redPacketColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF613200)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Obx(
          () => Text(
            controller.messageRed!.rpType.name.redPacketName,
            style: TextStyle(
              color: controller.redPacketData.value.rpType.titleColor,
              fontSize: 18.0,
              fontWeight: MFontWeight.bold5.value,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: Image.asset(
                'assets/images/red_packet/${controller.redPacketBackground}.png',
                fit: BoxFit.fitWidth,
              ),
            ),
            Positioned(
              bottom: 0.0,
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: DraggableScrollableSheet(
                initialChildSize: 0.75,
                maxChildSize: 0.92,
                minChildSize: 0.75,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: controller.tabController,
                          indicatorColor: const Color(0xFF613200),
                          labelStyle: const TextStyle(color: Color(0xFF613200)),
                          unselectedLabelStyle: TextStyle(color: systemColor),
                          tabs: <Widget>[
                            Tab(
                              child: Text(
                                localized(leaderboard),
                              ),
                            ),
                            Tab(
                              child: Text(
                                localized(details),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Obx(
                              () => controller.isLoading.value
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                      ),
                                    )
                                  : TabBarView(
                                      controller: controller.tabController,
                                      children: [
                                        if (controller.leaderBoardList.length ==
                                                0 &&
                                            !connectivityMgr.hasNetwork())
                                          Center(
                                            child: OfflineState(
                                              onTap: controller.getRpDetail,
                                            ),
                                          )
                                        else
                                          ListView.builder(
                                            controller: scrollController,
                                            padding: EdgeInsets.zero,
                                            itemCount: controller
                                                .leaderBoardList.length,
                                            itemBuilder:
                                                (BuildContext _, int index) {
                                              User user = controller
                                                  .leaderBoardList[index];
                                              ReceiveInfo? info = controller
                                                  .redPacketData
                                                  .value
                                                  .receiveInfos
                                                  .firstWhereOrNull((element) =>
                                                      element.userId ==
                                                      user.uid);
                                              return infoItem(info, index);
                                            },
                                          ),
                                        SingleChildScrollView(
                                          controller: scrollController,
                                          child: RedPacketDetailView(
                                            controller: controller,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoItem(ReceiveInfo? info, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: index > 0 &&
                controller.leaderBoardList[index].uid ==
                    objectMgr.userMgr.mainUser.uid &&
                controller.redPacketData.value.rpType ==
                    RedPacketType.luckyRedPacket
            ? systemColor.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(12.0),
        gradient: index == 0
            ? LinearGradient(
                colors: controller.leaderBoardSelfGradient!,
                stops: const [0.0, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          CustomAvatar(uid: controller.leaderBoardList[index].uid, size: 40.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  objectMgr.userMgr.isMe(controller.leaderBoardList[index].uid)
                      ? Text(
                          localized(chatInfoYou),
                          style: TextStyle(
                            color: (objectMgr.userMgr.isMe(controller
                                            .leaderBoardList[index].uid) &&
                                        controller.redPacketData.value.rpType !=
                                            RedPacketType.luckyRedPacket) ||
                                    (controller.redPacketData.value.rpType ==
                                            RedPacketType.luckyRedPacket &&
                                        index == 0)
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16.0,
                          ),
                        )
                      : NicknameText(
                          uid: controller.leaderBoardList[index].uid,
                          color: index == 0 ? Colors.white : Colors.black,
                          isTappable: false,
                          fontSize: 16.0,
                        ),
                  if (controller.userReceiveTime
                          .containsKey(controller.leaderBoardList[index].uid) &&
                      controller.userReceiveTime[
                              controller.leaderBoardList[index].uid]! >
                          0)
                    Text(
                      FormatTime.getTime(controller.userReceiveTime[
                              controller.leaderBoardList[index].uid]! ~/
                          1000),
                      style: TextStyle(
                        color: (controller.redPacketData.value.rpType ==
                                        RedPacketType.luckyRedPacket &&
                                    index == 0) ||
                                index == 0
                            ? Colors.white
                            : JXColors.secondaryTextBlack,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (info != null && info.receiveFlag!)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${info.amount} ${controller.redPacketData.value.currencyType}',
                  style: TextStyle(
                    color: (controller.redPacketData.value.rpType ==
                                    RedPacketType.luckyRedPacket &&
                                index == 0) ||
                            index == 0
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                Text(
                  '${info.convertedAmount} ${controller.redPacketData.value.conversionCurrency}',
                  style: TextStyle(
                    color: (controller.redPacketData.value.rpType ==
                                    RedPacketType.luckyRedPacket &&
                                index == 0) ||
                            index == 0
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            )
          else
            Center(
              child: Text(
                localized(unclaimed),
                style: TextStyle(
                  color: objectMgr.userMgr
                          .isMe(controller.leaderBoardList[index].uid)
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            )
        ],
      ),
    );
  }
}

class RedPacketDetailView extends StatelessWidget {
  final RedPacketLeaderboardController controller;

  const RedPacketDetailView({
    Key? key,
    required this.controller,
  }) : super(key: key);

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
