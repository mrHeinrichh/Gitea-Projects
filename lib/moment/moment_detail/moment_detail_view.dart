import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/sticker/emoji_component.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/component/moment_post_tool_box.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_detail/moment_detail_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/gaussian_image/gaussian_image.dart';

class MomentDetailView extends GetView<MomentDetailController> {
  const MomentDetailView({super.key});

  MomentPost get momentPost => controller.post.value.post!;

  MomentLikes get momentLikes => controller.post.value.likes!;

  MomentCommentDetail get momentCommentDetail =>
      controller.post.value.commentDetail!;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => controller.clickBackAction(),
        child:  GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 5) {
              controller.handleBackNavigation();
            } else if (details.delta.dx < -5) {}
          },
          onTap: controller.inputFocusNode.unfocus,
          child: Scaffold(
            appBar: PrimaryAppBar(
              withBackTxt: false,
              backButtonColor: colorTextPrimary,
              title: localized(momentDetail),
            ),
            resizeToAvoidBottomInset: false,
            body: controller.post.value.post == null
                ? Center(
              child: Text(
                localized(momentPostInvisible),
                style: jxTextStyle.textStyle17(color: colorTextPrimary),
              ),
            )
                : Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller.scrollController,
                    child: Column(
                      children: <Widget>[
                        _buildMomentPostContent(context),
                        GetBuilder(
                          init: controller,
                          id: 'like_view',
                          builder: (_) {
                            return ((momentLikes.count ?? 0) > 0 ||
                                (momentCommentDetail.count ?? 0) > 0)
                                ? Container(
                              decoration: BoxDecoration(
                                color: momentBackgroundColor,
                                borderRadius:
                                BorderRadius.circular(4.0),
                              ),
                              margin: EdgeInsets.only(
                                top: 4.0,
                                left: 56.0,
                                right: 12.0,
                                bottom: 12.0 +
                                    MediaQuery.of(context)
                                        .viewPadding
                                        .bottom,
                              ),
                              width:
                              MediaQuery.of(context).size.width,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: <Widget>[
                                  buildLikeView(context), // 点赞
                                  if ((momentLikes.count ?? 0) > 0 &&
                                      (momentCommentDetail.count ??
                                          0) >
                                          0) //點讚分隔線
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 2.0),
                                      child: Divider(
                                        color: momentBorderColor,
                                        height: 0.5,
                                      ),
                                    ),
                                  // 评论
                                  buildCommentView(context),
                                ],
                              ),
                            )
                                : const SizedBox.shrink();
                          },
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height*0.05,)
                      ],
                    ),
                  ),
                ),
                Obx(
                      () => ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 10),
                      alignment: Alignment.bottomCenter,
                      curve: Curves.easeOut,
                      heightFactor: !controller.isCommentInputExpand.value
                          ? 0.0
                          : 1.0,
                      child: assetInput(context),
                    ),
                  ),
                ),
              ],
            ),
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
          CustomAvatar.normal(
            momentPost.userId ?? 0,
            size: 40.0,
            headMin: Config().headMin,
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
                  ),
                ),
                if (notBlank(momentPost.content?.text))
                  GestureDetector(
                    onLongPress: () =>
                        controller.onMomentPostContentCopy(context),
                    child: OverlayEffect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Text(
                          momentPost.content!.text!,
                          style:
                              jxTextStyle.textStyle17(color: colorTextPrimary),
                        ),
                      ),
                    ),
                  ),
                if (notBlank(momentPost.content?.assets))
                  const SizedBox(height: 3.0),
                if (notBlank(momentPost.content?.assets))
                  if (momentPost.content!.assets!.length == 1)
                    GestureDetector(
                      onTap: () => controller.onAssetPreview(context, 0),
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
    final height =
        ratio >= 1.0 ? null : MediaQuery.of(context).size.width * 0.4;

    if (isVideo) {
      if (ratio < 1.0) {
        width = MediaQuery.of(context).size.width * 0.375;
      }

      return SizedBox(
        width: width,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            GaussianImage(
              src: asset.cover ?? '',
              width: width,
              height: height,
              gaussianPath: asset.gausPath,
              fit: BoxFit.cover,
              mini: Config().sMessageMin,
            ),
            SvgPicture.asset(
              'assets/svgs/video_play_icon.svg',
              width: 40,
              height: 40,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: GaussianImage(
        src: asset.url,
        width: width,
        height: height,
        gaussianPath: asset.gausPath,
        fit: BoxFit.cover,
        mini: Config().sMessageMin,
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
          if (objectMgr.userMgr.isMe(momentPost.userId!))
            GestureDetector(
              onTap: () => controller.onDeleteMoment(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
          const Spacer(),
          GestureDetector(
            key: controller.toolBoxKey,
            onTap: () => toggleToolExpand(context),
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
                        fontSize: MFontSize.size14.value,
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
    return momentLikes.count == 0
        ? const SizedBox()
        : Padding(
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
                            fontSize: MFontSize.size15.value,
                            fontWeight: MFontWeight.bold5.value,
                            color: momentThemeColor,
                            isTappable: false,
                          ),
                        ),
                        if (index != (momentLikes.count! - 1))
                          TextSpan(
                            text: ', ',
                            style: jxTextStyle.textStyle14(
                              color: momentThemeColor,
                            ),
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
    return GetBuilder(
      init: controller,
      id: 'comment_view',
      builder: (_) {
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
              onTap: () => controller.onCommentTap(
                context,
                replyUserId: comment.userId!,
                commentId: comment.id,
              ),
              onLongPress: () => controller.onCommentLongPress(
                context,
                commentId: comment.id!,
              ),
              child: OverlayEffect(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2.0,
                    horizontal: 8.0,
                  ),
                  child: Text.rich(
                    style: jxTextStyle.textStyle15(color: colorTextPrimary),
                    TextSpan(
                      children: <InlineSpan>[
                        WidgetSpan(
                          child: NicknameText(
                            fontSize: Platform.isAndroid
                                ? MFontSize.size14.value
                                : MFontSize.size15.value,
                            uid: comment.userId!,
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
                        TextSpan(text: ': ${comment.content}',style: jxTextStyle.textStyle15(color: colorTextPrimary),),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void toggleToolExpand(BuildContext context) {
    if (controller.isOverlayEnabled.value) {
      controller.isOverlayEnabled.value = false;
      return;
    }

    final box =
        controller.toolBoxKey.currentContext?.findRenderObject() as RenderBox;
    final Offset boxOffset = box.localToGlobal(Offset.zero);

    controller.isOverlayEnabled.value = true;

    controller.overlayEntry = createOverlayEntry(
      context,
      GestureDetector(
        onTap: () => controller.isOverlayEnabled.value = false,
        child: SvgPicture.asset(
          'assets/svgs/moments_more.svg',
          width: 32,
          height: 20,
        ),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: controller.isOverlayEnabled,
        builder: (_, enabled, Widget? __) {
          return MomentPostToolBox(
            isLikePost:
                momentLikes.list?.contains((objectMgr.userMgr.mainUser.uid)) ??
                    false,
            onLikePost: controller.onLikePost,
            onCommentTap: controller.onCommentTap,
            isOverlayEnabled: enabled,
            onEnd: controller.closeToggleToolExpand,
          );
        },
      ),
      left: boxOffset.dx,
      top: boxOffset.dy,
      targetAnchor: Alignment.centerLeft,
      followerAnchor: Alignment.centerRight,
      shouldBlurBackground: false,
      dismissibleCallback: () {
        controller.isOverlayEnabled.value = false;
      },
      LayerLink(),
    );
  }

  Widget assetInput(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 10),
          curve: Curves.easeOut,
          color: colorBackground,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 8.0,
                    bottom: 8.0,
                  ),
                  child: Stack(
                    children: <Widget>[
                      GetBuilder(
                        init: controller,
                        id: 'input_text_field',
                        builder: (_) {
                          return TextField(
                            contextMenuBuilder: textMenuBar,
                            autocorrect: false,
                            enableSuggestions: false,
                            textAlignVertical: TextAlignVertical.center,
                            textAlign: TextAlign.left,
                            maxLines: 10,
                            minLines: 1,
                            focusNode: controller.inputFocusNode,
                            controller: controller.inputController,
                            keyboardType: TextInputType.multiline,
                            scrollPhysics: const ClampingScrollPhysics(),
                            maxLength: 4096,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(4096),
                            ],
                            cursorColor: momentThemeColor,
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 16.0,
                              color: Colors.black,
                              height: 1.25,
                              textBaseline: TextBaseline.alphabetic,
                            ),
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: (controller.commentRepliedUserId !=
                                          null &&
                                      controller.commentRepliedUserId != 0)
                                  ? "${localized(chatOptionsReply)} ${objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(controller.commentRepliedUserId!))}"
                                  : localized(chatInputting),
                              hintStyle: const TextStyle(
                                fontSize: 16.0,
                                color: colorTextSupporting,
                                fontFamily: appFontfamily,
                              ),
                              isDense: true,
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(
                                  style: BorderStyle.none,
                                  width: 0,
                                ),
                              ),
                              isCollapsed: true,
                              counterText: '',
                              contentPadding: const EdgeInsets.only(
                                top: 8,
                                bottom: 8,
                                right: 12 + 24.0,
                                left: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 8.0,
                        bottom: 6.0,
                        child: buildEmojiWidget(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Send Button
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap:
                    controller.hasText.value ? controller.onCommentPost : null,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 6.0,
                    right: 6.0,
                    top: 6.0,
                    bottom: 8.0,
                  ),
                  child: OpacityEffect(
                    child: Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: controller.hasText.value
                            ? momentThemeColor
                            : colorTextPlaceholder,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: SvgPicture.asset(
                        'assets/svgs/send_arrow.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        buildEmojiPanel(context),
      ],
    );
  }

  Widget buildEmojiWidget(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: controller.onEmojiClick,
      child: OpacityEffect(
        child: Container(
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/svgs/${controller.showFaceView.value ? 'input_keyboard' : 'emoji'}.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }

  Widget buildEmojiPanel(BuildContext context) {

    return AnimatedContainer(
      color: colorBackground,
      duration: const Duration(milliseconds: 233),
      curve: Curves.easeOut,
      height:
      controller.showFaceView.value || controller.inputFocusNode.hasFocus
          ? controller.getKeyboardHeight
          : 0,
      child: Column(
        children: <Widget>[
          Expanded(
            child: controller.showFaceView.value
                ? EmojiComponent(
                    onEmojiClick: (String emoji) {
                      controller.addEmoji(emoji);
                    },
                  )
                : const SizedBox(),
          ),
          Container(
            color: colorSurface,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(
              top: 12.0,
              bottom: 12.0 + MediaQuery.of(context).viewPadding.bottom,
              right: 16.0,
              left: 16.0,
            ),
            child: GestureDetector(
              onTap: controller.onTextDeleteTap,
              onLongPress: controller.onTextDeleteLongPress,
              onLongPressEnd: controller.onTextDeleteLongPressEnd,
              child: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/svgs/delete_input.svg',
                  fit: BoxFit.fill,
                  colorFilter: const ColorFilter.mode(
                    colorTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
