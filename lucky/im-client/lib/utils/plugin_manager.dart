import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:im/widget/bet_panel/bet_coin.dart';
import 'package:im/widget/bet_panel/bet_game_tabs.dart';
import 'package:im/widget/record/bet_record_listview.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/second_verification_utils.dart';

import '../api/wallet_services.dart';
import '../main.dart';
import '../network/dun_mgr.dart';
import '../object/user.dart';
import '../object/wallet/currency_model.dart';
import '../object/wallet/wallet_assets_model.dart';
import '../reel/reel_group_vip_demo_video_page.dart';
import '../reel/reel_page/reel_controller.dart';
import '../routes.dart';
import '../views/wallet/controller/wallet_controller.dart';

class PluginManager {
  static final PluginManager _shared = PluginManager._internal();

  static PluginManager get shared {
    return _shared;
  }

  PluginManager._internal();

  void init() {
    GameManager.shared.imInit();
    imMiniAppManager.miniAppInit();
    imMiniAppManager.goToCryptoPage = (String? currencyType) {
      WalletController controller;
      if (!Get.isRegistered<WalletController>()) {
        controller = Get.put(WalletController());
      } else {
        controller = Get.find<WalletController>();
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        List<CurrencyModel> list = controller.cryptoCurrencyList;
        for (int i = 0; i < list.length; i++) {
          CurrencyModel model = list[i];
          if (currencyType == model.currencyType) {
            controller.tabController.index = i;
            controller.selectedTabCurrency = model;
            controller.selectedTabCurrency.netType =
                model.supportNetType!.first;
            Get.toNamed(RouteName.cryptoView);
            break;
          }
        }
      });
    };
    imMiniAppManager.getUserBalance = () async {
      WalletServices walletServices = WalletServices();
      final WalletAssetsModel? data = await walletServices.getUserAssets();
      imMiniAppManager.walletAssetsModel = data;

      return {
        'balance': data?.totalAmt ?? 0,
        'currency': data?.totalAmtCurrencyType ?? ''
      };
    };
    imMiniAppManager.userBalanceForCurrency = (String currency) {
      double balance = 0;
      WalletAssetsModel? data = imMiniAppManager.walletAssetsModel;
      if (data != null) {
        data.cryptoCurrencyInfo?.forEach((element) {
          if (element.currencyType == currency) {
            balance = element.amount ?? 0;
          }
        });
        data.legalCurrencyInfo?.forEach((element) {
          if (element.currencyType == currency) {
            balance = element.amount ?? 0;
          }
        });
      }
      return balance;
    };
    imMiniAppManager.getVideoThumbWidgetForBecomeBanker = (BuildContext context, String videoPath) {
      return Stack(
        children: [
          Container(),
          Center(
            child: GestureDetector(onTap: (){
              Get.put(ReelController());
              ReelController controller = Get.find<ReelController>();
              controller.precacheVideo(videoPath);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => ReelGroupVipDemoVideoPage(videoPath: videoPath)));
            },
              child: SvgPicture.asset(
                'assets/svgs/group_vip_demo_play.svg',
                width: 38,
                height: 38,
              ),),
          ),
        ],
      );
      // Get.put(ReelController());
      // ReelController controller = Get.find<ReelController>();
      // return Stack(
      //   children: [
      //     Obx(() {
      //       if (controller.postList.isEmpty) {
      //         return Container();
      //       } else {
      //         ReelData reelData = controller.postList[0];
      //         return RemoteImage(
      //           src: reelData.post!.thumbnail!,
      //           width: double.infinity,
      //           height: double.infinity,
      //           fit: BoxFit.cover);
      //         return ReelVideo.file(
      //           source: reelData.post!.files![0].path!,
      //           thumbnail: reelData.post!.thumbnail!,
      //           index: 0,
      //           isLoop: true,
      //         );
      //       }
      //     }),
      //     Center(
      //       child: GestureDetector(onTap: (){
      //         //then里面用来处理 pop回来后 刷新页面
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (BuildContext context) => const ReelGroupVipDemoVideoPage()));
      //       },
      //       child: SvgPicture.asset(
      //         'assets/svgs/group_vip_demo_play.svg',
      //         width: 38,
      //         height: 38,
      //       ),),
      //     ),
      //   ],
      // );
    };
    imGetUserName = (int uid, {int? inGid}) async {
      //如果在群组内 尝试从群组的群成员列表来获取群成员名称
      final User? user = await objectMgr.userMgr.loadUserById2(uid);
      return user?.nickname ?? '';
    };
    sharedDataManager.onTryDun = (Uri? uri) async {
      Uri? u= await dunMgr.serverToLocal(uri!);
      return u!;
    };


    bettingRecordListPageFromMiniAppPlugin = () {
      return BettingRecordList(
        currentGameId: GameManager.shared.currentGameId,
        currentGameName: GameManager.shared.currentGameName,
      );
    };

    imMiniAppManager.checkWalletPswBeforeOpenWalletPage =
        (context) async {
      bool status = await checkPasscodeStatus();
      if (status) {
        Get.toNamed(RouteName.walletView);
      } else {
        Get.toNamed(
          RouteName.passcodeIntroSetting,
          arguments: {
            'passcode_type': WalletPasscodeOption.setPasscode.type,
            'from_view': 'wallet_view',
          },
        );
      }
    };

    onTapToMyWalletPage = (context) => imMiniAppManager
        .checkWalletPswBeforeOpenWalletPage(context);
    onTapToLeagueGamePage = (context, String gameId) => imMiniAppManager
        .goToLeagueGamePage(context, gameId);
    twoTimesVerification();
  }

  Future<bool> checkPasscodeStatus() async {
    bool? passwordStatus =
        await objectMgr.localStorageMgr.read(LocalStorageMgr.SET_PASSWORD);
    if (passwordStatus != null) {
      return passwordStatus;
    } else {
      Secure? data = await SettingServices().getPasscodeSetting();
      if (data != null) {
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.SET_PASSWORD, !data.isNoPassword);
        return !data.isNoPassword;
      }
    }
    return false;
  }

  /// 設置是否為群主或管理員
  Function onSetGroupOwnerAdmin = (bool isAdmin) {};

  ///二次验证回调
  void twoTimesVerification() {
    imMiniAppManager.twoTimesVerification = ({required bool phoneAuth , required bool emailAuth}) async {
    return await goSecondVerification(phoneAuth: phoneAuth, emailAuth: emailAuth);
    };
  }
}
