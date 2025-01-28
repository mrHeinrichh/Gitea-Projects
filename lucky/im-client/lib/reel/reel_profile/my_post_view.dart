import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_profile/post_item.dart';

import '../../api/reel.dart';

class MyPostView extends StatefulWidget {
  const MyPostView({Key? key}) : super(key: key);

  @override
  State<MyPostView> createState() => _MyPostViewState();
}

class _MyPostViewState extends State<MyPostView> {
  RxList<ReelData> postList = <ReelData>[].obs;

  @override
  void initState() {
    super.initState();
    getPostData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getPostData() async {
    int? offset = 0;
    int? limit = 100;
    int? allowPublic;

    final list = await getMyPost(offset, limit, allowPublic);
    if (list.isNotEmpty) {
      postList.value = list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => postList.isNotEmpty
          ? CustomScrollView(
              slivers: [
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverGrid.count(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 2.0,
                  crossAxisSpacing: 2.0,
                  children: List.generate(
                    postList.length,
                    (index) {
                      final item = postList[index];
                      return PostItem(item: item);
                    },
                  ),
                ),
              ],
            )
          : const Center(
              child: Text("No Posts"),
            ),
    );
  }
}
