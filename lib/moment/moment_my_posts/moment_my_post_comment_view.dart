import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_create/moment_publish_dialog.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class MomentMyPostCommentView extends StatefulWidget {
  final MomentPosts post;

  const MomentMyPostCommentView({
    super.key,
    required this.post,
  });

  @override
  State<MomentMyPostCommentView> createState() =>
      _MomentMyPostCommentViewState();
}

class _MomentMyPostCommentViewState extends State<MomentMyPostCommentView> {
  TextEditingController textEditingController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();
  final Rx<bool> isSending = false.obs;
  final Rx<bool> isDone = false.obs;

  bool isShowLoading = false;
  bool isValid = true;

  @override
  void initState() {
    super.initState();
    textEditingController.addListener(() {
      setState(() {});
    });

    textEditingController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    textEditingController.removeListener(_onTextChanged);
    textEditingController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    if (textEditingController.text.length >= 4096) {
      isValid = false;
      Toast.showToast(localized(errorMaxCharInput));
    } else {
      isValid = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // onShowLoadingDialog(context);
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 0),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextField(
                  focusNode: inputFocusNode,
                  autofocus: true,
                  maxLines: null,
                  minLines: 1,
                  cursorColor: themeColor,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  controller: textEditingController,
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (!inputFocusNode.hasFocus) {
                inputFocusNode.requestFocus();
              }
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: const SizedBox(),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              color: Colors.white,
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context, "none");
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 11.5),
                        child: OpacityEffect(
                          child: Text(
                            localized(buttonCancel),
                            style: jxTextStyle.textStyleBold17(
                              color: themeColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 11.5),
                        child: Text(
                          localized(momentComment),
                          style: jxTextStyle.textStyleBold17(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 11.5),
                        child: GestureDetector(
                          onTap: () {
                            onCommentPost();
                          },
                          child: OpacityEffect(
                            child:Text(
                              localized(send),
                              style: jxTextStyle.textStyleBold17(
                                color: textEditingController.text.isEmpty
                                    ? colorTextPlaceholder
                                    : themeColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onShowLoadingDialog(BuildContext context) {
    isSending.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Obx(
          () => MomentPublishDialog(
            isSending: isSending.value,
            isDone: isDone.value,
          ),
        );
      },
    );
    isShowLoading = true;
  }

  void onCloseLoadingDialog(BuildContext context) {
    if (isShowLoading) {
      Navigator.of(context).pop();
      isShowLoading = false;
    }
  }

  void onCommentPost() async {
    if (textEditingController.text.trim().isEmpty) {
      return;
    }

    final result = await objectMgr.momentMgr.onCommentPost(
      widget.post.post!.id!,
      textEditingController.text.trim(),
      replyUserId: 0,
    );

    onShowLoadingDialog(Get.context!);

    if (result) {
      final commentDetail = await objectMgr.momentMgr.getMomentCommentDetail(
        widget.post.post!.id!,
        limit: 1000,
      );
      if (commentDetail == null) {
        widget.post.commentDetail!.totalCount =
            widget.post.commentDetail!.totalCount! + 1;
        widget.post.commentDetail!.comments!.add(
          MomentComment(
            id: 0,
            userId: objectMgr.userMgr.mainUser.uid,
            postId: widget.post.post!.id,
            replyUserId: 0,
            content: textEditingController.text,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        objectMgr.momentMgr.updateMoment(widget.post);
        closeKeyboard();
        return;
      }

      widget.post.commentDetail = commentDetail;
      objectMgr.momentMgr.updateMoment(widget.post);
      closeKeyboard();
      isDone.value = true;
      isSending.value = true;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      isDone.value = false;
      isSending.value = false;
      onCloseLoadingDialog(context);
      Navigator.pop(context);
    });
  }

  void closeKeyboard() {
    textEditingController.clear();
    inputFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
