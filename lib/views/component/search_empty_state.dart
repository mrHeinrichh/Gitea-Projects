import 'package:flutter/material.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/views/component/custom_image.dart';

class SearchEmptyState extends StatefulWidget {
  const SearchEmptyState({
    super.key,
    this.searchText,
    this.emptyMessage,
  });

  final String? searchText;
  final String? emptyMessage;

  @override
  State<SearchEmptyState> createState() => _SearchEmptyStateState();
}

class _SearchEmptyStateState extends State<SearchEmptyState>
    with WidgetsBindingObserver {
  bool _isKeyboardVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = ObjectMgr.screenMQ!.viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0.0;
    if (isKeyboardVisible != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = isKeyboardVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      padding: EdgeInsets.only(
        top: _isKeyboardVisible
            ? MediaQuery.of(context).size.height * 0.1
            : MediaQuery.of(context).size.height * 0.25,
      ),
      duration: const Duration(milliseconds: 100),
      child: Column(
        children: [
          const CustomImage(
            'assets/images/common/empty_search_icon.png',
            size: 84,
            isAsset: true,
          ),
          const SizedBox(height: 24),
          Text(localized(noResults), style: jxTextStyle.textStyleBold17()),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              widget.emptyMessage ?? localized(oopsNoResults),
              style: jxTextStyle.textStyle17(color: colorTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
