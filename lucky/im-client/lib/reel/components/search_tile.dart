import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class SearchTile extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const SearchTile({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: const Icon(
            Icons.access_time_outlined,
            color: JXColors.primaryTextBlack,
            size: 20,
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: jxTextStyle.textStyle17(),
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: const Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: const Icon(
              Icons.close,
              color: JXColors.primaryTextBlack,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
