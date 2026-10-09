import 'package:flutter/material.dart';

/// One UI scrolling: lists stop at their ends and stretch when pulled past them (Android's
/// overscroll, from [OneUIScrollBehavior]), and a fling glides a little further and slows
/// down more gently than Flutter's default.
class OneUIScrollPhysics extends ClampingScrollPhysics {
  /// Friction of a fling; Flutter's default is 0.015.
  static const double flingFriction = 0.011;

  const OneUIScrollPhysics({super.parent = const AlwaysScrollableScrollPhysics()});

  @override
  OneUIScrollPhysics applyTo(ScrollPhysics? ancestor) => OneUIScrollPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    if (position.outOfRange) return super.createBallisticSimulation(position, velocity);
    if (velocity.abs() < tolerance.velocity) return null;
    if (velocity > 0 && position.pixels >= position.maxScrollExtent) return null;
    if (velocity < 0 && position.pixels <= position.minScrollExtent) return null;
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      friction: flingFriction,
      tolerance: tolerance,
    );
  }
}

/// The app's scroll behaviour: [OneUIScrollPhysics] everywhere, with the stretch overscroll
/// Material 3 gives Android. Set on `MaterialApp.router`; screens that set `physics` use
/// [OneUIScrollPhysics] too.
class OneUIScrollBehavior extends MaterialScrollBehavior {
  const OneUIScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const OneUIScrollPhysics();
}
