// Copyright 2019 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/material.dart';

/// Built a slide page transition for the picker.
/// 为选择器构造一个上下进出的页面过渡动画
class CameraPickerPageRoute<T> extends PageRoute<T> {
  CameraPickerPageRoute({
    required this.builder,
    this.transitionCurve = Curves.easeOut,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.barrierColor,
    this.barrierDismissible = false,
    this.barrierLabel,
    this.maintainState = true,
    this.opaque = true,
    this.canTransitionFromPredicate,
    bool fullscreenDialog = false,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          fullscreenDialog: fullscreenDialog,
        );

  final WidgetBuilder builder;

  final Curve transitionCurve;
  @override
  final Duration transitionDuration;

  @override
  final Color? barrierColor;
  @override
  final bool barrierDismissible;
  @override
  final String? barrierLabel;
  @override
  final bool opaque;
  @override
  final bool maintainState;

  final bool Function(TransitionRoute<dynamic>)? canTransitionFromPredicate;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      canTransitionFromPredicate?.call(previousRoute) ?? false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(curve: transitionCurve, parent: animation),
      ),
      child: child,
    );
    // return SlideTransition(
    //   position: Tween<Offset>(
    //     begin: const Offset(1, 0),
    //     end: Offset.zero,
    //   ).animate(
    //     CurvedAnimation(curve: transitionCurve, parent: animation),
    //   ),
    //   child: child,
    // );
  }
}
