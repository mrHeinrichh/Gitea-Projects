import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';

class ReelCacheMgr extends BaseMgr {
  List<ReelPost> cacheReels = [];
  List<CancelToken> currentTokens = [];

  @override
  Future<void> initialize() async {
    preloadAssets();
  }

  @override
  Future<void> cleanup() async {
    cacheReels.clear();
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.REEL_POST_LIST, private: true);
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.REEL_UPLOAD_TAG_LIST, private: true);
  }

  List<ReelUploadTag> getLocalTags() {
    final String encodedTagList =
        objectMgr.localStorageMgr.read(LocalStorageMgr.REEL_UPLOAD_TAG_LIST) ??
            '';
    if (encodedTagList.isEmpty) return [];

    // 转换数据
    final List<dynamic> tags = jsonDecode(encodedTagList);
    List<ReelUploadTag> tagList =
        tags.map<ReelUploadTag>((e) => ReelUploadTag.fromJson(e)).toList();
    return tagList;
  }

  // 获取本地视频号帖子
  List<ReelPost> getLocalPosts() {
    final String encodedPostList =
        objectMgr.localStorageMgr.read(LocalStorageMgr.REEL_POST_LIST) ?? '';

    if (encodedPostList.isEmpty) return [];

    // 转换数据
    final List<dynamic> postList = jsonDecode(encodedPostList);

    List<ReelPost> reelList =
        postList.map<ReelPost>((e) => ReelPost.fromJson(e)).toList();
    return reelList;
  }

  syncFollow(int userId, int newRs) {
    bool synced = false;
    for (var post in cacheReels) {
      if (post.creator.value?.id.value == userId) {
        synced = true;
        post.creator.value?.rs.value = newRs; //因为作者数据也保持统一，故找到一次就能离开
        break;
      }
    }
    if (synced) {
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.REEL_POST_LIST, jsonEncode(cacheReels));
    }
  }

  sync(ReelProfile profile) {
    bool synced = false;
    for (var post in cacheReels) {
      if (post.creator.value?.id.value == profile.userid.value) {
        synced = true;
        //找到对应的creator，同步一遍
        post.creator.value?.profilePic.value = profile.profilePic.value;
        post.creator.value?.name.value = profile.name.value;
        post.creator.value?.rs.value = profile.rs.value;
      }
    }
    if (synced) {
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.REEL_POST_LIST, jsonEncode(cacheReels));
    }
  }

  preloadAssets() async {
    List<ReelPost> data = getLocalPosts();
    if (data.isEmpty) {
      try {
        await downloadReelsWithPreCache();
      } catch (e) {
        return;
      }
    } else {
      //确保每道视频都有m3u8和ts文件。
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        for (var element in data) {
          _preloadM3u8AndThumbnail(element);
        }
      });
    }
  }

  refreshCache() async {
    try {
      await downloadReelsWithPreCache();
    } catch (e) {
      // pdebug("error");
    }
  }

  downloadReelsWithPreCache({bool downloadData = true}) async {
    try {
      List<ReelPost> posts = await refreshReel();
      if (posts.isNotEmpty && downloadData) {
        for (var element in currentTokens) {
          if (element.isCancelled == false) element.cancel();
        }
        currentTokens.clear();
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          for (var element in posts) {
            _preloadM3u8AndThumbnail(element);
          }
        });
      }
      return posts;
    } catch (e) {
      rethrow;
    }
  }

  _preloadM3u8AndThumbnail(ReelPost data) {
    final String source = data.file.value!.path.value!;
    final int width = data.file.value!.width.value!;
    final int height = data.file.value!.height.value!;
    // preloadThumbnail(data.post!.thumbnail!);
    videoMgr.preloadVideo(source, width: width, height: height);
  }

  void preloadThumbnail(String source) async {
    try {
      CancelToken token = CancelToken();
      currentTokens.add(token);
      await downloadMgrV2.download(
        source,
        mini: Config().dynamicMin,
        cancelToken: token,
      );
      // await downloadMgr.downloadFile(
      //   source,
      //   mini: Config().dynamicMin,
      //   cancelToken: token,
      // );
    } catch (e) {
      pdebug('Download thumbnail failed: $e');
    }
  }

  Future<List<ReelPost>> refreshReel() async {
    try {
      final List<ReelPost> posts = await ReelPostMgr.instance.getMoreReels();
      if (posts.isNotEmpty) {
        cacheReels = posts;
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.REEL_POST_LIST, jsonEncode(posts));
      }
      return posts;
    } catch (e) {
      // e.printError();
      rethrow;
    }
  }

  void updateTagList(List<ReelUploadTag> tagList) {
    List<ReelUploadTag> tags = getLocalTags();
    tags
        .where((element) => element.uploadDate == null)
        .toList()
        .forEach((element) {
      element.uploadDate = DateTime.now();
    });
    for (var tag in tagList) {
      ReelUploadTag? tagRetrieved =
          tags.firstWhereOrNull((element) => element.tag == tag.tag);
      if (tagRetrieved != null) {
        tagRetrieved.uploadDate = DateTime.now();
        tagRetrieved.count++;
      } else {
        tag.uploadDate = DateTime.now();
        tags.add(tag);
      }
    }
    tags.sort((a, b) {
      return b.count.compareTo(a.count);
    });

    tags.sort((a, b) {
      if (a.count == b.count) {
        return b.uploadDate!.compareTo(a.uploadDate!);
      } else {
        return 0;
      }
    });

    objectMgr.localStorageMgr
        .write(LocalStorageMgr.REEL_UPLOAD_TAG_LIST, jsonEncode(tags));
  }

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}
