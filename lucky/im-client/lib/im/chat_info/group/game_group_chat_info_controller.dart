
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';

import '../../../main.dart';
import '../../../object/chat_info_model.dart';
import '../../../object/enums/enum.dart';
import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';
import '../../../utils/toast.dart';
import '../../model/group/group.dart';
import '../more_vert/more_vert_view.dart';
import '../tool_option_model.dart';

abstract class GameGroupChatInfoController extends GetxController
    with GetTickerProviderStateMixin {
  List<ToolOptionModel> optionModelList =[];
  RenderBox? floatWindowRender;
  final moreVertKey = GlobalKey();
  final notificationKey = GlobalKey();
  final isMuteOpen = false.obs;
  final isMoreOpen = false.obs;
  final isOwner = false.obs;
  final isCollect = false.obs;
  /// 悬浮小窗参数
  OverlayEntry? floatWindowOverlay;
  Widget? overlayChild;

  Offset? floatWindowOffset;
  final LayerLink layerLink = LayerLink();

  late var gameTabController = TabController(length: 0, vsync:this);

  RxInt currentTabIndex = 0.obs;

  final group = Rxn<Group>();

  List<ChatInfoModel> groupGameTabOptions = [
    ChatInfoModel(
        tabType: GameChatInfoTabOption.member.tabType, stringKey: "memberTab"),
  ];

  //紀錄該群組是否已經開通
  RxBool isGroupCertified = RxBool(false);
  GlobalKey tabBarKey = GlobalKey();
  late BuildContext context;

  checkShowGameTab({bool needRefresh=true}) async {
    if(needRefresh){
      isGroupCertified.value = await dataCenter.isGroupCertified(
          groupId: sharedDataManager.groupId.toString());
    }
    if(isGroupCertified.value){
      await gameManager.groupInfoBackEvent();
      groupGameTabOptions.add(ChatInfoModel(
          tabType: GameChatInfoTabOption.game.tabType, stringKey: "gameTab"));
    }
    gameTabController = TabController(
      length: groupGameTabOptions.length,
      vsync: this,
    );

    gameTabController.addListener(() {
      currentTabIndex.value = gameTabController.index;
      if ( !gameTabController.indexIsChanging) {
        //切換tab就強制將tab置頂
        scrollToTabPinned();
      }
    });
  }

  void gotoGroupOfficialPage(BuildContext context) {
    if (!objectMgr.loginMgr.isLogin) return;
    final ownNickName = group.value?.owner.nickName ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            OfficialCertification.providerPage(ownNickName: ownNickName),
      ),
    ).then((value) async {
      isGroupCertified.value= sharedDataManager.certified==1;
      checkShowGameTab();
      return true;
    });
  }

  void scrollToTabPinned();


  void showMoreOptionPopup(BuildContext context) {
    if (sharedDataManager.isGroupCertified || !isOwner.value) {
      //只有當群組沒開通且自己是群主才可以顯示開通認證
      optionModelList.removeWhere((e) =>
      e.optionType == MorePopupOption.groupCertified.optionType);
    }
    if (!sharedDataManager.isGroupCertified) {
      //當群組沒開通移除推廣中心以及投注紀錄
      optionModelList.removeWhere((e) =>
      e.optionType == MorePopupOption.promoteCenter.optionType);
      optionModelList.removeWhere((e) =>
      e.optionType == MorePopupOption.betRecordHome.optionType);
      if(!imMiniAppManager.isCurrentUserShareholder) {
        //如果不是股東不能看群組運營
        optionModelList.removeWhere((e) =>
        e.optionType == MorePopupOption.groupOperate.optionType);
      }
    } else {
      //當群組已開通
      if(!imMiniAppManager.isCurrentUserShareholder) {
        //如果不是股東不能看群組運營
        optionModelList.removeWhere((e) =>
        e.optionType == MorePopupOption.groupOperate.optionType);
      }
    }

    floatWindowRender =
    moreVertKey.currentContext!.findRenderObject() as RenderBox;
    if (floatWindowOffset != null) {
      floatWindowOffset = null;
      floatWindowOverlay?.remove();
      floatWindowOverlay = null;
      isMoreOpen.value = false;
    } else {
      floatWindowOffset = floatWindowRender!.localToGlobal(Offset.zero);

      overlayChild = MoreVertView(
        optionList: optionModelList,
        func: () => isMoreOpen.value = false,
      );
      isMoreOpen.value = true;
      floatWindowOverlay = createOverlayEntry(
        shouldBlurBackground: false,
        context,
        Container(
          padding: const EdgeInsets.all(8.0),
          width: floatWindowRender!.size.width,
          height: floatWindowRender!.size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/svgs/chat_info_more.svg',
                width: objectMgr.loginMgr.isDesktop ? 22 : 22.w,
                height: objectMgr.loginMgr.isDesktop ? 22 : 22.w,
                color: accentColor,
              ),
              SizedBox(height: objectMgr.loginMgr.isDesktop ? 2 : 2.w),
              Text(
                localized(searchMore),
                style: jxTextStyle.textStyle12(
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: objectMgr.loginMgr.isDesktop ? 300 : 220.w,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
                objectMgr.loginMgr.isDesktop ? 10 : 10.0.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                spreadRadius: 0,
                blurRadius: 16,
              ),
            ],
          ),
          child: overlayChild,
        ),
        layerLink,
        left: floatWindowOffset!.dx - (objectMgr.loginMgr.isDesktop ? 321 : 0),
        right: null,
        top: floatWindowOffset!.dy,
        bottom: null,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        dismissibleCallback: () {
          floatWindowOffset = null;
          floatWindowOverlay?.remove();
          floatWindowOverlay = null;
          isMoreOpen.value = false;
        },
      );
    }
  }

  Future<void> checkCollect() async {
    final CResponseData resp = await CommonHttpRequest.doPost(ImConstants.collectGet,data:{});
    if (resp.code != 0) return ;

    bool isC = false;
    for (final e in resp.data) {
      final bean = GameCollectBean.fromJson(e);
      if (bean.gid == group.value?.uid) {
        isC = true;
      }
    }
    isCollect.value = isC;
  }
  Future<void> collectGroup() async {
    if (group.value == null) return;
    showLoading();
    await GameCollectManager().collectAdd(group.value!.uid);
    await checkCollect();
    dismissLoading();
  }
  Future<void> unCollectGroup() async {
    if (group.value == null) return;
    showLoading();
    await GameCollectManager().collectDel(group.value!.uid);
    await checkCollect();
    dismissLoading();
  }
}
