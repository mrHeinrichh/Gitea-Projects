import 'package:flutter/widgets.dart';

class CustomScrollPhysics extends BouncingScrollPhysics {
  const CustomScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  // @override
  // CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
  //   return CustomScrollPhysics(parent: buildParent(ancestor));
  // }

  // @override
  // double get minFlingVelocity => 800.0;

  // @override
  // double get maxFlingVelocity => 5000.0;

  // @override
  // double carriedMomentum(double existingVelocity) {
  //   return existingVelocity * 3;
  // }

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Increase the offset proportionally to the scroll speed
    return position.pixels <= position.minScrollExtent ||  position.pixels >= position.maxScrollExtent? offset : offset * 1.5;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Keep the default boundary behavior
    return super.applyBoundaryConditions(position, value);
  }
}