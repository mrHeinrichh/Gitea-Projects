import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../object/reel.dart';

class DraftPostView extends StatefulWidget {
  const DraftPostView({Key? key}) : super(key: key);

  @override
  State<DraftPostView> createState() => _DraftPostViewState();
}

class _DraftPostViewState extends State<DraftPostView> {
  RxList<ReelData> postList = <ReelData>[].obs;

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
    return Center(
      child: Text(localized(homeToBeContinue)),
    );
  }
}
