import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';

class RedPacketLeaderboardController extends GetxController
    with GetTickerProviderStateMixin {
  // ================================ VARIABLES ================================
  Color? redPacketColor;
  String? redPacketBackground;

  // 显示自己时候的 背景颜色
  List<Color>? leaderBoardSelfGradient;
  Rx<RedPacketDetail> redPacketData = RedPacketDetail().obs;
  MessageRed? messageRed;
  int redPacketStatus = 0;

  TabController? tabController;
  final RxBool isLoading = true.obs;
  RxMap<int, int> userReceiveTime = <int, int>{}.obs;
  RxList<User> leaderBoardList = <User>[].obs;

  // ================================= METHODS =================================
  @override
  void onInit() {
    super.onInit();

    tabController = TabController(length: 2, vsync: this);

    final arguments = Get.arguments as Map<String, dynamic>;
    redPacketColor = arguments['redPacketColor'];
    redPacketBackground = arguments['redPacketBackground'];
    leaderBoardSelfGradient = arguments['leaderBoardSelfGradient'];
    messageRed = arguments['messageRed'];
    redPacketStatus = arguments['redPacketStatus'];

    getRpDetail();
  }

  @override
  void onClose() {
    tabController?.dispose();
    super.onClose();
  }

  void getRpDetail() async {
    try {
      final RedPacketDetail detail =
          await walletServices.getRedPacket(rpID: messageRed!.id);
      redPacketData.update((data) {
        data!.conversionCurrency = detail.conversionCurrency;
        data.convertedAmt = detail.convertedAmt;
        data.currencyType = detail.currencyType;
        data.receiveAmt = detail.receiveAmt;
        data.receiveInfos = detail.receiveInfos;
        data.receiveNum = detail.receiveNum;
        data.rpType = detail.rpType;
        data.totalAmt = detail.totalAmt;
        data.totalNum = detail.totalNum;
        data.userID = detail.userID;
      });
      sortLeaderboard();
    } finally {
      isLoading.value = false;
    }
  }

  sortLeaderboard() async {
    leaderBoardList.clear();
    if (RedPacketType.normalRedPacket == redPacketData.value.rpType) {
      List<User> recipientUsers = [];
      if (redPacketData.value.receiveInfos.isNotEmpty) {
        List<ReceiveInfo> tempReceiveList = redPacketData.value.receiveInfos
            .where((e) => e.receiveFlag == true)
            .toList();
        tempReceiveList
            .sort((a, b) => a.receiveTime!.compareTo(b.receiveTime!));
        for (ReceiveInfo info in tempReceiveList) {
          if (info.receiveTime != null) {
            userReceiveTime[info.userId!] = info.receiveTime!;
          }

          User? user = await objectMgr.userMgr.loadUserById(info.userId!);
          if (user != null) {
            recipientUsers.add(user);
          }
        }

        final User? user = recipientUsers.firstWhereOrNull(
            (element) => element.uid == objectMgr.userMgr.mainUser.uid);

        if (user != null) {
          leaderBoardList.add(objectMgr.userMgr.mainUser);
          recipientUsers.remove(user);
        }

        leaderBoardList.addAll(recipientUsers);
      }
    } else if (RedPacketType.luckyRedPacket == redPacketData.value.rpType) {
      List<User> recipientUsers = [];
      if (redPacketData.value.receiveInfos.isNotEmpty) {
        List<ReceiveInfo> tempReceiveList = redPacketData.value.receiveInfos
            .where((e) => e.receiveFlag == true)
            .toList();

        tempReceiveList.sort((a, b) =>
            double.parse(b.amount!).compareTo(double.parse(a.amount!)));
        for (ReceiveInfo info in tempReceiveList) {
          if (info.receiveTime != null) {
            userReceiveTime[info.userId!] = info.receiveTime!;
          }
          User? user = await objectMgr.userMgr.loadUserById(info.userId!);
          if (user != null) {
            recipientUsers.add(user);
          }
        }

        leaderBoardList.addAll(recipientUsers);
      }
    } else {
      if (redPacketData.value.receiveInfos.isNotEmpty) {
        List<User> recipientUsers = [];
        for (ReceiveInfo info in redPacketData.value.receiveInfos) {
          if (info.receiveTime != null) {
            userReceiveTime[info.userId!] = info.receiveTime!;
          }
          User? user = await objectMgr.userMgr.loadUserById(info.userId!);
          if (user != null) {
            recipientUsers.add(user);
          }
        }

        List<ReceiveInfo> tempReceiveList = redPacketData.value.receiveInfos
            .where((e) => e.receiveFlag == true)
            .toList();

        final User? user = recipientUsers.firstWhereOrNull(
            (element) => element.uid == objectMgr.userMgr.mainUser.uid);

        if (user != null) {
          leaderBoardList.add(objectMgr.userMgr.mainUser);
          recipientUsers.remove(user);
        }

        tempReceiveList.sort((a, b) =>
            double.parse(a.amount!).compareTo(double.parse(b.amount!)));

        List<int> receivedUserIds =
            tempReceiveList.map<int>((e) => e.userId!).toList();
        leaderBoardList.addAll(recipientUsers
            .where((element) => receivedUserIds.contains(element.uid)));

        recipientUsers
            .removeWhere((element) => receivedUserIds.contains(element.uid));
        recipientUsers.sort((a, b) {
          if (a.alias.isNotEmpty && b.alias.isNotEmpty) {
            return a.alias.compareTo(b.alias);
          } else if (a.alias.isNotEmpty) {
            return a.alias.compareTo(b.nickname);
          } else if (b.alias.isNotEmpty) {
            return a.nickname.compareTo(b.alias);
          } else {
            return a.nickname.compareTo(b.nickname);
          }
        });

        leaderBoardList.addAll(recipientUsers);
      }
    }

    isLoading.value = false;
  }
}
