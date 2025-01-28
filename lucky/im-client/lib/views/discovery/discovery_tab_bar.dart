import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';

class DiscoveryTabBar extends StatefulWidget {
  final TabController controller;
  final List tabTitles;
  final Function(int) onTabSelected;
  final EdgeInsetsGeometry? labelPadding;
  final isScrollable;

  const DiscoveryTabBar({
    Key? key,
    required this.controller,
    required this.tabTitles,
    required this.onTabSelected,
    this.labelPadding,
    this.isScrollable = false,
  }) : super(key: key);

  @override
  State<DiscoveryTabBar> createState() => _DiscoveryTabBarState();
}

class _DiscoveryTabBarState extends State<DiscoveryTabBar> {
  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabAlignment: TabAlignment.center,
      isScrollable: widget.isScrollable,
      controller: widget.controller,
      dividerColor: Colors.transparent,
      labelPadding: widget.labelPadding ??
          const EdgeInsets.only(left: 16, top: 12, right: 16).w,
      splashFactory: NoSplash.splashFactory,
      indicator: const BoxDecoration(),
      indicatorWeight: 0,
      tabs: List.generate(
        widget.tabTitles.length,
        (index) {
          bool isTabSelected = (widget.controller.index == index);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImText(
                widget.tabTitles[index],
                color: isTabSelected ? ImColor.black : ImColor.black48,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              ImGap.vGap(9),
              Container(
                width: 34.w,
                height: 3.w,
                decoration: BoxDecoration(
                  color:
                      isTabSelected ? ImColor.accentColor : Colors.transparent,
                  borderRadius: ImBorderRadius.only(topLeft: 6, topRight: 6),
                ),
              ),
            ],
          );
        },
      ),
      onTap: widget.onTabSelected,
    );
  }
}
