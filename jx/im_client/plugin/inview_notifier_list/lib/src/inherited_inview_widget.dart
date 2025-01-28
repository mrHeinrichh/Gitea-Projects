//This widget passes down the InViewState down the widget tree;
import 'package:flutter/widgets.dart';

import 'package:inview_notifier_list/src/inview_state.dart';

class InheritedInViewWidget extends InheritedWidget {
  final InViewState? inViewState;
  @override
  final Widget child;

  const InheritedInViewWidget({Key? key, this.inViewState, required this.child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedInViewWidget oldWidget) => false;
}
