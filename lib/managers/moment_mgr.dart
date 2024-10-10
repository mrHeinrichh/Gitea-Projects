import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/models/enum/moment_available_day.dart';
import 'package:jxim_client/object/retry.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/offline_retry/retry_util.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/utility.dart';

class MomentMgr extends EventDispatcher implements MgrInterface {
  static const String MOMENT_NEW_POST = 'MOMENT_NEW_POST';
  static const String MOMENT_COVER_UPDATE = 'MOMENT_COVER_UPDATE';
  static const String MOMENT_FRIEND_COVER_UPDATE = 'MOMENT_FRIEND_COVER_UPDATE';
  static const String MOMENT_POST_UPDATE = 'MOMENT_POST_UPDATE';
  static const String MOMENT_POST_DELETE = 'MOMENT_POST_DELETE';
  static const String MOMENT_MY_POST_UPDATE = 'MOMENT_MY_POST_UPDATE';

  static const String MOMENT_NOTIFICATION_UPDATE = 'MOMENT_NOTIFICATION_UPDATE';

  bool isUploadCover = false;

  List<MomentPosts> postList = [];

  Map<String, List<int>> momentTag = {};

  String momentCoverPath = '';
  Map<int, String> momentFriendCoverPath = {};

  MomentAvailableDays availableDaysMomentSetting = MomentAvailableDays.forever;

  // 朋友圈强提醒 数量
  int notificationStrongCount = 0;
  MomentNotificationLastInfo? notificationLastInfo;

  List<MomentDetailUpdate> notificationList = [];

  get FormatTime => null;

  @override
  Future<void> init() async {
    _getLocalCover();

    _getLocalAvailableDays();

    _getLocalStories();

    _getLocalMomentTag();

    // get moment setting
    getSetting();

    getLatestNotificationInfo();

    objectMgr.socketMgr.on(SocketMgr.updateMomentBlock, _onMomentUpdate);
  }

  @override
  Future<void> logout() async {
    postList.clear();
    momentTag.clear();
    momentCoverPath = '';

    objectMgr.localStorageMgr.remove(
      LocalStorageMgr.MOMENT_COVER_PATH,
      private: true,
    );
    objectMgr.localStorageMgr.remove(
      LocalStorageMgr.MOMENT_POST_LIST,
      private: true,
    );
    objectMgr.localStorageMgr.remove(
      LocalStorageMgr.MOMENT_TAG,
      private: true,
    );

    objectMgr.socketMgr.off(SocketMgr.updateMomentBlock, _onMomentUpdate);
  }

  @override
  Future<void> register() async {}

  @override
  Future<void> reloadData() async {
    // get moment setting
    // getSetting();

    getLatestNotificationInfo();
  }

  void _onMomentUpdate(_, __, Object? data) {
    if (data == null || data is! List) return;
    for (int i = 0; i < data.length; i++) {
      if (data[i].containsKey('notification')) {
        _processNotificationInfo(data[i]['notification']);
      }

      //notification_detail
      if (data[i].containsKey('notification_detail')) {
        _processNotificationDetail(data[i]['notification_detail']);
      }
    }
  }

  void _processNotificationInfo(dynamic data) {
    Map<String, dynamic> notificationContent = {};
    if (data is String) {
      notificationContent = jsonDecode(data);
    } else {
      notificationContent = data;
    }

    final notification =
        MomentNotificationLastInfo.fromJson(notificationContent);
    notificationStrongCount = notification.unreadNotificationCount ?? 0;

    if (notification.postCreatorId == 0) {
      notificationLastInfo = null;
    } else {
      notificationLastInfo = notification;
    }

    if (notificationStrongCount > 0) {
      unawaited(
        getNotificationList(
          startIdx: 0,
          limit: notificationStrongCount,
          shouldNotify: true,
        ),
      );
    }

    event(
      this,
      MOMENT_NOTIFICATION_UPDATE,
      data: notification,
    );
    return;
  }

  void _processNotificationDetail(dynamic data) {
    Map<String, dynamic> map = {};
    if (data is String) {
      map = jsonDecode(data);
    } else {
      map = data;
    }

    final MomentDetailUpdate detail = MomentDetailUpdate.fromJson(map);

    switch (detail.typ) {
      case MomentNotificationType.likeNotificationType: //強提醒
        final post = postList.firstWhereOrNull(
          (post) => post.post?.id == detail.content?.postId,
        );

        if (post == null) {
          updateMyPostMoment(detail);
          return;
        }

        if (post.likes!.list == null) {
          post.likes!.list = [];
        }

        post.likes!.list!.add(detail.content!.userId!);
        post.likes!.count =
            post.likes!.list?.length ?? (post.likes!.count ?? 0 + 1);
        updateMoment(post);
        break;
      case MomentNotificationType.commentNotificationType:
        final post = postList.firstWhereOrNull(
          (post) => post.post?.id == detail.content?.postId,
        );

        if (post == null) {
          updateMyPostMoment(detail);
          return;
        }

        if (post.commentDetail!.comments == null) {
          post.commentDetail!.comments = [];
        }

        post.commentDetail!.comments!.add(
          MomentComment(
            id: detail.typId,
            userId: detail.content!.userId,
            postId: detail.content?.postId,
            replyUserId: detail.content?.replyUserId,
            content: detail.content?.msg,
            createdAt: detail.createdAt,
          ),
        );
        post.commentDetail!.count = post.commentDetail?.comments?.length ??
            (post.commentDetail!.count ?? 0 + 1);
        post.commentDetail!.totalCount = (post.commentDetail?.totalCount ??
                post.commentDetail!.totalCount ??
                0) +
            1;

        updateMoment(post);
        break;
      case MomentNotificationType.deleteCommentNotificationType:
        final post = postList.firstWhereOrNull(
          (post) => post.post?.id == detail.postId,
        );

        if (post == null) {
          updateMyPostMoment(detail);
          return;
        }

        post.commentDetail!.comments!.removeWhere(
          (element) => element.id == detail.typId,
        );

        post.commentDetail!.count = post.commentDetail?.comments?.length ??
            (post.commentDetail!.count ?? 1 - 1);
        post.commentDetail!.totalCount = (post.commentDetail?.totalCount ??
                post.commentDetail!.totalCount ??
                1) -
            1;

        updateMoment(post);

        // 更新通知列表里的消息为删除类型
        final index = notificationList.indexWhere(
          (element) => element.typId == detail.typId,
        );
        if (index != -1) {
          notificationList[index].typ =
              MomentNotificationType.deleteCommentNotificationType;
        }

        break;
      case MomentNotificationType.deletePostNotificationType:
        final index = notificationList.indexWhere(
          (element) => element.typId == detail.typId,
        );
        if (index != -1) {
          notificationList[index].typ =
              MomentNotificationType.deletePostNotificationType;
        }
        break;
      case MomentNotificationType.deleteLikeNotificationType: //取消點讚
        final post = postList.firstWhereOrNull(
          (post) => post.post?.id == detail.postId,
        );

        if (post == null) {
          updateMyPostMoment(detail);
          return;
        } else {
          post.likes!.list!.removeWhere(
            (element) => element == detail.content!.userId!,
          );
          post.likes!.count = post.likes!.list?.length;
          updateMoment(post);
        }
        break;
      case MomentNotificationType.reLikeLikeNotificationType: //重新點贊
        final post = postList.firstWhereOrNull(
          (post) => post.post?.id == detail.postId,
        );

        if (post == null) {
          updateMyPostMoment(detail);
          return;
        } else {
          if (post.likes!.list == null) {
            post.likes!.list = [];
          }

          if (!post.likes!.list!.contains(detail.content!.userId!)) {
            post.likes!.list!.add(detail.content!.userId!);
            post.likes!.count =
                post.likes!.list?.length ?? (post.likes!.count ?? 0 + 1);
            updateMoment(post);
          }
        }
        break;
      default:
        return;
    }
  }

  void getSetting() async {
    try {
      final setting = await getMomentSetting();

      if (notBlank(setting.backgroundPic)) {
        momentCoverPath = setting.backgroundPic!;
        objectMgr.localStorageMgr.write(
          LocalStorageMgr.MOMENT_COVER_PATH,
          setting.backgroundPic!,
        );
        downloadMgr.downloadFile(momentCoverPath, mini: Config().dynamicMin);
        event(this, MOMENT_COVER_UPDATE, data: true);
      }

      if (notBlank(setting.availableDay)) {
        availableDaysMomentSetting =
            MomentAvailableDays.parseValue(setting.availableDay!);
        objectMgr.localStorageMgr.write(
          LocalStorageMgr.MOMENT_AVAILABLE_DAYS,
          setting.availableDay!,
        );
      }
    } catch (e) {
      pdebug('get moment setting error: $e');
    }
  }

  String getFriendCover(int userId) {
    if (momentFriendCoverPath.containsKey(userId)) {
      return momentFriendCoverPath[userId]!;
    } else {
      return objectMgr.localStorageMgr
              .read("${LocalStorageMgr.MOMENT_MY_POSTS_COVER}_$userId") ??
          "";
    }
  }

  void getFriendSetting(int targetId) async {
    try {
      final setting = await getMomentSetting(targetId: targetId);

      if (notBlank(setting.backgroundPic)) {
        String localCoverPath = objectMgr.localStorageMgr.read(
              "${LocalStorageMgr.MOMENT_MY_POSTS_COVER}_$targetId",
            ) ??
            "";
        if (localCoverPath.isNotEmpty &&
            localCoverPath == setting.backgroundPic) {
          return;
        }
        if (!momentFriendCoverPath.containsKey(targetId)) {
          momentFriendCoverPath[targetId] = setting.backgroundPic!;
        } else {
          momentFriendCoverPath.update(
            targetId,
            (value) => setting.backgroundPic!,
          );
        }

        downloadMgr.downloadFile(
          momentFriendCoverPath[targetId]!,
          mini: Config().dynamicMin,
        );
        objectMgr.localStorageMgr.write(
          "${LocalStorageMgr.MOMENT_MY_POSTS_COVER}_$targetId",
          momentFriendCoverPath[targetId]!,
        );
        event(this, MomentMgr.MOMENT_FRIEND_COVER_UPDATE, data: targetId);
      }
    } catch (e) {
      pdebug('get moment setting error: $e');
    }
  }

  _getLocalCover() {
    final String encodedCoverPath =
        objectMgr.localStorageMgr.read(LocalStorageMgr.MOMENT_COVER_PATH) ?? '';

    if (encodedCoverPath.isEmpty) return;

    momentCoverPath = encodedCoverPath;
  }

  void uploadCover(String path, int width, int height) async {
    if (isUploadCover) {
      return;
    }

    isUploadCover = true;
    final Size size =
        getResolutionSize(width, height, MediaResolution.image_high.minSize);

    final url = await imageMgr.upload(
      path,
      size.width.toInt(),
      size.height.toInt(),
      cancelToken: CancelToken(),
    );

    isUploadCover = false;

    if (notBlank(url)) {
      momentCoverPath = url!;
      objectMgr.localStorageMgr.write(
        LocalStorageMgr.MOMENT_COVER_PATH,
        url,
      );
      updateMomentSetting(coverPath: url);
    }
    event(this, MOMENT_COVER_UPDATE, data: notBlank(url));
  }

  _getLocalAvailableDays() {
    final int encodedAvailableDays = objectMgr.localStorageMgr
            .read<int?>(LocalStorageMgr.MOMENT_AVAILABLE_DAYS) ??
        0;

    if (!notBlank(encodedAvailableDays)) return;

    availableDaysMomentSetting =
        MomentAvailableDays.parseValue(encodedAvailableDays);
  }

  void uploadAvailableDays(MomentAvailableDays days) async {
    availableDaysMomentSetting = days;
    objectMgr.localStorageMgr.write(
      LocalStorageMgr.MOMENT_AVAILABLE_DAYS,
      days.value,
    );
    updateMomentSetting(availableDay: days.value);
  }

  // 获取本地朋友圈帖子
  _getLocalStories() {
    // 从本地缓存获取朋友圈帖子
    final String encodedPostList =
        objectMgr.localStorageMgr.read(LocalStorageMgr.MOMENT_POST_LIST) ?? '';

    if (encodedPostList.isEmpty) return;

    // 转换数据
    final List<dynamic> postList = jsonDecode(encodedPostList);
    this.postList =
        postList.map<MomentPosts>((e) => MomentPosts.fromJson(e)).toList();
  }

  // 获取朋友圈帖子 (所有人)
  Future<List<MomentPosts>> getStories(
    int start,
    int postId,
    int userId, {
    int limit = 50,
  }) async {
    final List<MomentPosts> newPostList = await getMomentStories(
      starts: start == 0 && userId == 0 && postId == 0
          ? ''
          : '$start,$postId,$userId',
      limit: limit,
    ).catchError((e) {
      //有機會發生Request: : 未知请求错误(502) 相關錯誤.
      return <MomentPosts>[MomentPosts()..networkError = true];
    });

    if (newPostList.isNotEmpty && newPostList.first.networkError) {
      return newPostList;
    }

    for (var i = 0; i < newPostList.length; i++) {
      if (newPostList[i].commentDetail!.totalCount! > 50) {
        final MomentPosts post = newPostList[i];
        final MomentCommentDetail? commentDetail = await getMomentCommentDetail(
          post.post!.id!,
          page: 1,
          limit: 1000,
        );
        post.commentDetail!.comments!.assignAll(commentDetail!.comments!);
        post.commentDetail!.count = post.commentDetail!.comments!.length;
      }
    }

    if (start == 0) {
      // 缓存最新的一屏数据到本地
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.MOMENT_POST_LIST, jsonEncode(newPostList));
      postList.assignAll(newPostList);
    } else {
      postList.addAll(newPostList);
    }

    return newPostList;
  }

  Future<void> getAllCommentDetail(
    MomentPosts post,
    int count,
    int page,
    int totalPage,
  ) async {
    final MomentCommentDetail? commentDetail = await getMomentCommentDetail(
      post.post!.id!,
      page: page,
      limit: count,
    );

    post.commentDetail!.comments!.addAll(commentDetail!.comments!);
    post.commentDetail!.count = post.commentDetail!.comments!.length;

    if (page + 1 > totalPage) {
      return;
    }

    await getAllCommentDetail(post, count, page + 1, totalPage);
  }

  // 获取特定用户的帖子数据
  Future<List<MomentPosts>> getUserPost(
    int userId,
    int startIdx, {
    int limit = 30,
    int commentLimit = 30,
  }) async {
    final List<MomentPosts> newPostList = await getMomentPost(
      userId: userId,
      startIdx: startIdx,
      limit: limit,
      commentLimit: commentLimit,
    ).catchError((e) {
      var temp = MomentPosts()..networkError = true;
      return <MomentPosts>[temp];
    });

    if (startIdx == 0) {
      // 缓存最新的一屏数据到本地
      objectMgr.localStorageMgr.write(
        "${LocalStorageMgr.MOMENT_MY_POSTS}_$userId",
        jsonEncode(newPostList),
      );
    }

    return newPostList;
  }

  void updateLocalMomentPostList() {
    objectMgr.localStorageMgr.write(LocalStorageMgr.MOMENT_POST_LIST,
        jsonEncode(postList.take(50).toList()));
  }

  void addLocalMomentPostList(MomentPosts post) {
    List<MomentPosts>? myPosts =
        getLocalHistoryPost(objectMgr.userMgr.mainUser.uid);
    myPosts = (myPosts ?? [])..insert(0, post);
    setLocalHistoryPost(objectMgr.userMgr.mainUser.uid, myPosts);
  }

  void setLocalHistoryPost(int userId, List<MomentPosts> postList) async {
    objectMgr.localStorageMgr.write(
      "${LocalStorageMgr.MOMENT_MY_POSTS}_$userId",
      jsonEncode(postList),
    );
  }

  void updateLocalHistoryPost(int userId, MomentPosts post) {
    List<MomentPosts> myPostList = getLocalHistoryPost(userId) ?? [];

    for (int i = 0; i < myPostList.length; i++) {
      if (myPostList[i].post?.id == post.post?.id) {
        myPostList[i] = post;
        setLocalHistoryPost(post.post!.userId!, myPostList);
        break;
      }
    }
  }

  // 获取本地朋友圈帖子
  List<MomentPosts>? getLocalHistoryPost(int userId) {
    // 从本地缓存获取朋友圈帖子
    final String encodedPostList = objectMgr.localStorageMgr
            .read("${LocalStorageMgr.MOMENT_MY_POSTS}_$userId") ??
        '';

    if (encodedPostList.isEmpty) return null;

    // 转换数据
    final List<dynamic> postList = jsonDecode(encodedPostList);

    return postList.map<MomentPosts>((e) => MomentPosts.fromJson(e)).toList();
  }

  Future<MomentPosts?> getSpecificPost(int postId) async {
    try {
      final MomentPosts post = await getPostDetail(postId: postId);

      if (post.commentDetail!.totalCount! > 50) {
        final MomentCommentDetail? commentDetail = await getMomentCommentDetail(
          post.post!.id!,
          page: 1,
          limit: 1000,
        );
        post.commentDetail!.comments!.assignAll(commentDetail!.comments!);
        post.commentDetail!.count = post.commentDetail!.comments!.length;
      }

      return post;
    } catch (e) {
      return null;
    }
  }

  _getLocalMomentTag() {
    final String? encodedMomentTag =
        objectMgr.localStorageMgr.read(LocalStorageMgr.MOMENT_TAG);

    if (!notBlank(encodedMomentTag)) return;

    final Map<String, dynamic> momentTag = jsonDecode(encodedMomentTag!);
    this.momentTag = momentTag.map((key, value) {
      return MapEntry(key, (value as List).map((e) => e as int).toList());
    });
  }

  // 同步用户好友标签
  syncMomentTag() async {}

  // 发布朋友圈
  Future<MomentPosts?> createMoment(
    MomentContent content, {
    MomentVisibility visibility = MomentVisibility.public,
    List<int>? targets,
    List<int>? mentions,
  }) async {
    try {
      final MomentPosts post =
          await createPost(content, visibility, targets ?? [], mentions ?? []);
      postList.insert(0, post);
      updateLocalMomentPostList();
      addLocalMomentPostList(post);
      return post;
    } catch (e) {
      return null;
    }
  }

  //更新各頁面post，由各頁面更新User post歷史。
  void updateMoment(MomentPosts post) {
    final index =
        postList.indexWhere((element) => element.post!.id == post.post!.id);
    if (index != -1) {
      postList[index] = post;
      updatePostCache();
      event(this, MOMENT_POST_UPDATE, data: post);
    }
  }

  //更新首頁緩存
  void updatePostCache() {
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.MOMENT_POST_LIST, jsonEncode(postList));
  }

  void updateMyPostMoment(MomentDetailUpdate post) {
    event(this, MOMENT_MY_POST_UPDATE, data: post);
  }

  Future<bool> deleteMoment(int postId) async {
    try {
      final status = await deletePost(postId: postId);
      if (status) {
        postList.removeWhere((element) => element.post!.id == postId);
        updatePostCache();
        List<MomentPosts>? myPost =
            getLocalHistoryPost(objectMgr.userMgr.mainUser.uid);
        if (myPost != null && myPost.isNotEmpty) {
          myPost.removeWhere((posts) => posts.post?.id == postId);
          setLocalHistoryPost(objectMgr.userMgr.mainUser.uid, myPost);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<MomentLikes> getLikePost(int postId) async {
    try {
      return await getPostLikeDetail(postId);
    } catch (e) {
      rethrow;
    }
  }

  Future<LikePost?> onLikePost(int postId, bool flag) async {
    try {
      return await likePost(postId, flag);
    } catch (e) {
      return null;
    }
  }

  Future<bool> onCommentPost(
    int postId,
    String content, {
    int replyUserId = 0,
  }) async {
    try {
      return await createComment(postId, content, replyUserId: replyUserId);
    } catch (e) {
      return false;
    }
  }

  Future<MomentCommentDetail?> getMomentCommentDetail(
    int postId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      return await getMomentComment(postId: postId, page: page, limit: limit);
    } catch (e) {
      return null;
    }
  }

  Future<bool> onDeleteComment(int commentId) async {
    try {
      final status = await deleteComment(commentId);
      return status;
    } catch (e) {
      return false;
    }
  }

  Future<void> getLatestNotificationInfo() async {
    try {
      final MomentNotificationLastInfo notificationInfo =
          await getMomentLatestNotificationInfo();

      final MomentNotificationResponse notification =
          await getMomentNotification(
        startIdx: 0,
        limit: notificationInfo.unreadNotificationCount ?? 10,
      );

      notificationLastInfo = notificationInfo;
      notificationStrongCount = notificationInfo.unreadNotificationCount ?? 0;
      notificationList.assignAll(notification.notifications ?? []);

      event(
        this,
        MOMENT_NOTIFICATION_UPDATE,
        data: notification,
      );
    } catch (e) {
      return;
    }
  }

  Future<MomentNotificationResponse> getNotificationList({
    required int startIdx,
    int limit = 10,
    bool shouldNotify = false,
  }) async {
    try {
      final MomentNotificationResponse notification =
          await getMomentNotification(
        startIdx: startIdx,
        limit: limit,
      );

      if (startIdx == 0) {
        notificationList.assignAll(notification.notifications ?? []);
      } else {
        notificationList.addAll(notification.notifications ?? []);
      }

      if (shouldNotify) {
        event(
          this,
          MOMENT_NOTIFICATION_UPDATE,
          data: notification,
        );
      }

      return notification;
    } catch (e) {
      logMgr.logMomentMgr.addMetrics(
        LogMomentMsg(
          msg: 'getNotificationList 报错: ${e.toString()}',
          e: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<bool> updateLastReadNotification({
    required int notificationId,
    int? hideNotificationId,
  }) async {
    try {
      final status = await updateLastNotification(
        notificationId: notificationId,
        hideNotificationId: hideNotificationId,
      );

      if (status) {
        if (notificationId != 0) {
          notificationList.clear();
          notificationStrongCount = 0;
        }

        notificationLastInfo = null;

        event(
          this,
          MOMENT_NOTIFICATION_UPDATE,
          data: notificationLastInfo,
        );
      }
      return status;
    } catch (e) {
      return false;
    }
  }

  void clearNotificationInfo() {
    notificationLastInfo = null;

    event(
      this,
      MOMENT_NOTIFICATION_UPDATE,
      data: notificationLastInfo,
    );
  }

  void clearNotificationList() {
    notificationList.clear();
    notificationStrongCount = 0;
    notificationLastInfo = null;

    event(
      this,
      MOMENT_NOTIFICATION_UPDATE,
      data: notificationLastInfo,
    );
  }

  //retryResponseData: 重試的資料
  void likeRetryCallback(Retry retry, bool isSuccess) {
    if (retry.apiType == CustomRequest.methodTypePost &&
        retry.endPoint ==
            RetryEndPointCallback.MOMENT_POST_LIKE_RETRY_CALLBACK) {
      final Map<String, dynamic> data = jsonDecode(retry.requestData);

      if (!isSuccess) {
        final int postId = data['data']['post_id'];
        final MomentPosts post =
            postList.firstWhereOrNull((element) => element.post!.id == postId)!;
        bool isLiked =
            post.likes?.list?.contains((objectMgr.userMgr.mainUser.uid)) ??
                false;
        if (isLiked) {
          post.likes!.list!.remove(objectMgr.userMgr.mainUser.uid);
          post.likes!.count = post.likes!.count! - 1;
          //1.可能在我的/好友帖子中去做按讚留言
          //2.可能在首頁的所有帖子中去做按讚留言
          updateMoment(post); //更新cell狀態
          if (!hasListener(MOMENT_POST_UPDATE)) {
            //若沒有訂閱，必須更新我的/好友帖子緩存
            updateLocalHistoryPost(post.post!.userId!, post);
          }
          return;
        }
        if (!isLiked) {
          post.likes!.list!.add(objectMgr.userMgr.mainUser.uid);
          post.likes!.count = post.likes!.count! + 1;
          updateMoment(post); //更新cell狀態
          if (!hasListener(MOMENT_POST_UPDATE)) {
            //若沒有訂閱，必須更新我的/好友帖子緩存
            updateLocalHistoryPost(post.post!.userId!, post);
          }
          return;
        }
      } else {
        //成功需確保按讚狀態
        final int postId = data['data']['post_id'];
        final MomentPosts post =
            postList.firstWhereOrNull((element) => element.post!.id == postId)!;
        final LikePost result = LikePost.fromJson(retry.responseData!.data);

        if (result != null) {
          // 点赞成功
          bool isLiked = post.likes?.list?.contains((result.userId)) ?? false;
          bool flag = result.flag ?? false;
          if (!flag && isLiked) {
            post.likes!.list!.remove(result.userId);
            post.likes!.count = post.likes!.count! - 1;
            objectMgr.momentMgr.updateMoment(post);
            if (!hasListener(MOMENT_POST_UPDATE)) {
              //若沒有訂閱，必須更新我的/好友帖子緩存
              updateLocalHistoryPost(post.post!.userId!, post);
            }
            return;
          }

          if (flag && !isLiked) {
            post.likes!.list!.add(result.userId!);
            post.likes!.count = post.likes!.count! + 1;
            objectMgr.momentMgr.updateMoment(post);
            if (!hasListener(MOMENT_POST_UPDATE)) {
              //若沒有訂閱，必須更新我的/好友帖子緩存
              updateLocalHistoryPost(post.post!.userId!, post);
            }
            return;
          }
        }
      }
    }
  }
}
