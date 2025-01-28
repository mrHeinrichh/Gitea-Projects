import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final Function() callBack;

  const ExpandableText({Key? key, required this.text, required this.callBack})
      : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text);

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: constraints.maxWidth);

        final isTextOverflow = textPainter.didExceedMaxLines;

        return Stack(
          children: [
            Text(
              widget.text,
              overflow:
                  _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              maxLines: _isExpanded ? null : 2,
              style: jxTextStyle.textStyle16(),
            ),
            if (isTextOverflow)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (!_isExpanded) {
                      widget.callBack();
                    }
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            spreadRadius: 8,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                            blurStyle: BlurStyle.inner),
                      ],
                    ),
                    child: Text(
                      _isExpanded ? 'Less' : 'More',
                      style: jxTextStyle.textStyle16(color: accentColor),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
