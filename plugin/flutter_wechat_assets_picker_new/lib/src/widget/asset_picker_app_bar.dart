// Copyright 2019 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/material.dart';

/// A custom app bar.
/// 自定义的顶栏
class AssetPickerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AssetPickerAppBar({
    super.key,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyActions = true,
    this.brightness,
    this.title,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.actions,
    this.actionsPadding,
    this.height,
    this.blurRadius = 0,
    this.iconTheme,
    this.semanticsBuilder,
  });

  /// Title widget. Typically a [Text] widget.
  /// 标题部件
  final Widget? title;

  /// Leading widget.
  /// 头部部件
  final Widget? leading;

  /// Action widgets.
  /// 尾部操作部件
  final List<Widget>? actions;

  /// This widget appears across the bottom of the app bar.
  /// 显示在顶栏下方的 widget
  final PreferredSizeWidget? bottom;

  /// Padding for actions.
  /// 尾部操作部分的内边距
  final EdgeInsetsGeometry? actionsPadding;

  /// Whether it should imply leading with [BackButton] automatically.
  /// 是否会自动检测并添加返回按钮至头部
  final bool automaticallyImplyLeading;

  /// Whether the [title] should be at the center.
  /// [title] 是否会在正中间
  final bool centerTitle;

  /// Whether it should imply actions size with [effectiveHeight].
  /// 是否会自动使用 [effectiveHeight] 进行占位
  final bool automaticallyImplyActions;

  /// Background color.
  /// 背景颜色
  final Color? backgroundColor;

  /// Height of the app bar.
  /// 高度
  final double? height;

  /// Elevation to [Material].
  /// 设置在 [Material] 的阴影
  final double elevation;

  /// The blur radius applies on the bar.
  /// 顶栏的高斯模糊值
  final double blurRadius;

  /// Set the brightness for the status bar's layer.
  /// 设置状态栏亮度层
  final Brightness? brightness;

  final IconThemeData? iconTheme;

  final Semantics Function(Widget appBar)? semanticsBuilder;

  bool canPop(BuildContext context) =>
      Navigator.of(context).canPop() && automaticallyImplyLeading;

  double get _barHeight => height ?? kToolbarHeight;

  double get effectiveHeight =>
      _barHeight + (bottom?.preferredSize.height ?? 0);

  @override
  Size get preferredSize => Size.fromHeight(effectiveHeight);

  @override
  Widget build(BuildContext context) {
    Widget? titleWidget = title;
    if (centerTitle) {
      titleWidget = Center(child: title);
    }
    final Widget child = Container(
      width: double.maxFinite,
      height: 0, //_barHeight + MediaQuery.of(context).padding.top,
      //padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[

          // Align(
          //   alignment: Alignment.topCenter,
          //   child: Container(
          //     margin: const EdgeInsets.only(top: 8),
          //     width: 31,
          //     height: 4,
          //     decoration: BoxDecoration(
          //       color: const Color(0xFFCCCCCC),
          //       borderRadius: BorderRadius.circular(2),
          //     ),
          //   ),
          // ),

          // if (canPop(context))
          //   PositionedDirectional(
          //     top: 0.0,
          //     bottom: 0.0,
          //     child: leading ?? const BackButton(),
          //   ),

          if (titleWidget != null)
            Align(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: titleWidget,
              ),
            ),
          // PositionedDirectional(
          //   top: 0.0,
          //   bottom: 0.0,
          //   start: canPop(context) ? _barHeight : 0.0,
          //   end: automaticallyImplyActions ? _barHeight : 0.0,
          //   child: Align(
          //     alignment: centerTitle
          //         ? Alignment.center
          //         : AlignmentDirectional.centerStart,
          //     child: DefaultTextStyle(
          //       style: Theme.of(context)
          //           .textTheme
          //           .headline6!
          //           .copyWith(fontSize: 23.0),
          //       maxLines: 1,
          //       softWrap: false,
          //       overflow: TextOverflow.ellipsis,
          //       child: titleWidget,
          //     ),
          //   ),
          // ),
          if (canPop(context) && (actions?.isEmpty ?? true))
            SizedBox(width: _barHeight)
          else if (actions?.isNotEmpty ?? false)
            PositionedDirectional(
              top: 0.0,
              end: 0.0,
              height: _barHeight,
              child: Padding(
                padding: EdgeInsets.zero,
                child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
            ),
        ],
      ),
    );

    return child;
  }

  // Widget _buildAppBar() {
  //   return Container(
  //     width: double.infinity,
  //     height: 58,
  //     alignment: Alignment.center,
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Container(
  //           width: 31,
  //           height: 4,
  //           decoration: BoxDecoration(
  //             color: const Color(0xFFCCCCCC),
  //             borderRadius: BorderRadius.circular(2),
  //           ),
  //         ),
  //         Row(
  //           children: [

  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

/// Wrapper for [AssetPickerAppBar]. Avoid elevation covered by body.
/// 顶栏封装。防止内容块层级高于顶栏导致遮挡阴影。
class AssetPickerAppBarWrapper extends StatelessWidget {
  const AssetPickerAppBarWrapper({
    super.key,
    required this.appBar,
    required this.body,
  });

  final AssetPickerAppBar appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            top: MediaQuery.of(context).padding.top +
                appBar.preferredSize.height,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: body,
            ),
          ),
          Positioned.fill(bottom: null, child: appBar),
        ],
      ),
    );
  }
}
