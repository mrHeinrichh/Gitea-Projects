import 'package:flutter/material.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool expandEnable;

  const ExpandableText({
    required this.text,
    required this.style,
    this.expandEnable = true,
    super.key,
  });

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final text = TextSpan(text: widget.text, style: widget.style);
        final textPainter = TextPainter(
          text: text,
          maxLines: 5,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final textWidget = Text(
          widget.text,
          style: widget.style,
          maxLines: _isExpanded ? null : 5,
        );

        if (textPainter.didExceedMaxLines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              textWidget,
              if (widget.expandEnable)
                Container(
                  margin: const EdgeInsets.only(
                    top: 6.0,
                    bottom: 2.0,
                  ),
                  child: InkWell(
                    child: Text(
                      _isExpanded
                          ? localized(momentTextCollapse)
                          : localized(momentTextExpand),
                      style: jxTextStyle.textStyle17(
                        color: momentThemeColor,
                      ),
                    ),
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                ),
            ],
          );
        } else {
          return textWidget;
        }
      },
    );
  }
}
