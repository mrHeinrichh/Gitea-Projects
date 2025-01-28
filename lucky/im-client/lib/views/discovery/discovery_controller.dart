import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/call.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/views/discovery/discovery_recommend.dart';
import '../../main.dart';
import '../../object/call.dart';
import '../../routes.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/net/app_exception.dart';
import '../../utils/toast.dart';
import '../component/custom_avatar.dart';
import '../component/custom_confirmation_popup.dart';
import 'discovery_collection.dart';
import 'package:im/src/game_collect_manager.dart';
import 'package:im/src/object/game_collect_bean.dart';

class DiscoveryController extends GetxController
    with GetTickerProviderStateMixin {
  final BuildContext context = Routes.navigatorKey.currentContext!;
  late final TabController tabController;
  // late final TabController tagsTabController;
  // List<String> tagsTitleList = [
  //   localized(discovery_game),
  //   localized(discovery_novel),
  //   localized(discovery_livestream),
  //   localized(discovery_video)
  // ];

  late final TabController tagsTabControllerRecommend;
  List<String> tagsTitleListRecommend = [
    localized(discovery_game),
    localized(discovery_video),
    localized(discovery_novel),
    localized(discovery_livestream),
  ];
  late final TabController tagsTabControllerCollection;
  List<String> tagsTitleListCollection = [
    localized(discovery_game),
    localized(discovery_novel),
    localized(discovery_livestream),
  ];

  // RxInt tagIndex = 0.obs;
  RxInt tagIndexRecommend = 0.obs;
  RxInt tagIndexCollection = 0.obs;

  RxList<GameCollectBean> collectGameList = RxList<GameCollectBean>();

  StreamSubscription<List<GameCollectBean>>? collectGameListSub;

  final List<Widget> tabList = [
    const DiscoveryRecommend(),
    const DiscoveryCollection(),
  ];

  RxInt currentTabIndex = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    tabController = TabController(length: tabList.length, vsync: this);

    tabController.addListener(() {
      if (tabController.indexIsChanging) {
        currentTabIndex.value = tabController.index;
      }
    });
    tabController.index = 1;
    currentTabIndex.value = 1;

    tagsTabControllerRecommend = TabController(
      length: tagsTitleListRecommend.length,
      vsync: this,
    );
    tagsTabControllerCollection = TabController(
      length: tagsTitleListCollection.length,
      vsync: this,
    );
    // tagsTabController =
    //     TabController(length: tagsTitleList.length, vsync: this);
    // tagsTabController.addListener(() {
    //   if (tagsTabController.index == tagsTabController.animation?.value) {
    //     //_viewModel.setCurrentTab(_tabController.index);
    //   }
    // });

    GameCollectManager().fetch();
    collectGameListSub = GameCollectManager().collectListStream.listen((event) {
      fetchCollectList();
    });
  }

  @override
  void dispose() {
    collectGameListSub?.cancel();
    collectGameListSub = null;
    super.dispose();
  }

  Future<void> requestCollectGet() async {
    await GameCollectManager().fetch();
  }

  void fetchCollectList() async {
    if (collectGameList.hashCode != GameCollectManager().collectList.hashCode) {
      final newList = GameCollectManager().collectList;
      for (final game in newList) {
        game.groupName = await fetchGroupName(game.gid);
      }
      collectGameList.value = newList;
    }
  }

  Future<String> fetchGroupName(int gid) async {
    Group? group = objectMgr.myGroupMgr.getGroupById(gid);
    if (group == null) {
      //本地沒有再重新撈一次
      group = await objectMgr.myGroupMgr.loadGroupById(gid);
    }
    return group?.name ?? '';
  }

  void requestCollectDel(GameCollectBean game) {
    collectGameList.remove(game);
    GameCollectManager().collectDel(
      game.gid,
      shouldFetch: false,
    );
  }

  Future<void> removeLog(Call callItem) async {
    try {
      final bool successDeleted = await deleteLog(callItem.channelId);
      callItem.deletedAt = DateTime.now().millisecondsSinceEpoch;
      if (successDeleted) {
        objectMgr.callMgr.onCallLogChanged(
          [callItem],
        );
      }
    } catch (e) {
      if (e is NetworkException) {
        Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      } else
        Toast.showToast(e.toString());
    }
  }

  void onDeleteCallLog(Call callItem) async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          img: CustomAvatar(
            uid: objectMgr.userMgr.isMe(callItem.callerId)
                ? callItem.receiverId
                : callItem.callerId,
            size: 56.w,
          ),
          confirmButtonColor: JXColors.red,
          cancelButtonColor: accentColor,
          title: localized(deleteChatHistory),
          subTitle: localized(logInfoDoYouWantToDelete),
          confirmButtonText: localized(buttonDelete),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () {
            Get.back();
            removeLog(callItem);
          },
          cancelCallback: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}
