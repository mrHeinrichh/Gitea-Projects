import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ReelProfileInfoItem extends StatefulWidget {
  final String label;
  final int count;
  final VoidCallback? onClick;

  const ReelProfileInfoItem({
    super.key,
    required this.count,
    required this.label,
    this.onClick,
  });

  @override
  State<ReelProfileInfoItem> createState() => _ReelProfileInfoItemState();
}

class _ReelProfileInfoItemState extends State<ReelProfileInfoItem> {
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
    // if (widget.profileData?.profile == null) return SizedBox();
    return GestureDetector(
      onTap: widget.onClick,
      // child: OpacityEffect( //hide it for now, will show it in next phase
      child: Row(
        children: [
          Text(
            '${widget.count}',
            style: jxTextStyle.textStyleBold17(),
          ),
          const SizedBox(width: 4),
          Text(
            widget.label,
            style: jxTextStyle.textStyleBold14(color: colorTextSecondary),
          ),
        ],
      ),
      // ),
    );
  }
}
