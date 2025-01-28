import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:jxim_client/reel/components/reel_bottom_sheet.dart';
import 'package:jxim_client/reel/reel_profile/reel_follow_follower_list_item.dart';
import 'package:jxim_client/utils/debug_info.dart';

class ReelFollow extends StatelessWidget {
  ReelFollow({
    super.key,
  });

  final List demoList = [
    {'name': 'SS', 'type': 0,},
    {'name': 'TT', 'type': 2},
    {'name': 'EE','type': 2},
    {'name': 'FF', 'type': 2},
    {'name': 'GG', 'type': 0},
    {'name': 'HH', 'type': 2},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: demoList.length,
      itemBuilder: (BuildContext context, int index) {
        final rd = Random();
        return GetBuilder(
          // init: ,
          // id: ,
          builder: (_) {
            return ReelFollowFollowerListItem(
              isFollow: rd.nextBool(),
              type: demoList[index]['type'],
              name: demoList[index]['name'],
              avatarID: rd.nextInt(20),
              followerCount: rd.nextInt(20),
              onTap: () {
                if(demoList[index]['type'] == 2) {
                  //已關注
                  reelBtmSheet.showReelBottomFollowSheet(ctx: context, unFollowTap: () {
                    ///點擊了確認取消關注
                    pdebug('unfollow la~~');
                  },);
                }
              },
            );
          },
        );
      },
    );
  }
}
