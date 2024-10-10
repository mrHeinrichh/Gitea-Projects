import 'package:flutter/material.dart';

///多列式瀑布流
class StaggeredRowsView extends StatefulWidget {
  ///多列式瀑布流
  const StaggeredRowsView({
    super.key,
    required this.itemBuilder,
    required this.childWidth,
    this.childHeights,
    this.childCount = 1,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.listpadding,
  });

  ///列表项回调函数
  final Widget Function(int index) itemBuilder;

  ///列表项宽度列表
  final double childWidth;

  ///列表项高度列表
  final List<double>? childHeights;

  //列表项数量
  final int childCount;

  ///列数
  final int crossAxisCount;

  ///上下距离
  final double mainAxisSpacing;

  ///左右距离
  final double crossAxisSpacing;

  ///列表内间距
  final EdgeInsets? listpadding;

  @override
  State<StaggeredRowsView> createState() => _StaggeredRowsViewState();
}

class _StaggeredRowsViewState extends State<StaggeredRowsView> {
  @override
  Widget build(BuildContext context) {
    var subIndexs = <List<int>>[];
    var childHeights = widget.childHeights;
    if (childHeights != null) {
      //列表项高度列表
      List<double> subHeights = [];
      //初始化
      for (int i = 0; i < widget.crossAxisCount; i++) {
        subIndexs.add(<int>[]);
        subHeights.add(0);
      }
      //插入列表项
      for (int i = 0; i < childHeights.length; i++) {
        int index = -1;
        double min = -1;
        for (int j = 0; j < widget.crossAxisCount; j++) {
          if (min == -1 || min > subHeights[j]) {
            min = subHeights[j];
            index = j;
          }
        }
        subIndexs[index].add(i);
        subHeights[index] += childHeights[i];
      }
    } else {
      //列表项数量(平均分配)
      //初始化
      for (int i = 0; i < widget.crossAxisCount; i++) {
        subIndexs.add(<int>[]);
      }
      for (int i = 0; i < widget.childCount; i++) {
        subIndexs[i % widget.crossAxisCount].add(i);
      }
    }
    var children = <Widget>[];
    for (int i = 0; i < widget.crossAxisCount; i++) {
      children.add(
        Container(
          margin: EdgeInsets.only(left: i > 0 ? widget.crossAxisSpacing : 0),
          width: widget.childWidth,
          child: ListView.builder(
            padding: widget.listpadding,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: subIndexs[i].length,
            itemBuilder: (context, index) {
              int idx = subIndexs[i][index];
              double top =
                  idx >= widget.crossAxisCount ? widget.mainAxisSpacing : 0;
              return Container(
                margin: EdgeInsets.only(top: top),
                child: widget.itemBuilder(idx),
              );
            },
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
