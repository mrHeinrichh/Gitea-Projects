import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/views/component/no_content_view.dart';

class DraftPostView extends StatefulWidget {
  const DraftPostView({super.key});

  @override
  State<DraftPostView> createState() => _DraftPostViewState();
}

class _DraftPostViewState extends State<DraftPostView> {
  RxList<ReelPost> postList = <ReelPost>[].obs;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const NoContentView();
  }
}
