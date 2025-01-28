import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class SearchEmptyState extends StatefulWidget {
  const SearchEmptyState({
    Key? key,
    this.searchText,
    this.emptyMessage,
  }) : super(key: key);

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
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
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
              : MediaQuery.of(context).size.height * 0.25),
      duration: const Duration(milliseconds: 100),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/svgs/search_empty_icon.svg',
            width: 148,
            height: 148,
          ),
          const SizedBox(height: 16),
          Text(
            localized(noResults),
            style: jxTextStyle.textStyleBold16(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              widget.emptyMessage ?? localized(oopsNoResults),
              style:
                  jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
