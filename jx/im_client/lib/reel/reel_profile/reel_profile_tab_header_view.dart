import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';

class ReelProfileTabBar extends SliverPersistentHeaderDelegate {
  final bool isMe;
  final TabController? tabController;
  final List tabBarList;

  ReelProfileTabBar({
    this.isMe = false,
    this.tabController,
    required this.tabBarList,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ReelProfileTabHeaderView(
      isMe: isMe,
      tabController: tabController,
      tabBarList: tabBarList,
    );
  }

  @override
  double get maxExtent => 46;

  @override
  double get minExtent => 46;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class ReelProfileTabHeaderView extends StatefulWidget {
  final bool isMe;
  final TabController? tabController;
  final List tabBarList;

  const ReelProfileTabHeaderView({
    super.key,
    this.isMe = false,
    this.tabController,
    required this.tabBarList,
  });

  @override
  State<ReelProfileTabHeaderView> createState() =>
      _ReelProfileTabHeaderViewState();
}

class _ReelProfileTabHeaderViewState extends State<ReelProfileTabHeaderView> {
  final _categoryList = [localized(latest), localized(hottest)];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    widget.tabController?.addListener(_handleTabChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.tabController?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted && widget.tabController!.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorBackground,
      padding: const EdgeInsets.only(top: 12),
      child: Stack(
        children: [
          TabBar(
            overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
            physics: const NeverScrollableScrollPhysics(),
            controller: widget.tabController,
            indicatorWeight: 0,
            indicator: const BoxDecoration(),
            splashFactory: NoSplash.splashFactory,
            labelPadding: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            isScrollable: !widget.isMe,
            tabAlignment: widget.isMe ? TabAlignment.fill : TabAlignment.start,
            tabs: List.generate(widget.tabBarList.length, (int index) {
              bool isSelected = widget.tabController?.index == index;

              return SizedBox(
                width: MediaQuery.sizeOf(context).width / 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (index == 0 && isSelected)
                        // ? showPopUpMenuDialog(isSelected)
                        ? tempCustomImage(index, isSelected)
                        : index == 0
                            ? tempCustomImage(index, isSelected)
                            : CustomImage(
                                'assets/svgs/${widget.tabBarList[index]}.svg',
                                size: 24,
                                color: isSelected
                                    ? colorTextPrimary
                                    : colorTextSecondary,
                              ),
                    Opacity(
                      opacity: isSelected ? 1 : 0,
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: colorTextPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomDivider(),
          ),
        ],
      ),
    );
  }

  Widget tempCustomImage(index, isSelected) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 3),
      child: CustomImage(
        'assets/svgs/${widget.tabBarList[index]}.svg',
        // size: 24,
        color: isSelected ? colorTextPrimary : colorTextSecondary,
      ),
    );
  }

  Widget showPopUpMenuDialog(bool isSelected) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton(
        color: Colors.transparent,
        initialValue: _selectedCategoryIndex,
        offset: Offset(-48, _selectedCategoryIndex == 0 ? 45 : 90),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 130),
        elevation: 0,
        itemBuilder: (BuildContext context) => _buildPopupMenuItems(),
        onSelected: (value) {
          _selectedCategoryIndex = value;
        },
        child: CustomImage(
          'assets/svgs/reel_post.svg',
          size: 24,
          color: isSelected ? colorTextPrimary : colorTextSecondary,
        ),
      ),
    );
  }

  List<PopupMenuItem<int>> _buildPopupMenuItems() {
    return List.generate(
      _categoryList.length,
      (int index) => PopupMenuItem<int>(
        value: index,
        height: 0,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: _getBorderRadius(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: colorWhite,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFD0D0D0),
                  width: 0.5,
                ),
              ),
            ),
            child: OpacityEffect(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_categoryList[index]),
                  if (_selectedCategoryIndex == index)
                    CustomImage(
                      'assets/svgs/check1.svg',
                      size: 22,
                      color: themeColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius(int index) {
    if (index == 0) {
      return const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      );
    } else if (index == _categoryList.length - 1) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    } else {
      return BorderRadius.zero;
    }
  }
}
