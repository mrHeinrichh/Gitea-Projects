import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class GroupInviteLinkFormSlider extends StatefulWidget {
  final String? title;
  final List<String> sliderHeaderList;
  final double sliderValue;
  final double max;
  final String? bottomTitle;
  final String bottomSubtitle;
  final String? instructionText;
  final Function(double value) onChanged;
  final bool isEnabled;

  const GroupInviteLinkFormSlider({
    super.key,
    this.title,
    required this.sliderHeaderList,
    required this.sliderValue,
    this.max = 4,
    this.bottomTitle,
    required this.bottomSubtitle,
    this.instructionText,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  State<GroupInviteLinkFormSlider> createState() =>
      _GroupInviteLinkFormSliderState();
}

class _GroupInviteLinkFormSliderState extends State<GroupInviteLinkFormSlider> {
  late double _currentSliderValue;
  final Color _activeColor = themeColor;
  final Color _inactiveColor = const Color(0xFFD9D9D9);

  @override
  void initState() {
    super.initState();
    _currentSliderValue = widget.sliderValue;
  }

  @override
  Widget build(BuildContext context) {
    return CustomRoundContainer(
      title: widget.title ?? localized(validTimeLimit),
      bottomText: widget.instructionText ?? localized(linkExpireDetail),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: _buildHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                overlayShape: SliderComponentShape.noOverlay,
                overlayColor: Colors.transparent,
                thumbColor: colorWhite,
                thumbShape: const RoundSliderThumbShape(elevation: 3),
                activeTickMarkColor: _activeColor,
                activeTrackColor: _activeColor,
                inactiveTrackColor: _inactiveColor,
                inactiveTickMarkColor: _inactiveColor,
                disabledThumbColor: colorWhite,
                disabledActiveTrackColor: _inactiveColor,
                disabledInactiveTrackColor: _inactiveColor,
                disabledActiveTickMarkColor: _inactiveColor,
                disabledInactiveTickMarkColor: _inactiveColor,
                trackHeight: 3,
                tickMarkShape: const _LineSliderTickMarkShape(),
              ),
              child: Slider(
                value: _currentSliderValue,
                min: 1,
                max: widget.max,
                divisions: 3,
                onChanged: widget.isEnabled
                    ? (double value) {
                        setState(() => _currentSliderValue = value);
                        widget.onChanged(value);
                      }
                    : null,
              ),
            ),
          ),
          const CustomDivider(),
          CustomListTile(
            text: widget.bottomTitle ?? localized(expirationTime),
            rightText: widget.bottomSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _getText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: MFontWeight.bold4.value,
        fontSize: MFontSize.size11.value,
        color: colorTextSecondary,
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _getText(widget.sliderHeaderList.first),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              widget.sliderHeaderList.length - 2,
              (index) => _getText(widget.sliderHeaderList[index + 1]),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _getText(widget.sliderHeaderList.last),
        ),
      ],
    );
  }
}

class _LineSliderTickMarkShape extends SliderTickMarkShape {
  const _LineSliderTickMarkShape();

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    assert(sliderTheme.trackHeight != null);
    return Size.fromRadius(sliderTheme.trackHeight! / 4);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {
    Color? begin;
    Color? end;
    switch (textDirection) {
      case TextDirection.ltr:
        final bool isTickMarkRightOfThumb = center.dx > thumbCenter.dx;
        begin = isTickMarkRightOfThumb
            ? sliderTheme.disabledInactiveTickMarkColor
            : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkRightOfThumb
            ? sliderTheme.inactiveTickMarkColor
            : sliderTheme.activeTickMarkColor;
        break;
      case TextDirection.rtl:
        final bool isTickMarkLeftOfThumb = center.dx < thumbCenter.dx;
        begin = isTickMarkLeftOfThumb
            ? sliderTheme.disabledInactiveTickMarkColor
            : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkLeftOfThumb
            ? sliderTheme.inactiveTickMarkColor
            : sliderTheme.activeTickMarkColor;
        break;
    }

    final Paint paint = Paint()
      ..color = ColorTween(begin: begin, end: end).evaluate(enableAnimation)!
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    context.canvas.drawLine(Offset(center.dx, center.dy - 4),
        Offset(center.dx, center.dy + 4), paint);
  }
}
