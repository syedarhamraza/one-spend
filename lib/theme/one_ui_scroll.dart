import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One UI scrolling: lists stop at their ends and stretch when pulled past them (Android's
/// overscroll, from [OneUIScrollBehavior]), and a fling glides a little further and slows
/// down more gently than Flutter's default.
///
/// With [headerSnap] (the distance a big header collapses, see [bigHeader]), a page never
/// comes to rest with its header half collapsed: when the finger lifts, a fling that would
/// stop there turns into a spring that carries on, in the same motion, to fully open or
/// fully closed, whichever is nearer.
class OneUIScrollPhysics extends ClampingScrollPhysics {
  /// Friction of a fling; Flutter's default is 0.015.
  static const double flingFriction = 0.011;

  /// How far a big header collapses: `OneUICollapsibleHeaderDelegate`'s default expanded
  /// height (270) minus its collapsed height (92).
  static const double bigHeaderCollapse = 270.0 - 92.0;

  /// For pages whose `CustomScrollView` starts with a big header.
  static const OneUIScrollPhysics bigHeader = OneUIScrollPhysics(headerSnap: bigHeaderCollapse);

  /// Critically damped, so a snap settles without overshooting.
  static final SpringDescription _snapSpring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 150,
    ratio: 1.0,
  );

  /// The scroll range at the top of the page that a header snaps across, if any.
  final double? headerSnap;

  const OneUIScrollPhysics({super.parent = const AlwaysScrollableScrollPhysics(), this.headerSnap});

  @override
  OneUIScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      OneUIScrollPhysics(parent: buildParent(ancestor), headerSnap: headerSnap);

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) return super.createBallisticSimulation(position, velocity);
    final tolerance = toleranceFor(position);
    final pixels = position.pixels;
    final fling = velocity.abs() < tolerance.velocity ||
            (velocity > 0 && pixels >= position.maxScrollExtent) ||
            (velocity < 0 && pixels <= position.minScrollExtent)
        ? null
        : ClampingScrollSimulation(position: pixels, velocity: velocity, friction: flingFriction, tolerance: tolerance);

    final snap = headerSnap;
    if (snap != null) {
      // Where the page would come to rest, and how far the header can collapse here.
      final end = fling?.x(double.maxFinite) ?? pixels;
      final reach = math.min(snap, position.maxScrollExtent);
      if (reach > 1 && end > 0.5 && end < reach - 0.5) {
        final target = end < reach / 2 ? 0.0 : reach;
        return ScrollSpringSimulation(_snapSpring, pixels, target, velocity, tolerance: tolerance);
      }
    }
    return fling;
  }
}

/// The app's scroll behaviour: [OneUIScrollPhysics] everywhere, with the stretch overscroll
/// Material 3 gives Android. Set on `MaterialApp.router`; screens that set `physics` use
/// [OneUIScrollPhysics] too ([OneUIScrollPhysics.bigHeader] under a big header).
class OneUIScrollBehavior extends MaterialScrollBehavior {
  const OneUIScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const OneUIScrollPhysics();
}
