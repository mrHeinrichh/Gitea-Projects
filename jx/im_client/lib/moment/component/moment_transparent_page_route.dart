import 'package:flutter/material.dart';

class MomentHeroTransparentRoute extends PageRoute<void> {
  MomentHeroTransparentRoute({
    required this.builder,
    required RouteSettings settings,
  }) : super(settings: settings, fullscreenDialog: true);

  final WidgetBuilder builder;

  static const int TRANSITION_DURATION_TIMES = 200;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String get barrierLabel => '';

  @override
  bool get barrierDismissible => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      const Duration(milliseconds: TRANSITION_DURATION_TIMES);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final result = builder(context);
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.linear,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: result,
    );
  }
}
