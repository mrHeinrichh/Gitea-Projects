import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_controller.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_picture_widget.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class MomentMyPostsCell extends StatefulWidget {
  final int index;
  final MomentPosts momentPost;
  final bool isShowDate;

  const MomentMyPostsCell({
    super.key,
    required this.momentPost,
    required this.index,
    this.isShowDate = false,
  });

  @override
  State<MomentMyPostsCell> createState() => _MomentMyPostsCellState();
}

class _MomentMyPostsCellState extends State<MomentMyPostsCell> {
  late MomentPosts post;

  MomentMyPostsController controller = Get.find<MomentMyPostsController>();

  MomentPost get momentPost => post.post!;

  @override
  void initState() {
    super.initState();
    post = MomentPosts()
      ..post = widget.momentPost.post
      ..commentDetail = widget.momentPost.commentDetail
      ..likes = widget.momentPost.likes;
    objectMgr.momentMgr.on(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);
    // 因為MOMENT_POST_UPDATE發送機制是判斷moment_mgr中的postList做比對，更新才送，
    // 但MyPosts頁面的postList是自己維護的，所以要監聽MOMENT_MY_POST_UPDATE
    objectMgr.momentMgr.on(MomentMgr.MOMENT_MY_POST_UPDATE, onMyPostUpdate);
  }

  @override
  void dispose() {
    objectMgr.momentMgr.off(MomentMgr.MOMENT_POST_UPDATE, onPostUpdate);
    objectMgr.momentMgr.off(MomentMgr.MOMENT_MY_POST_UPDATE, onMyPostUpdate);
    super.dispose();
  }

  void onMyPostUpdate(_, __, Object? detail) {
    if (detail is! MomentDetailUpdate || detail.postId != post.post?.id) {
      return;
    }

    switch (detail.typ) {
      case MomentNotificationType.likeNotificationType: //強提醒
        post.likes!.list!.add(detail.content!.userId!);
        post.likes!.count =
            post.likes!.list?.length ?? (post.likes!.count ?? 0 + 1);
        break;
      case MomentNotificationType.commentNotificationType:
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
        break;
      case MomentNotificationType.deleteCommentNotificationType:
        post.commentDetail!.comments!.removeWhere(
          (element) => element.id == detail.typId,
        );
        post.commentDetail!.count = post.commentDetail?.comments?.length ??
            (post.commentDetail!.count ?? 1 - 1);
        post.commentDetail!.totalCount = (post.commentDetail?.totalCount ??
                post.commentDetail!.totalCount ??
                1) -
            1;
        // 更新通知列表里的消息为删除类型
        // final index = notificationList.indexWhere(
        //       (element) => element.typId == detail.typId,
        // );
        // if (index != -1) {
        //   notificationList[index].typ =
        //       MomentNotificationType.deleteCommentNotificationType;
        // }
        break;
      case MomentNotificationType.deletePostNotificationType:
        // final index = notificationList.indexWhere(
        //       (element) => element.typId == detail.typId,
        // );
        // if (index != -1) {
        //   notificationList[index].typ =
        //       MomentNotificationType.deletePostNotificationType;
        // }
        break;
      case MomentNotificationType.deleteLikeNotificationType: //取消點讚
        post.likes!.list!.removeWhere(
          (element) => element == detail.content!.userId!,
        );
        post.likes!.count = post.likes!.list?.length;
        break;
      case MomentNotificationType.reLikeLikeNotificationType: //重新點贊
        post.likes!.list!.add(detail.content!.userId!);
        post.likes!.count =
            post.likes!.list?.length ?? (post.likes!.count ?? 0 + 1);
        break;
      default:
        break;
    }

    for (int i = 0; i < controller.postList.length; i++) {
      if (controller.postList[i].post!.id == post.post?.id) {
        controller.postList[i] = post;
      }
    }

    //Update my posts local cache.
    objectMgr.momentMgr
        .updateMyPostSharePreferenceForAPost(post.post!.userId!, post);

    if (mounted) setState(() {});
  }

  void onPostUpdate(_, __, Object? updatedPost) {
    if (updatedPost is! MomentPosts || updatedPost.post?.id != post.post?.id) {
      return;
    }

    post = updatedPost;

    for (int i = 0; i < controller.postList.length; i++) {
      if (controller.postList[i].post!.id == post.post?.id) {
        controller.postList[i] = post;
      }
    }

    //Update my posts local cache.
    objectMgr.momentMgr
        .updateMyPostSharePreferenceForAPost(post.post!.userId!, post);

    if (mounted) setState(() {});
  }

  Widget buildDateText(BuildContext context, int millisecondsSinceEpoch) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    List<TextSpan> ts = [];
    bool isMandarin =
        AppLocalizations(objectMgr.langMgr.currLocale).isMandarin();

    if (DateTime(date.year, date.month, date.day) != today ||
        controller.userId != objectMgr.userMgr.mainUser.uid) {
      if (isMandarin &&
          DateTime(date.year, date.month, date.day) == yesterday &&
          controller.userId == objectMgr.userMgr.mainUser.uid) {
        ts.add(
          TextSpan(
            text: localized(myChatYesterday),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        );
      } else {
        ts.add(
          TextSpan(
            text: date.day.toString(),
            style: TextStyle(
              fontSize: MFontSize.size24.value,
              fontWeight: MFontWeight.bold4.value,
              color: colorTextPrimary,
            ),
          ),
        );
        ts.add(
          TextSpan(
            text: " ",
            style: TextStyle(
              fontSize: 8,
              fontWeight: MFontWeight.bold4.value,
              color: colorTextPrimary,
            ),
          ),
        );
        ts.add(
          TextSpan(
            style: jxTextStyle.textStyleBold10(
              fontWeight: MFontWeight.bold5.value,
            ),
            text: isMandarin
                ? "${date.month}${localized(myChatMonth2)}"
                : controller.monthAbbreviations[date.month - 1],
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: ts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isShowDate && widget.index != 0)
          const SizedBox(
            height: 15,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: (momentPost.content!.assets != null &&
                      momentPost.content!.assets!.isNotEmpty) ||
                  widget.index == 0
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.22,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: widget.isShowDate
                  ? buildDateText(context, momentPost.createdAt!)
                  : const SizedBox(),
            ),

            ///Image or Video
            if (momentPost.content!.assets != null &&
                momentPost.content!.assets!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.onCellTap(
                    widget.index,
                    RouteName.momentMyPostsNested,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 80,
                  height: 80,
                  color: colorBackground3,
                  child: Stack(
                    children: [
                      MomentMyPostsPictureWidget(
                        width: 80,
                        momentContentDetail: momentPost.content!.assets!,
                        space: 1,
                      ),

                      /// Visibility Icon
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                            padding: const EdgeInsets.only(right: 6, bottom: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 13,
                                    offset: Offset(0, 0),
                                    spreadRadius: 3,
                                    blurStyle: BlurStyle.normal,
                                  ),
                                ],
                              ),
                              child:
                                  objectMgr.userMgr.isMe(momentPost.userId!) &&
                                          (momentPost.visibility !=
                                              MomentVisibility.public.value)
                                      ? SvgPicture.asset(
                                          momentPost.visibility ==
                                                  MomentVisibility.private.value
                                              ? 'assets/svgs/moment_private.svg'
                                              : 'assets/svgs/tag_friends.svg',
                                          width: 16.0,
                                          height: 16.0,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.white,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                            )),
                      ),
                    ],
                  ),
                ),
              ),

            ///鏈結圖片
            if ((notBlank(momentPost.content?.metadata) && momentPost.content?.metadata!.title != MomentMgr.MOMENT_NO_LINK_CONTENT)
                && (momentPost.content!.assets == null || momentPost.content!.assets!.isEmpty))
              GestureDetector(
                onTap: () {
                  controller.onCellTap(widget.index, RouteName.momentDetail);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 64,
                  height: 64,
                  color: colorBackground3,
                  child: momentPost.content!.metadata!.hasMedia &&
                          momentPost.content?.metadata!.imageWidth != null &&
                          momentPost.content?.metadata!.imageHeight != null
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4.0),
                              topRight: Radius.circular(4.0),
                              bottomRight: Radius.circular(4.0),
                              bottomLeft: Radius.circular(4.0),
                            ),
                            child: MomentCellMedia(
                              url: momentPost.content!.metadata!.image!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              gausPath:
                                  momentPost.content!.metadataGausBlurHash,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          child: const Image(
                            image: AssetImage(
                                'assets/images/moments/moment_link_no_image.png'),
                            fit: BoxFit.fill,
                            width: 48,
                            height: 48,
                          ),
                        ),
                ),
              ),

            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  controller.onCellTap(widget.index, RouteName.momentDetail);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: momentPost.content!.assets != null && momentPost.content!.assets!.isNotEmpty
                      ? SizedBox(  /// With Assets
                          height: 64,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              momentPost.content!.text!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                      : Container( /// Without Assets
                          color: colorBackground3,
                          height: (notBlank(momentPost.content?.metadata) && momentPost.content?.metadata!.title != MomentMgr.MOMENT_NO_LINK_CONTENT)
                              ? 64
                              : null,
                          child: Padding(
                              padding: EdgeInsets.only(
                                left: (notBlank(momentPost.content?.metadata) && momentPost.content?.metadata!.title != MomentMgr.MOMENT_NO_LINK_CONTENT)?4.0:10.0,
                                right: 10,
                                top:  10.0,
                                bottom: 10.0,
                              ),
                              child: Stack(
                                alignment: AlignmentDirectional.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: notBlank(
                                                momentPost.content?.metadata) &&
                                            momentPost
                                                    .content?.metadata!.title !=
                                                MomentMgr.MOMENT_NO_LINK_CONTENT
                                        ? Text(
                                            (momentPost.content?.text != null &&
                                                    momentPost.content!.text!
                                                        .isNotEmpty)
                                                ? momentPost.content!.text!
                                                : momentPost.content?.metadata!
                                                        .title ??
                                                    Uri.parse(momentPost
                                                                .content
                                                                ?.metadata!
                                                                .url ??
                                                            '')
                                                        .host
                                                        .toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            momentPost.content!.text!,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                  ),

                                  /// Visibility Icon
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: objectMgr.userMgr
                                                .isMe(momentPost.userId!) &&
                                            (momentPost.visibility !=
                                                MomentVisibility.public.value)
                                        ? SvgPicture.asset(
                                            momentPost.visibility ==
                                                    MomentVisibility
                                                        .private.value
                                                ? 'assets/svgs/moment_private.svg'
                                                : 'assets/svgs/tag_friends.svg',
                                            width: 16.0,
                                            height: 16.0,
                                            colorFilter: const ColorFilter.mode(
                                              Color(0x60000000),
                                              BlendMode.srcIn,
                                            ),
                                          )
                                        : const SizedBox(),
                                  ),
                                ],
                              )),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}
