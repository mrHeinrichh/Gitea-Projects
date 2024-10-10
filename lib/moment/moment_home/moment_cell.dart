import 'dart:io';

import 'package:dio/dio.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/component/expandable_text_widget.dart';
import 'package:jxim_client/moment/component/moment_post_tool_box.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_comment/moment_comment_view_more.dart';
import 'package:jxim_client/moment/moment_preview/moment_asset_preview.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/gaussian_image/gaussian_image.dart';

class MomentCell extends StatefulWidget {
  final MomentPosts momentPost;
  final int index;

  const MomentCell({
    super.key,
    required this.momentPost,
    required this.index,
  });

  @override
  State<MomentCell> createState() => _MomentCellState();
}

class _MomentCellState extends State<MomentCell>
    with SingleTickerProviderStateMixin {
  late MomentPosts post;

  MomentHomeController controller = Get.find<MomentHomeController>();

  MomentPost get momentPost => post.post!;

  MomentLikes get momentLikes => post.likes!;

  MomentCommentDetail get momentCommentDetail => post.commentDetail!;

  final GlobalKey containerKey = GlobalKey();

  final GlobalKey toolBoxKey = GlobalKey();
  ValueNotifier<bool> isOverlayEnabled = ValueNotifier<bool>(false);
  OverlayEntry? overlayEntry;

  Map<String, bool> isExpandedCommand = {};

  RxString source = ''.obs;
  final thumbCancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    post = MomentPosts()
      ..post = widget.momentPost.post
      ..commentDetail = widget.momentPost.commentDetail
      ..likes = widget.momentPost.likes;

    objectMgr.momentMgr.on(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);

    if (notBlank(momentPost.content?.assets)) {
      if (momentPost.content!.assets!.length == 1 && momentPost.content!.assets!.first.type == 'video') {
        _preloadVideo(momentPost.content!.assets!.first.url, momentPost.content!.assets!.first.width, momentPost.content!.assets!.first.height,);
      }
    }
  }

  _preloadVideo(String url,int width,int height) async {
    videoMgr.preloadVideo(
      url,
      width: width,
      height: height,
    );
  }

  @override
  void didUpdateWidget(covariant MomentCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hashCode != widget.hashCode) {
      //更新MomentCell
      post = MomentPosts()
        ..post = widget.momentPost.post
        ..commentDetail = widget.momentPost.commentDetail
        ..likes = widget.momentPost.likes;
      setState(() {});
    }
  }

  @override
  void dispose() {
    closeToggleToolExpand();
    objectMgr.momentMgr.off(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);
    super.dispose();
  }

  void onPostUpdate(_, __, Object? updatedPost) {
    if (updatedPost is! MomentPosts || updatedPost.post?.id != post.post?.id){
      return;
    }

    post = updatedPost;
    controller.postList[widget.index] = post;
    //Update my posts local cache.
    objectMgr.momentMgr.updateLocalHistoryPost(post.post!.userId!, post);
    if (mounted) {
      setState(() {});
    }
  }

  void onAssetPreview(BuildContext context, int index) async {
    if (!notBlank(momentPost.content!.assets)) return;

    if (objectMgr.loginMgr.isMobile) {
      controller.closeKeyboard();
      Navigator.of(context).push(
        TransparentRoute(
          builder: (BuildContext context) => MomentAssetPreview(
            assets: momentPost.content!.assets!,
            index: index,
            postId: momentPost.id!,
            userId: momentPost.userId!,
          ),
          settings: const RouteSettings(name: RouteName.momentAssetPreview),
        ),
      );
    }
  }

  void onEnterDetailView() async {
    Get.toNamed(
      RouteName.momentDetail,
      arguments: {
        'detail': post,
      },
    );
  }

  void onLikePost(BuildContext context) async {
    // 点赞成功
    bool isLiked = post.likes?.list?.contains((objectMgr.userMgr.mainUser.uid)) ?? false;

    objectMgr.momentMgr.onLikePost(post.post!.id!,!isLiked);

    Future.delayed(
      const Duration(milliseconds: 500),
          () => isOverlayEnabled.value = false,
    );

    if (isLiked) {
      post.likes!.list!.remove(objectMgr.userMgr.mainUser.uid);
      post.likes!.count = post.likes!.count! - 1;
      objectMgr.momentMgr.updateMoment(post);
      if (mounted) setState(() {});
      return;
    }

    if (!isLiked) {
      post.likes!.list!.add(objectMgr.userMgr.mainUser.uid);
      post.likes!.count = post.likes!.count! + 1;
      objectMgr.momentMgr.updateMoment(post);
      if (mounted) setState(() {});
      return;
    }
  }

  void onDeleteMoment(BuildContext context) async
  {
      controller.closeKeyboard();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) {
          return CustomConfirmationPopup(
            confirmButtonColor: colorRed,
            confirmButtonText: localized(delete),
            cancelButtonColor: momentThemeColor,
            cancelButtonText: localized(cancel),
            title: localized(momentDeleteTitle),
            confirmCallback: () => onMomentDeleteCallback(context),
            cancelCallback: ()
            {
              final navigator = Navigator.of(context);
              // it not always be null,check it to avoid crash is necessary.
              if (navigator != null) {
                navigator.pop();
              }
            },
          );
        },
      );
  }

  void onMomentDeleteCallback(BuildContext context) async {
    final status = await objectMgr.momentMgr.deleteMoment(post.post!.id!);

    if (!status) {
      //ignore: use_build_context_synchronously
      imBottomToast(
        context,
        title: localized(deletedFailed),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    //ignore: use_build_context_synchronously
    imBottomToast(
      context,
      title: localized(momentPostDeleteSuccess),
      icon: ImBottomNotifType.warning,
    );

    // refresh
    objectMgr.momentMgr.event(
      objectMgr.momentMgr,
      MomentMgr.MOMENT_POST_DELETE,
      data: post.post!.id,
    );
  }

  void onCommentTap(
    BuildContext context, {
    int? replyUserId,
    int? commentId,
  }) async {
    isOverlayEnabled.value = false;
    controller.closeKeyboard();
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
    if (!controller.isMovingCover.value) animateToPostEnd();
    controller.commentRepliedUserId = replyUserId;
    controller.commentRepliedPostId = post.post!.id;
    controller.commentRepliedPostIdx = widget.index;
    controller.isCommentInputExpand.value = true;
    controller.inputFocusNode.requestFocus();
    controller.update(['input_text_field'].toList(), true);
  }

  void onCommentLongPress(
    BuildContext context, {
    required int commentId,
  }) async {
    controller.closeKeyboard();
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
    MomentComment? comment = post.commentDetail?.comments!
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
              context,
              comment: comment!,
            );
          },
        ),
        if (objectMgr.userMgr.isMe(comment!.userId!) ||
            objectMgr.userMgr.isMe(post.post!.userId!))
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

  void onMomentPostContentCopy(BuildContext context) async =>
      copyToClipboard(momentPost.content!.text!);

  void onMomentCommentCopyCallback(
    BuildContext context, {
    required MomentComment comment,
  }) async {
    Clipboard.setData(ClipboardData(text: comment.content!));
    imBottomToast(
      context,
      title: localized(toastCopyToClipboard),
      icon: ImBottomNotifType.success,
    );
  }

  Future<void> onMomentCommentDeleteCallback(
    BuildContext context, {
    required int commentId,
  }) async {
    controller.closeKeyboard();
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
      momentPost.id!,
      limit: limits,
    );

    post.commentDetail = commentDetail;

    //ignore: use_build_context_synchronously
    imBottomToast(
      context,
      title: localized(momentCommentDeleteSuccess),
      icon: ImBottomNotifType.success,
    );

    objectMgr.momentMgr.updateMoment(post);

    if (mounted) setState(() {});
  }

  void animateToPostEnd() async {
    final RenderBox renderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    final widgetY = position.dy + size.height;
    final visibleHeight = screenHeight - getKeyboardHeight;

    if (widgetY > visibleHeight) {
      final diffY = widgetY - visibleHeight + 60;

      Future.delayed(const Duration(milliseconds: 500), () {
        controller.scrollController.animateTo(
          controller.scrollController.offset + diffY,
          duration: const Duration(milliseconds: 233),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  void toggleToolExpand(BuildContext context, GlobalKey toolBoxKey) {
    if (isOverlayEnabled.value) {
      isOverlayEnabled.value = false;
      return;
    }

    final box = toolBoxKey.currentContext?.findRenderObject() as RenderBox;
    final Offset boxOffset = box.localToGlobal(Offset.zero);

    isOverlayEnabled.value = true;

    overlayEntry = createOverlayEntry(
      context,
      GestureDetector(
        onTap: () => isOverlayEnabled.value = false,
        child: SvgPicture.asset(
          'assets/svgs/moments_more.svg',
          width: 32,
          height: 20,
        ),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: isOverlayEnabled,
        builder: (_, enabled, Widget? __) {
          return MomentPostToolBox(
            // post: post,
            isLikePost:
                post.likes?.list?.contains((objectMgr.userMgr.mainUser.uid)) ??
                    false,
            onLikePost: onLikePost,
            onCommentTap: onCommentTap,
            isOverlayEnabled: enabled,
            onEnd: closeToggleToolExpand,
          );
        },
      ),
      left: boxOffset.dx,
      top: boxOffset.dy,
      targetAnchor: Alignment.centerLeft,
      followerAnchor: Alignment.centerRight,
      shouldBlurBackground: false,
      dismissibleCallback: () {
        isOverlayEnabled.value = false;
      },
      LayerLink(),
    );
  }

  void closeToggleToolExpand() {
    if (overlayEntry != null) {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (isOverlayEnabled.value) {
            isOverlayEnabled.value = false;
            return false;
          }
      return true;
    }, child:  Container(
      key: containerKey,
      color: colorWhite,
      child: Column(
        children: <Widget>[
          _buildMomentPostContent(context),
          if (((momentLikes.count ?? 0) > 0) | ((momentCommentDetail.count ?? 0) > 0))
            Container(
              decoration: BoxDecoration(
                color: momentBackgroundColor,
                borderRadius: BorderRadius.circular(4.0),
              ),
              margin: const EdgeInsets.only(
                top: 4.0,
                left: 56.0,
                right: 12.0,
                bottom: 12.0,
              ),
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 点赞
                  buildLikeView(context),
                  if ((momentLikes.count ?? 0) > 0 && (momentCommentDetail.count ?? 0) > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.0),
                      child: Divider(
                        color: momentBorderColor,
                        height: 0.5,
                      ),
                    ),
                  // 评论
                  buildCommentView(context),
                ],
              ),
            ),
        ],
      ),
     ),
    );
  }

  Widget _buildMomentPostContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        bottom:
            (momentLikes.count ?? 0) > 0 || (momentCommentDetail.count ?? 0) > 0
                ? 0.0
                : 8.0,
        top: 16.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () => controller.onMyPostsTap(momentPost.userId!),
            child: ForegroundOverlayEffect(
              overlayColor: colorTextPrimary.withOpacity(0.3),
              radius: BorderRadius.circular(40.0),
              child: CustomAvatar.normal(
                momentPost.userId ?? 0,
                size: 40.0,
                headMin: Config().headMin,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: NicknameText(
                    uid: momentPost.userId!,
                    color: momentThemeColor,
                    fontSize: MFontSize.size17.value,
                    fontWeight: MFontWeight.bold5.value,
                    isTappable: false,
                    maxLine: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (notBlank(momentPost.content?.text))
                  GestureDetector(
                    onLongPress: () => onMomentPostContentCopy(context),
                    child: OverlayEffect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: ExpandableText(
                          text: momentPost.content!.text ?? "",
                          style: jxTextStyle.textStyle17(
                            color: colorTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (notBlank(momentPost.content?.assets))
                  const SizedBox(height: 3.0),
                if (notBlank(momentPost.content?.assets))
                  if (momentPost.content!.assets!.length == 1)
                    GestureDetector(
                      onTap: () => onAssetPreview(context, 0),
                      child: buildSingleAsset(context),
                    )
                  else if (momentPost.content!.assets!.first.type != 'video')
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.78,
                      child: momentPost.content!.assets!.length == 4
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width * 0.78,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: MomentPictureWidget(
                                      width: MediaQuery.of(context).size.width *
                                          0.78,
                                      momentContentDetail:
                                          momentPost.content!.assets,
                                      postId: momentPost.id!,
                                      userId: momentPost.userId!,
                                    ),
                                  ),
                                  Container(
                                    width: (MediaQuery.of(context).size.width *
                                            0.78) /
                                        3,
                                    color: Colors.transparent,
                                  ),
                                ],
                              ),
                            )
                          : MomentPictureWidget(
                              width: MediaQuery.of(context).size.width * 0.78,
                              momentContentDetail: momentPost.content!.assets,
                              postId: momentPost.id!,
                              userId: momentPost.userId!,
                            ),
                    ),
                if (notBlank(momentPost.content?.assets))
                  const SizedBox(height: 8.0),
                if (notBlank(momentPost.mentions)) _buildMentionView(context),
                _buildPostInfo(context),
                // _buildToolOptions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSingleAsset(BuildContext context) {
    MomentContentDetail asset = momentPost.content!.assets!.first;
    final isVideo = asset.type.contains('video');
    final ratio = asset.width / asset.height;

    double width = ratio >= 1.0
        ? MediaQuery.of(context).size.width * 0.5
        : MediaQuery.of(context).size.width * 0.3;

    final height = ratio >= 1.0 ? width / ratio : MediaQuery.of(context).size.width * 0.4;

    if (isVideo) {
      if (ratio < 1.0) {
        width = MediaQuery.of(context).size.width * 0.375;
      }

      return Hero(
        tag: asset.uniqueId,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              GaussianImage(
                  src: momentPost.content!.assets!.first.cover!,
                  width: width,
                  height: height,
                  gaussianPath: momentPost.content!.assets!.first.gausPath,
                  mini: Config().messageMin,
                  fit: BoxFit.cover,
                  enableShimmer:false
              ),
              SvgPicture.asset(
                'assets/svgs/video_play_icon.svg',
                width: 40,
                height: 40,
              ),
            ],
          ),
        ),
      );
    }

    return Hero(
      tag: asset.uniqueId,
      child: SizedBox(
        width: width,
        height: height,
        child:
        GaussianImage(
            src: momentPost.content!.assets!.first.url,
            width: width,
            height: height,
            gaussianPath: momentPost.content!.assets!.first.gausPath,
            mini: Config().messageMin,
            fit: BoxFit.cover,
            enableShimmer:false
        ),
      ),
    );
  }

  Widget _buildPostInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 3.0,
        bottom: 3.0,
      ),
      child: Row(
        children: <Widget>[
          Text(
            FormatTime.getCountTime(momentPost.createdAt ?? 0),
            style: jxTextStyle.textStyle14(
              color: colorTextSupporting,
            ),
          ),
          if (objectMgr.userMgr.isMe(post.post!.userId!))
            GestureDetector(
              onTap: () => onDeleteMoment(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: OpacityEffect(
                  child: SvgPicture.asset(
                    'assets/svgs/moment_delete_icon.svg',
                    width: 16.0,
                    height: 16.0,
                    colorFilter: const ColorFilter.mode(
                      momentThemeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          GestureDetector(
            key: toolBoxKey,
            onTap: () => toggleToolExpand(context, toolBoxKey),
            child: SvgPicture.asset(
              'assets/svgs/moments_more.svg',
              width: 32,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionView(BuildContext context) {
    // 贴主
    if (objectMgr.userMgr.isMe(momentPost.userId!)) {
      return Container(
        padding: const EdgeInsets.only(
          top: 3.0,
          bottom: 3.0,
        ),
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    momentPost.mentions!
                            .contains(objectMgr.userMgr.mainUser.uid)
                        ? "${localized(momentMentionedMe)}:"
                        : "${localized(momentMentioned)}:",
                    style: jxTextStyle.textStyle14(
                      color: colorTextSecondary,
                    ),
                  ),
                ),
              ),
              ...List.generate(momentPost.mentions!.length, (index) {
                return TextSpan(
                  children: <InlineSpan>[
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: NicknameText(
                        uid: momentPost.mentions![index],
                        color: colorTextSecondary,
                        isTappable: false,
                      ),
                    ),
                    if (index != (momentPost.mentions!.length - 1))
                      TextSpan(
                        text: ', ',
                        style:
                            jxTextStyle.textStyle14(color: colorTextSecondary),
                      ),
                  ],
                );
              }),
            ],
          ),
          style: jxTextStyle.textStyle14(color: colorTextSecondary),
        ),
      );
    }

    // 被@的人
    if (momentPost.mentions!.contains(objectMgr.userMgr.mainUser.uid)) {
      return Container(
        padding: const EdgeInsets.only(
          top: 3.0,
          bottom: 3.0,
        ),
        child: Text(
          localized(momentMentionedMe),
          style: jxTextStyle.textStyle14(
            color: colorTextSecondary,
          ),
        ),
      );
    }

    // 都不是
    return const SizedBox();
  }

  Widget buildLikeView(BuildContext context) {
    if (momentLikes.count == 0) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: SvgPicture.asset(
                  'assets/svgs/like_outlined_bold.svg',
                  width: 16.0,
                  height: 16.0,
                  colorFilter: const ColorFilter.mode(
                    momentThemeColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            ...List.generate(momentLikes.count ?? 0, (index) {
              return TextSpan(
                children: <InlineSpan>[
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: NicknameText(
                      uid: momentLikes.list![index],
                      fontSize: Platform.isAndroid
                          ? MFontSize.size14.value
                          : MFontSize.size15.value,
                      fontWeight: MFontWeight.bold5.value,
                      color: momentThemeColor,
                      isTappable: false,
                    ),
                  ),
                  if (index != (momentLikes.count! - 1))
                    TextSpan(
                      text: ', ',
                      style: jxTextStyle.textStyle14(color: momentThemeColor),
                    ),
                ],
              );
            }),
          ],
        ),
        style: jxTextStyle.textStyle14(color: momentThemeColor),
      ),
    );
  }

  Widget buildCommentView(BuildContext context) {
    if (momentCommentDetail.count == 0) return const SizedBox();
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: momentCommentDetail.count,
      itemBuilder: (BuildContext context, int index) {
        MomentComment comment = momentCommentDetail.comments![index];

        bool isReplied =
            comment.replyUserId != null && comment.replyUserId! > 0;

        return GestureDetector(
          onTap: () => onCommentTap(
            context,
            replyUserId: comment.userId!,
            commentId: comment.id,
          ),
          onLongPress: () => onCommentLongPress(
            context,
            commentId: comment.id!,
          ),
          child: OverlayEffect(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 2.0,
                horizontal: 8.0,
              ),
              child: ExtendedText.rich(
                TextSpan(
                  children: <InlineSpan>[
                    WidgetSpan(
                      child: NicknameText(
                        uid: comment.userId!,
                        fontSize: Platform.isAndroid
                            ? MFontSize.size14.value
                            : MFontSize.size15.value,
                        isTappable: false,
                        fontWeight: MFontWeight.bold6.value,
                        color: momentThemeColor,
                      ),
                    ),
                    if (isReplied)
                      TextSpan(
                        text: ' ${localized(reply)} '.toLowerCase(),
                        children: <InlineSpan>[
                          WidgetSpan(
                            child: NicknameText(
                              uid: comment.replyUserId!,
                              isTappable: false,
                              fontSize: Platform.isAndroid
                                  ? MFontSize.size14.value
                                  : MFontSize.size15.value,
                              fontWeight: MFontWeight.bold6.value,
                              color: momentThemeColor,
                            ),
                          ),
                        ],
                      ),
                    TextSpan(
                      text:': ${(comment.content ?? '')}',
                      style: jxTextStyle.textStyle15(color: colorTextPrimary),
                    ),
                  ],
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                joinZeroWidthSpace: true,
                style:
                    jxTextStyle.textStyle15(color: colorTextPrimary).copyWith(
                          overflow: TextOverflow.ellipsis,
                        ),
                overflowWidget: TextOverflowWidget(
                  child: GestureDetector(
                    onTap: () async {
                      Get.to(
                        () => MomentCommentViewMore(
                          name: objectMgr.userMgr
                              .getUserById(comment.userId!)!
                              .nickname,
                          content: comment.content.toString(),
                        ),
                      );
                    },
                    child: Text(
                      localized(details),
                      style: jxTextStyle.textStyle15(
                        color: momentThemeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
