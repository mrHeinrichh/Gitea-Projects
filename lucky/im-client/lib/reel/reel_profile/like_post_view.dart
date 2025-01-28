import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/reel.dart';
import '../../object/reel.dart';
import 'post_item.dart';

class LikePostView extends StatefulWidget {
  const LikePostView({Key? key}) : super(key: key);

  @override
  State<LikePostView> createState() => _LikePostViewViewState();
}

class _LikePostViewViewState extends State<LikePostView> {
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

    final list = await getLikePost(offset, limit);
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
