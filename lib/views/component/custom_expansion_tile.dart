import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class CustomExpansionTile extends StatefulWidget {
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsets? childPadding;

  const CustomExpansionTile({
    super.key,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.title,
    required this.children,
    this.leading,
    this.trailing,
    this.childPadding,
  });

  @override
  CustomExpansionTileState createState() => CustomExpansionTileState();
}

class CustomExpansionTileState extends State<CustomExpansionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
            widget.onExpansionChanged(_isExpanded);
          },
          leading: widget.leading,
          title: widget.title,
          trailing: SizedBox(
            width: 48,
            height: 28,
            child: widget.trailing ??
                FlutterSwitch(
                  activeColor: themeColor,
                  width: 48.0,
                  height: 28.0,
                  toggleSize: 24,
                  value: _isExpanded,
                  onToggle: (value) {
                    setState(() {
                      _isExpanded = value;
                    });
                    widget.onExpansionChanged(_isExpanded);
                  },
                ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.all(0),
            //padding: widget.childPadding ?? const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: widget.children,
            ),
          ),
      ],
    );
  }
}
