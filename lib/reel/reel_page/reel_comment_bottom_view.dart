import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_comment_tile.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_appbar.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_chat_field.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_controller.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ShowCommentBottomView extends StatefulWidget {
  const ShowCommentBottomView({
    super.key,
    required this.controller,
  });

  @override
  State<ShowCommentBottomView> createState() => _ShowCommentBottomViewState();

  // final ReelController controller;
  final ReelCommentController controller;
  // final dynamic controllerToPause;
}

class _ShowCommentBottomViewState extends State<ShowCommentBottomView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ObjectMgr.screenMQ!.size.height,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Obx(
              () => Offstage(
                offstage: widget.controller.isCommentExpand.value,
                child: GestureDetector(
                  onTap: () {
                    widget.controller.commentTextEditingController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    color: Colors.transparent,
                    height: ObjectMgr.screenMQ!.size.height / 2,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Obx(
              () => Container(
                padding: EdgeInsets.only(
                    bottom: 52 + MediaQuery.of(context).padding.bottom),
                height: widget.controller.commentMaxHeight.value,
                decoration: const BoxDecoration(
                  color: colorBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    ReelCommentAppBar(
                      controller: widget.controller,
                      title: localized(
                        reelCommentCountTitle,
                        params: [
                          '${widget.controller.post.value.commentCount}'
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Offstage(
                            offstage: widget.controller.post.value.comments.isEmpty,
                            child: ListView.builder(
                              controller: widget.controller.scrollController,
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: widget.controller.post.value.comments.length,
                              itemBuilder: (context, index) {
                                return ReelCommentTile(
                                    comment: widget.controller.post.value.comments[index],
                                    onProfileTap: () async {
                                      if (widget.controller.controllerToPause !=
                                          null) {
                                        widget.controller.controllerToPause
                                            .pause();
                                      }
                                      ReelComment c = widget.controller.post.value.comments[index];

                                      if (objectMgr.userMgr
                                          .isMe(c.userId.value ?? 0)) {
                                        Get.toNamed(
                                          RouteName.reelMyProfileView,
                                          preventDuplicates: false,
                                          arguments: {
                                            "onBack": () {
                                              Navigator.of(context).pop();
                                              if (widget.controller
                                                      .controllerToPause !=
                                                  null) {
                                                widget.controller
                                                    .controllerToPause
                                                    .play();
                                              }
                                            },
                                          },
                                        );
                                      } else {
                                        Get.toNamed(
                                          RouteName.reelProfileView,
                                          preventDuplicates: false,
                                          arguments: {
                                            "userId": c.userId.value,
                                            "onBack": () {
                                              Navigator.of(context).pop();
                                              if (widget.controller
                                                      .controllerToPause !=
                                                  null) {
                                                widget.controller
                                                    .controllerToPause
                                                    .play();
                                              }
                                            },
                                          },
                                        );
                                      }
                                    });
                              },
                            ),
                          ),
                          Offstage(
                            offstage: widget.controller.post.value.comments.isNotEmpty,
                            child: _showNoCommentsMessage(),
                          ),
                        ],
                      ),
                    ),
                    // CustomTextButton(
                    //   'Show More',
                    //   onClick: () async {
                    //     _scrollwidget.controller.animateTo(
                    //       _scrollwidget.controller.position.maxScrollExtent,
                    //       duration: const Duration(milliseconds: 100),
                    //       curve: Curves.linear,
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ),
          widget.controller.commentFocusNode.hasFocus
              ? Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => widget.controller.commentFocusNode.unfocus(),
                    child: const ColoredBox(color: Colors.black45),
                  ),
                )
              : const SizedBox(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: ReelCommentChatField(
                controller: widget.controller.commentTextEditingController,
                focusNode: widget.controller.commentFocusNode,
                onTap: () async {
                  if (widget.controller.commentTextEditingController.text
                          .trim()
                          .isEmpty ||
                      widget.controller.isLoading.value) {
                    return;
                  }

                  await widget.controller.onSendComment(
                      widget.controller.post.value,
                      widget.controller.commentTextEditingController);

                  if (widget.controller.post.value.comments.length > 1) {
                    widget.controller.scrollController.animateTo(
                      widget
                          .controller.scrollController.position.minScrollExtent,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.linear,
                    );
                  }
                  widget.controller.commentFocusNode.unfocus();
                  widget.controller.commentTextEditingController.clear();
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _showNoCommentsMessage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomImage(
            'assets/images/common/no_comment.png',
            isAsset: true,
            size: 80,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              localized(reelNoCommentTitle),
              textAlign: TextAlign.center,
              style: jxTextStyle.textStyleBold16(),
            ),
          ),
          Text(
            localized(reelNoCommentSubTitle),
            textAlign: TextAlign.center,
            style: jxTextStyle.textStyle12(color: colorTextSecondary),
          ),
        ],
      ),
    );
  }
}
