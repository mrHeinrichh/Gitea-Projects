import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../../main.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../group/group_chat_info_controller.dart';

class DetailView extends StatefulWidget {
  final Chat? chat;
  final Widget featureBtn;
  const DetailView({
    super.key,
    required this.featureBtn,
    this.chat,
  });

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  int members = 0, apps = gameManager.gameNameList.length, openTime = 0;
  late final groupController = Get.find<GroupChatInfoController>();

  Widget grpDetail(String data, String description) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ImText(
              data,
              color: ImColor.black,
              fontWeight: FontWeight.w700,
              fontSize: ImFontSize.title,
              fontFamily: fontFamily_din,
            ),
            ImGap.vGap4,
            ImText(
              description,
              color: ImColor.black48,
              fontWeight: FontWeight.w400,
            ),
          ],
        ),
      );

  @override
  void initState() {
    super.initState();
    GroupLocalBean? groupLocalBean = sharedDataManager.groupLocalData;
    members = groupController.groupMemberListData.length;
    if (groupLocalBean != null && groupLocalBean.certifiedTime != null) {
      openTime = groupLocalBean.certifiedTime ?? 0;
    }
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await updateInformation();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: <Widget>[
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(top: 20.w, right: 16.w, left: 16.w),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    grpDetail('$members', localized(groupMembers)),
                    grpDetail('$apps', localized(launchApp)),
                    grpDetail(
                        openTime != 0
                            ? DateFormat('yyyy/MM/dd').format(DateTime.parse(
                            DateTime.fromMillisecondsSinceEpoch(openTime * 1000).toString()
                        )) : '--',
                        localized(groupOpenTime)
                    ),
                  ],
                ),
                widget.featureBtn,
                ImGap.vGap24,
                ImText(
                  localized(groupNewActivity),
                  color: ImColor.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
                ImGap.vGap8,
                GestureDetector(
                  onTap: () {
                    if (!objectMgr.loginMgr.isLogin) return;
                    // if (chat != null) {
                    //   imMiniAppManager.goToPromotionCenterPage(context);
                    // }
                    imMiniAppManager.goToPromotionCenterPage(context);
                  },
                  child: Image.asset(
                    'assets/images/game_banner.png',
                    width: 360.w,
                    height: 140.w,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> updateInformation() async {
    Map appInfoMap = {};
    appInfoMap = await gameManager.getOpenAppInfo();
    apps = appInfoMap['app_count'];
    openTime = appInfoMap['open_time'];
    members = groupController.groupMemberListData.length;
    setState(() {});
  }
}
