import 'package:flutter/material.dart';

class CustomScrollableListView extends StatelessWidget {
  const CustomScrollableListView({
    super.key,
    required this.children,
    this.physics =
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
    this.shrinkWrap = false,
    this.padding,
    this.separatorGap = 24,
  });

  final List<Widget> children;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final double separatorGap;

  // ListView as an optimisation to the combination of SingleChildScrollView + Column.
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      physics: physics,
      itemCount: children.length,
      itemBuilder: (_, int index) => children[index],
      separatorBuilder: (_, __) => SizedBox(height: separatorGap),
    );
  }
}
