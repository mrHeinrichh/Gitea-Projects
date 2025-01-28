import 'package:get/get.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/utils/debug_info.dart';

class ReelPostMgr {
  ReelPostMgr._();

  Map<String, ReelPost> allPosts = {};
  Map<int, Rxn<ReelCreator>> allCreators = {};

  static final ReelPostMgr _instance = ReelPostMgr._();

  static ReelPostMgr get instance => _instance;

  Future<List<ReelPost>> getMoreReels() async {
    try {
      final List<ReelPost> posts = await getSuggestedPosts();
      final List<ReelPost> items = syncData(posts);
      return items;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReelPost>> getPosts(int userId, {int? lastId}) async {
    int? limit = 30;
    int? allowPublic;

    try {
      final list = await getPost(userId, lastId, limit, allowPublic);
      final List<ReelPost> items = syncData(list);
      return items;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReelPost>> getSavedPosts(int userId, {int? lastId}) async {
    int? limit = 30;
    try {
      final list = await getSavePost(userId, lastId, limit);
      final List<ReelPost> items = syncData(list);
      return items;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReelPost>> getLikedPosts(int userId, {int? lastId}) async {
    int? limit = 30;
    try {
      final list = await getLikePost(userId, lastId, limit);
      final List<ReelPost> items = syncData(list);
      return items;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReelPost>> getSearchPost(String value, {int? offset}) async {
    try {
      final list = await searchPost(
        value,
        offset: offset ?? 0,
      );
      final List<ReelPost> items = syncData(list);
      return items;
    } catch (e) {
      rethrow;
    }
  }

  Future<ReelPost> updateReel(int postId) async {
    try {
      final reelData = await getReelDetail(postId);
      final List<ReelPost> items = syncData([reelData]);
      return items.first;
    } catch (e) {
      rethrow;
    }
  }

  List<ReelPost> syncData(List<ReelPost> posts) {
    List<ReelPost> newItems = [];
    for (var element in posts) {
      ReelPost itemChosen;
      if (allPosts[
              "${element.id.value!}_${element.creator.value!.id.value!}"] !=
          null) {
        ReelPost item = allPosts[
            "${element.id.value!}_${element.creator.value!.id.value!}"]!;
        item.sync(element);
        itemChosen = item;
        newItems.add(item);
      } else {
        allPosts["${element.id.value!}_${element.creator.value!.id.value!}"] =
            element;
        itemChosen = element;
        newItems.add(element);
      }

      if (allCreators[itemChosen.creator.value!.id.value] == null) {
        allCreators[itemChosen.creator.value!.id.value!] = itemChosen.creator;
      } else {
        var creator = itemChosen.creator;
        itemChosen.creator = allCreators[itemChosen.creator.value!.id.value!]!;
        itemChosen.creator.value?.sync(creator.value!);
      }
    }
    return newItems;
  }

  removeAllData() {
    allPosts.clear();
    allCreators.clear();
    pdebug(allPosts.values.length);
  }

  syncProfile(ReelProfile profile) {
    for (var post in allPosts.values) {
      if (post.creator.value?.id.value == profile.userid.value) {
        //找到对应的creator，同步一遍
        post.creator.value?.profilePic.value = profile.profilePic.value;
        post.creator.value?.name.value = profile.name.value;
        post.creator.value?.rs.value = profile.rs.value;
      }

      if (post.comments.isNotEmpty) {
        //每道文章里，若有评论被加载下来，这时需要同步评论里的资料
        post.comments
            .where((comment) => comment.userId.value == profile.userid.value)
            .toList()
            .forEach((element) {
          element.profilePic.value = profile.profilePic.value;
          element.name.value = profile.name.value;
          element.rs.value = profile.rs.value;
        });
      }
    }
    objectMgr.reelCacheMgr.sync(profile);
  }

  syncFollow(int userId, int newRs) {
    Rxn<ReelCreator>? creator = allCreators[userId];
    if (creator != null) {
      creator.value?.rs.value = newRs;
    }

    for (var post in allPosts.values) {
      if (post.comments.isNotEmpty) {
        //每道文章里，若有评论被加载下来，这时需要同步评论里的资料
        post.comments
            .where((comment) => comment.userId.value == userId)
            .toList()
            .forEach((element) {
          element.rs.value = newRs;
        });
      }
    }
    objectMgr.reelCacheMgr.syncFollow(userId, newRs);
  }
}
