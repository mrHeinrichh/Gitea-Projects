import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class GroupView extends StatefulWidget {
  final int userId;
  final Chat? chat;

  const GroupView({
    super.key,
    required this.userId,
    required this.chat,
  });

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  /// 加载状态
  final isLoading = false.obs;

  /// 是否还有更多数据
  bool isLoadingMore = true;
  final scrollThreshold = 200;
  final List<Map<String, dynamic>> commonGrp = [];
  Chat? chat;
  bool singleAndNotFriend = false;

  ChatInfoController? get chatInfoController =>
      Get.isRegistered<ChatInfoController>()
          ? Get.find<ChatInfoController>()
          : null;

  @override
  void initState() {
    super.initState();
    if (chatInfoController!.user.value!.relationship != Relationship.friend) {
      singleAndNotFriend = true;
    } else {
      loadGroupList();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadGroupList() async {
    if (commonGrp.isEmpty) isLoading.value = true;

    List<Map<String, dynamic>> grpList = [];
    commonGrp.clear();
    grpList = await objectMgr.myGroupMgr.getCommonGroupByRemote(widget.userId);
    if (grpList.isNotEmpty) {
      commonGrp.addAll(grpList);
    }

    commonGrp.sort((a, b) => b['join_time'].compareTo(a['join_time']));

    if (grpList.isEmpty) {
      isLoadingMore = false;
    }

    isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.scrollDelta! > 0.0) {
          } else if (notification.scrollDelta! < 0.0) {
          } else {
            Debounce dbounce = Debounce(const Duration(milliseconds: 100));
            dbounce.call(() {});
          }
        }
        // if (notification is ScrollEndNotification) {
        //   if ((notification.metrics.pixels ==
        //           notification.metrics.maxScrollExtent) ||
        //       (notification.metrics.pixels + scrollThreshold >
        //               notification.metrics.maxScrollExtent) &&
        //           scrollStatus == 1) {
        //     if (isLoadingMore) {
        //       loadGroupList();
        //     }
        //   }
        // }
        return true;
      },
      child: Obx(() {
        if (isLoading.value) {
          return BallCircleLoading(
            radius: 20,
            ballStyle: BallStyle(
              size: 4,
              color: themeColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: themeColor,
            ),
          );
        }

        if (singleAndNotFriend && commonGrp.isEmpty) {
          return Center(
            child: Text(localized(noItemFoundAddThisUserFirst)),
          );
        } else if (commonGrp.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: objectMgr.loginMgr.isDesktop ? 30.0 : 0, bottom: 16),
                child: SvgPicture.asset(
                  'assets/svgs/empty_state.svg',
                  width: 60,
                  height: 60,
                ),
              ),
              Text(
                localized(noHistoryYet),
                style: jxTextStyle.headerText(
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
              Text(
                localized(yourHistoryIsEmpty),
                style: jxTextStyle.normalText(color: colorTextSecondary),
              ),
            ],
          );
        } else {
          return CustomScrollView(
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext builder, int index) {
                    return OverlayEffect(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          chat = objectMgr.chatMgr.getChatById(
                              commonGrp[index]["group_info"]['id']);
                          if (chat != null) {
                            if(objectMgr.loginMgr.isDesktop){
                              if (Get.find<HomeController>().pageIndex.value == 0) {
                                Routes.toChat(chat: chat!);
                              } else {
                                final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
                                Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
                                Get.find<HomeController>().tabController?.index = 0;
                                Get.find<HomeController>().pageIndex.value = 0;
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (chat != null) {
                                    Routes.toChat(chat: chat!);
                                  }
                                });
                              }
                            }else{
                              Routes.toChat(chat: chat!);
                            }
                          }
                        },
                        child: Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: CustomAvatar(
                                size: 40,
                                dataProvider: DataProvider(
                                    uid: commonGrp[index]["group_info"]['id'],
                                    isGroup: true),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(border: customBorder),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${commonGrp[index]["group_info"]['name']}',
                                  style: jxTextStyle.headerText(
                                      fontWeight: MFontWeight.bold5.value),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: commonGrp.length,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
