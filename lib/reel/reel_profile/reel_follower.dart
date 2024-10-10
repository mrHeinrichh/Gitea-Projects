import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/reel/components/reel_bottom_sheet.dart';
import 'package:jxim_client/reel/reel_profile/reel_follow_follower_list_item.dart';
import 'package:jxim_client/utils/debug_info.dart';

class ReelFollower extends StatelessWidget {
  ReelFollower({
    super.key,
  });

  final List demoList = [
    {'name': 'JJ', 'type': 3},
    {'name': 'KK', 'type': 1},
    {'name': 'AA', 'type': 3},
    {'name': 'BB', 'type': 1},
    {'name': 'CC', 'type': 3},
    {'name': 'DD', 'type': 3},
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
              avatarID: rd.nextInt(30),
              followerCount: rd.nextInt(30),
              onTap: () {
                if (demoList[index]['type'] == 3) {
                  //相互關注
                  reelBtmSheet.showReelBottomFollowSheet(
                    ctx: context,
                    unFollowTap: () {
                      ///點擊了確認取消關注
                      pdebug('unfollow la~~');
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
