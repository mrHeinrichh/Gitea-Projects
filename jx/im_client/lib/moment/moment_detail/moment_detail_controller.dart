import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_create/moment_publish_dialog.dart';
import 'package:jxim_client/moment/moment_label/moment_label_controller.dart';
import 'package:jxim_client/moment/moment_label/moment_label_member.dart';
import 'package:jxim_client/moment/moment_label/moment_label_page.dart';
import 'package:jxim_client/moment/moment_preview/moment_asset_preview.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';

class MomentDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late Rx<MomentPosts> post;

  // 展开评论输入框
  RxBool isCommentInputExpand = false.obs;

  // 展示表情输入
  RxBool showFaceView = false.obs;
  Timer? onDeleteTimer;

  // 被回复的用户id
  int? commentRepliedUserId;
  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();

  RxBool isSwitchingBetweenStickerAndKeyboard = false.obs;
  final stickerDebounce = Debounce(const Duration(milliseconds: 600));

  RxBool hasText = false.obs;

  // 点赞动画控制器
  late AnimationController likeAnimationController;

  final GlobalKey toolBoxKey = GlobalKey();
  OverlayEntry? overlayEntry;
  ValueNotifier<bool> isOverlayEnabled = ValueNotifier<bool>(false);

  final ScrollController scrollController = ScrollController();

  var keyboardHeights = 0.0.obs;

  final Rx<bool> isSending = false.obs;
  final Rx<bool> isDone = false.obs;
  final Rx<bool> isFailed = false.obs;
  bool isShowLoading = false;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>;

    if (arguments['detail'] == null) {
      post = Rx<MomentPosts>(MomentPosts());
    } else {
      post = Rx<MomentPosts>(arguments['detail'] as MomentPosts);
    }

    likeAnimationController = AnimationController(
      value:
          (post.value.likes?.list?.contains(objectMgr.userMgr.mainUser.uid) ??
                  false)
              ? 1.0
              : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    inputFocusNode.addListener(_onInputFocusChanged);
    inputController.addListener(_onTextChanged);
    likeAnimationController.addListener(_onLikeAnimationChanged);

    objectMgr.momentMgr.on(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);
    objectMgr.momentMgr.on(MomentMgr.MOMENT_MY_POST_UPDATE, onMyPostUpdate);
  }

  @override
  void onClose() {
    inputFocusNode.removeListener(_onInputFocusChanged);
    inputController.removeListener(_onTextChanged);
    inputController.dispose();
    likeAnimationController.removeListener(_onLikeAnimationChanged);

    objectMgr.momentMgr.off(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);
    objectMgr.momentMgr.off(MomentMgr.MOMENT_MY_POST_UPDATE, onMyPostUpdate);
    likeAnimationController.dispose();
    closeToggleToolExpand();
    super.onClose();
  }

  void maxScroll() {
    Future.delayed(const Duration(seconds: 1), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeInOut,
      );
    });
  }

  bool handleBackNavigation() {
    Get.back();
    return false;
  }

  Future<bool> clickBackAction() async {
    if (isOverlayEnabled.value) {
      isOverlayEnabled.value = false;
      return false;
    }
    return true;
  }

  void onMyPostUpdate(_, __, Object? detail) {
    if (detail is! MomentDetailUpdate || detail.postId != post.value.post?.id) {
      return;
    }

    switch (detail.typ) {
      case MomentNotificationType.likeNotificationType: //強提醒
        post.value.likes!.list!.add(detail.content!.userId!);
        post.value.likes!.count = post.value.likes!.list?.length ??
            (post.value.likes!.count ?? 0 + 1);
        break;
      case MomentNotificationType.commentNotificationType:
        if (post.value.commentDetail!.comments == null) {
          post.value.commentDetail!.comments = [];
        }

        post.value.commentDetail!.comments!.add(
          MomentComment(
            id: detail.typId,
            userId: detail.content!.userId,
            postId: detail.content?.postId,
            replyUserId: detail.content?.replyUserId,
            content: detail.content?.msg,
            createdAt: detail.createdAt,
          ),
        );
        post.value.commentDetail!.count =
            post.value.commentDetail?.comments?.length ??
                (post.value.commentDetail!.count ?? 0 + 1);
        post.value.commentDetail!.totalCount =
            (post.value.commentDetail?.totalCount ??
                    post.value.commentDetail!.totalCount ??
                    0) +
                1;
        break;
      case MomentNotificationType.deleteCommentNotificationType:
        post.value.commentDetail!.comments!.removeWhere(
          (element) => element.id == detail.typId,
        );
        post.value.commentDetail!.count =
            post.value.commentDetail?.comments?.length ??
                (post.value.commentDetail!.count ?? 1 - 1);
        post.value.commentDetail!.totalCount =
            (post.value.commentDetail?.totalCount ??
                    post.value.commentDetail!.totalCount ??
                    1) -
                1;
        break;
      case MomentNotificationType.deletePostNotificationType:
        break;
      case MomentNotificationType.deleteLikeNotificationType: //取消點讚
        post.value.likes!.list!.removeWhere(
          (element) => element == detail.content!.userId!,
        );
        post.value.likes!.count = post.value.likes!.list?.length;
        break;
      case MomentNotificationType.reLikeLikeNotificationType: //重新點贊
        post.value.likes!.list!.add(detail.content!.userId!);
        post.value.likes!.count = post.value.likes!.list?.length ??
            (post.value.likes!.count ?? 0 + 1);
        break;
      default:
        break;
    }

    update(['comment_view', 'like_view'].toList(), true);
  }

  void onPostUpdate(_, __, Object? updatedPost) {
    if (updatedPost is! MomentPosts ||
        updatedPost.post?.id != post.value.post?.id) return;

    post.value = updatedPost;

    bool isLiked =
        post.value.likes?.list?.contains((objectMgr.userMgr.mainUser.uid)) ??
            false;
    if (isLiked) {
      HapticFeedback.mediumImpact();
      likeAnimationController.forward();
    } else {
      likeAnimationController.reverse();
    }

    update(['comment_view', 'like_view'].toList(), true);
  }

  void _onLikeAnimationChanged() {
    update(['like_view'].toList(), true);
  }

  void closeToggleToolExpand() {
    if (overlayEntry != null) {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  double get getKeyboardHeight {
    if (keyboardHeight.value == 0) {
      if (KeyBoardObserver.instance.keyboardHeightOpen < 200 &&
          keyboardHeight.value < 200) {
        keyboardHeight.value = getPanelFixHeight;
        KeyBoardObserver.instance.keyboardHeightOpen = getPanelFixHeight;
      } else {
        keyboardHeight.value = KeyBoardObserver.instance.keyboardHeightOpen;
        return keyboardHeight.value;
      }
      if (Platform.isIOS) {
        return 336;
      } else {
        return 240;
      }
    }
    return keyboardHeight.value < MediaQuery.of(Get.context!).viewInsets.bottom
        ? MediaQuery.of(Get.context!).viewInsets.bottom
        : keyboardHeight.value;
  }

  double get getPanelFixHeight {
    if (Platform.isIOS) {
      var sWidth = 1;
      var sHeight = 1;
      if (sWidth == 430 && sHeight == 932) {
        return 346;
      } else if (sWidth == 375 && sHeight == 667) {
        ///iphone SE
        return 260;
      } else {
        return 336;
      }
    } else {
      return 294;
    }
  }

  void _onInputFocusChanged() {
    if (inputFocusNode.hasFocus) {
      if (showFaceView.value) {
        isSwitchingBetweenStickerAndKeyboard.value = true;
        stickerDebounce.call(() {
          isSwitchingBetweenStickerAndKeyboard.value = false;
        });
      }

      showFaceView.value = false;
    } else {
      if (!showFaceView.value) {
        isCommentInputExpand.value = false;
      }
    }
  }

  void _onTextChanged() {
    if (inputController.text.isEmpty && hasText.value) {
      hasText.value = false;
    } else if (inputController.text.isNotEmpty && !hasText.value) {
      hasText.value = true;
    }
  }

  void onEmojiClick() {
    /// 已经打开表情窗口 并且 键盘没有出现
    if (showFaceView.value) {
      showFaceView.value = false;
      inputFocusNode.requestFocus();

      inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: inputController.text.length),
      );
    } else {
      showFaceView.value = true;
      inputFocusNode.unfocus();
    }
  }

  void addEmoji(String emoji) {
    inputController.text = inputController.text + emoji;
  }

  void onTextDeleteTap() {
    final originalText = inputController.text;
    final newText = originalText.characters.skipLast(1).string;
    inputController.text = newText;
  }

  void onTextDeleteLongPress() {
    onDeleteTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!showFaceView.value ||
          !isCommentInputExpand.value ||
          inputFocusNode.hasFocus) {
        onDeleteTimer?.cancel();
        onDeleteTimer = null;
        return;
      }
      onTextDeleteTap();
    });
  }

  void onTextDeleteLongPressEnd(_) {
    onDeleteTimer?.cancel();
    onDeleteTimer = null;
  }

  void onMomentPostContentCopy(BuildContext context) async {
    if (!notBlank(post.value.post?.content?.text)) return;
    copyToClipboard(post.value.post!.content!.text!);
  }

  void onLikePost(BuildContext context) async {
    bool isLiked =
        post.value.likes?.list?.contains((objectMgr.userMgr.mainUser.uid)) ??
            false;

    Future.delayed(
      const Duration(milliseconds: 500),
      () => isOverlayEnabled.value = false,
    );

    if (isLiked) {
      likeAnimationController.reverse();
    } else {
      HapticFeedback.mediumImpact();
      likeAnimationController.forward();
    }

    objectMgr.momentMgr.onLikePost(post.value.post!.id!, !isLiked);

    // 点赞成功
    isLiked =
        post.value.likes?.list?.contains((objectMgr.userMgr.mainUser.uid)) ??
            false;

    if (isLiked) {
      post.value.likes!.list!.remove(objectMgr.userMgr.mainUser.uid);
      post.value.likes!.count = post.value.likes!.count! - 1;
      likeAnimationController.reverse();
      objectMgr.momentMgr.updateMoment(post.value);
      update(['like_view'].toList(), true);
      return;
    }

    if (!isLiked) {
      post.value.likes!.list!.add(objectMgr.userMgr.mainUser.uid);
      post.value.likes!.count = post.value.likes!.count! + 1;
      likeAnimationController.forward();
      objectMgr.momentMgr.updateMoment(post.value);
      update(['like_view'].toList(), true);
      return;
    }
  }

  void onCommentPost() async {
    if (inputController.text.isEmpty) return;

    final result = await objectMgr.momentMgr.onCommentPost(
      post.value.post!.id!,
      inputController.text.trim(),
      replyUserId: commentRepliedUserId ?? 0,
    );

    Future.delayed(
      const Duration(milliseconds: 500),
      () => isOverlayEnabled.value = false,
    );

    if (result) {
      final commentDetail = await objectMgr.momentMgr.getMomentCommentDetail(
        post.value.post!.id!,
        limit: 1000,
      );
      if (commentDetail == null) {
        post.value.commentDetail!.totalCount =
            post.value.commentDetail!.totalCount! + 1;
        post.value.commentDetail!.count = post.value.commentDetail!.count! + 1;
        post.value.commentDetail!.comments!.add(
          MomentComment(
            id: 0,
            userId: objectMgr.userMgr.mainUser.uid,
            postId: post.value.post!.id,
            replyUserId: commentRepliedUserId,
            content: inputController.text,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        objectMgr.momentMgr.updateMoment(post.value);
        closeKeyboard();
        commentRepliedUserId = null;
        isCommentInputExpand.value = false;
        update(['comment_view', 'input_text_field'].toList(), true);
        return;
      }

      post.value.commentDetail = commentDetail;
      objectMgr.momentMgr.updateMoment(post.value);
      closeKeyboard();
      commentRepliedUserId = null;
      isCommentInputExpand.value = false;
      update(['comment_view', 'input_text_field'].toList(), true);
    }
  }

  void onDeleteMoment(BuildContext context) async {
    showCustomBottomAlertDialog(
      context,
      subtitle: localized(momentDeleteTitle),
      confirmText: localized(delete),
      confirmTextColor: colorRed,
      cancelTextColor: themeColor,
      onConfirmListener: () => onMomentDeleteCallback(context),
    );
  }

  void onVisibilityTap(BuildContext context, MomentPosts post) {
    MomentLabelController momentLabelController =
        Get.put(MomentLabelController());

    List<Tags> tags = post.post!.targetTags
            ?.map((tag) {
              return objectMgr.tagsMgr.allTags.firstWhere(
                  (label) => label.uid.toString() == tag,
                  orElse: () =>
                      Tags()..uid = MomentLabelController.LABEL_IS_NOT_EXIST);
            })
            .where((tag) => tag.uid != MomentLabelController.LABEL_IS_NOT_EXIST)
            .toList() ??
        [];

    List<User> users = objectMgr.userMgr.allUsers
        .where((user) =>
            (post.post!.targets ?? []).contains(user.uid) &&
            user.relationship != Relationship.stranger)
        .toList();

    momentLabelController.tagsList.value = tags;
    momentLabelController.userList.value = users;
    momentLabelController.viewPermission.value =
        MomentVisibility.fromValue(post.post!.visibility!);

    MomentVisibility momentVisibility = MomentVisibility.public;
    List<User> selectedFriend = [];
    List<Tags> selectedLabel = [];
    bool isChanging = false;
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return MomentLabelBottomSheet(
          controller: momentLabelController,
          changeCallback: (MomentVisibility momentVisibilities,
              List<User> selectedFriends,
              List<Tags> selectedLabels,
              List<User> selectLabelFriends) {
            isChanging = true;
            selectedFriend = selectedFriends;
            selectedLabel = selectedLabels;
            momentVisibility = momentVisibilities;
            Get.close(1);
          },
          clickTagCallback: (Tags tag) {
            showMomentLabelMember(
              tag.tagName,
              (objectMgr.tagsMgr.allTagByGroup[tag.uid] ?? []).cast<User>(),
            );
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<MomentLabelController>();
      if (isChanging) {
        updatePost(post, momentVisibility, selectedFriend, selectedLabel);
      }
    });
  }

  void updatePost(MomentPosts post, MomentVisibility momentVisibility,
      List<User> selectedFriends, List<Tags> selectedLabel) async {
    onShowLoadingDialog(Get.context!);

    List<int> tagUid = selectedLabel.map((e) => e.uid).toList();
    List<int> targetUid = selectedFriends.map((e) => e.uid).toList();
    bool result = await objectMgr.momentMgr.updateMomentVisibilityPost(
        post, momentVisibility,
        targets: targetUid, target_tags: tagUid);
    isDone.value = false;
    isSending.value = false;
    if (!result) {
      isFailed.value = true;
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      onCloseLoadingDialog(Get.context!);
      update(["momentDetailVisibility"], true);
    });
  }

  void onShowLoadingDialog(BuildContext context) {
    isSending.value = true;
    isFailed.value = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Obx(
          () => MomentPublishDialog(
            isSending: isSending.value,
            isDone: isDone.value,
            isFailed: isFailed.value,
            sendingLocalizationKey: localized(momentModifying),
            doneLocalizationKey: localized(momentModified),
            failedLocalizationKey: localized(momentModificationFailed),
          ),
        );
      },
    );
    isShowLoading = true;
  }

  void onCloseLoadingDialog(BuildContext context) {
    if (isShowLoading) {
      Future.delayed(const Duration(milliseconds: 150), () {
        Navigator.of(context).pop();
        isShowLoading = false;
      });
    }
  }

  void showMomentLabelMember(String name, List<User> users) {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return MomentLabelMemberBottomSheet(
          tagName: name,
          member: users,
          cancelCallback: () {
            Get.close(1);
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<MomentLabelController>();
    });
  }

  void onMomentDeleteCallback(BuildContext context) async {
    final status = await objectMgr.momentMgr.deleteMoment(post.value.post!.id!);

    if (!status) {
      //ignore: use_build_context_synchronously
      imBottomToast(
        context,
        title: localized(deletedFailed),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    // refresh
    objectMgr.momentMgr.event(
      objectMgr.momentMgr,
      MomentMgr.MOMENT_POST_DELETE,
      data: post.value.post!.id!,
    );

    ///當使用者從MyPosted->刪除貼文後，返回MyPosted頁面，需要通知MyPosted頁面刷新
    String jsonString = '{"isDeleted": $status}';
    const jsonDecoder = JsonDecoder();
    final Map<String, dynamic> deleteResult = jsonDecoder.convert(jsonString);
    Get.back(result: deleteResult);
  }

  void onCommentTap(
    BuildContext context, {
    int? replyUserId,
    int? commentId,
  }) async {
    isOverlayEnabled.value = false;
    closeKeyboard();

    if (replyUserId != null &&
        objectMgr.userMgr.isMe(replyUserId) &&
        commentId != null) {
      // 弹窗删除
      onMomentCommentDelete(
        context,
        commentId,
      );
      return;
    }

    maxScroll();

    commentRepliedUserId = replyUserId;
    isCommentInputExpand.value = true;
    inputFocusNode.requestFocus();
  }

  void onCommentLongPress(
    BuildContext context, {
    required int commentId,
  }) async {
    closeKeyboard();
    // 弹窗删除
    onMomentCommentDelete(
      context,
      commentId,
    );
  }

  Future<void> onMomentCommentDelete(
    BuildContext context,
    int commentId,
  ) async {
    MomentComment? comment = post.value.commentDetail?.comments!
        .firstWhereOrNull((element) => element.id == commentId);

    if (!notBlank(comment)) {
      return;
    }

    FocusScope.of(context).unfocus();
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
        CustomBottomAlertItem(
          text: localized(momentCopyContent),
          onClick: () {
            onMomentCommentCopyCallback(
              comment!,
            );
          },
        ),
        if (objectMgr.userMgr.isMe(comment!.userId!) ||
            objectMgr.userMgr.isMe(post.value.post!.userId!))
          CustomBottomAlertItem(
            text: localized(momentDeleteComment),
            textColor: colorRed,
            onClick: () {
              onMomentCommentDeleteCallback(context, commentId: commentId);
            },
          ),
      ],
    );
  }

  void onMomentCommentCopyCallback(MomentComment comment) {
    copyToClipboard(comment.content!);
  }

  Future<void> onMomentCommentDeleteCallback(
    BuildContext context, {
    required int commentId,
  }) async {
    final status = await objectMgr.momentMgr.onDeleteComment(commentId);

    if (!status) {
      //ignore: use_build_context_synchronously
      imBottomToast(
        context,
        title: localized(deletedFailed),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    int limits = 1000;

    //先拉一次拿到最新的total_count;
    final commentDetail = await objectMgr.momentMgr.getMomentCommentDetail(
      post.value.post!.id!,
      limit: limits,
    );

    post.value.commentDetail = commentDetail;

    //ignore: use_build_context_synchronously
    imBottomToast(
      context,
      title: localized(deletedSuccess),
      icon: ImBottomNotifType.success,
    );

    objectMgr.momentMgr.updateMoment(post.value);
    update(
      ['comment_view', 'like_view'].toList(),
      true,
    ); //加入like_view為了刷新，點讚分隔線，當刪除留言時。
  }

  void onAssetPreview(BuildContext context, int index) async {
    closeKeyboard();
    if (!notBlank(post.value.post!.content!.assets)) return;

    if (objectMgr.loginMgr.isMobile) {
      Navigator.of(context)
          .push(
        TransparentRoute(
          builder: (BuildContext context) => MomentAssetPreview(
            assets: post.value.post!.content!.assets!,
            index: index,
            postId: post.value.post!.id!,
            userId: post.value.post!.userId!,
          ),
          settings: const RouteSettings(name: RouteName.momentAssetPreview),
        ),
      )
          .then((value) {
        closeKeyboard();
      });
    }
  }

  /// =========================== 工具方法 ===========================

  void closeKeyboard() {
    inputController.clear();
    inputFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
