import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

class ReelCommentMgr {

  ReelCommentMgr._();

  static final ReelCommentMgr _instance = ReelCommentMgr._();

  static ReelCommentMgr get instance => _instance;

  Future<ReelComment?> addComment(
    ReelPost post,
    TextEditingController editingController,
  ) async {
    assert(post.id.value != null);
    // isLoading.value = true;
    ReelComment? comment;
    try {
      comment = await createComments(
        postId: post.id.value!,
        comment: editingController.text,
      );
      if (comment != null) {
        post.comments.insert(0, comment);
        post.commentCount.value = post.commentCount.value! + 1;
      }
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      // isLoading.value = false;
    }

    return comment;
  }

  Future<List<ReelComment>?> getReelComments(ReelPost post, {int? lastId}) async {
    try {
      CommentData? res = await getComments(postId: post.id.value!, lastId: lastId);
      // pdebug('----getReelComments---${res}');

      if (res.comments != null) {
        if (post.comments.isNotEmpty && lastId != null) {
          post.comments.addAll(res.comments!);
        } else {
          post.comments.assignAll(res.comments!);
        }
        post.commentCount.value = res.totalCount;
      }

      return res.comments;
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      return null;
    }
  }
}