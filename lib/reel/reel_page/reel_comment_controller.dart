import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_mgr.dart';

class ReelCommentController extends GetxController {
  FocusNode commentFocusNode = FocusNode();
  final commentTextEditingController = TextEditingController();
  late Rx<ReelPost> post;
  final scrollController = ScrollController();
  final RxBool _scrollLoading = false.obs;
  RxBool isCommentExpand = false.obs;
  RxBool isLoading = false.obs;
  RxDouble commentMaxHeight = ObjectMgr.screenMQ!.size.height.obs;
  bool _noMoreComments = false;

  final dynamic controllerToPause;
  RxBool commentBtnSheetActive = false.obs;

  ReelCommentController({
    required this.controllerToPause,
    required ReelPost post,
  }) {
    this.post = post.obs;
    scrollController.addListener(_scrollListener);
    _getCommentList();

    commentMaxHeight.value =
        isCommentExpand.value ? ObjectMgr.screenMQ!.size.height * 0.95 : 500;

    ever(
      isCommentExpand,
      (callback) => commentMaxHeight.value =
          isCommentExpand.value ? ObjectMgr.screenMQ!.size.height * 0.95 : 500,
    );
  }

  @override
  onClose() {
    scrollController.dispose();
    commentTextEditingController.dispose();
    commentFocusNode.dispose();
    // posts.clear();
    super.onClose();
  }

  _getCommentList() async {
    await getReelComments(post.value);
  }


  Future<ReelComment?> onSendComment(
    ReelPost post,
    TextEditingController editingController,
  ) async {
    assert(post.id.value != null);
    isLoading.value = true;

    ReelComment? comment =
        await ReelCommentMgr.instance.addComment(post, editingController);
    isLoading.value = false;
    return comment;
  }

  Future<List<ReelComment>?> getReelComments(ReelPost post, {int? lastId}) async {
    if (_noMoreComments) {
      return null;
    }

    isLoading.value = true;
    assert(post.id.value != null);
    int postLength = post.comments.length;

    List<ReelComment>? comments =
        await ReelCommentMgr.instance.getReelComments(post, lastId: lastId);
    isLoading.value = false;
    //posts will be updated
    if (postLength == post.comments.length) _noMoreComments = true;

    return comments;
  }

  void _scrollListener() {
    if (_noMoreComments) return;
    if (_scrollLoading.value) return;

    // pdebug(
    //     "### ${scrollController.position.pixels.toString()} - ${(scrollController.position.maxScrollExtent - 500).toString()}");

    // Check if scrolled to the almost end of the list
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 500) {
      _loadMoreData();
      _scrollLoading.value = true;
    }
  }

  _loadMoreData() async {
    if (_scrollLoading.value) return;
    int? commentId;
    if (post.value.comments.isNotEmpty) {
      ReelComment data = post.value.comments.last;
      commentId = data.commentId.value;
    }
    await getReelComments(post.value, lastId: commentId);

    //等待UI更新让scrollview再度识别
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // pdebug("is loading false");
      _scrollLoading.value = false;
    });
  }

}
