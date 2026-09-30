import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Arms a [OneUISliverScrollAnchor] for a short window after an interaction.
class OneUIScrollAnchorController {
  final Duration window;
  final Stopwatch _clock = Stopwatch();

  OneUIScrollAnchorController({this.window = const Duration(milliseconds: 450)});

  /// Call right before a change that resizes content above the anchor (e.g. in a tap handler).
  void hold() => _clock
    ..reset()
    ..start();

  bool get isHolding => _clock.isRunning && _clock.elapsed < window;
}

/// Zero-size sliver that keeps whatever follows it fixed on screen while [controller] is
/// holding: if the slivers above grow or shrink, it corrects the scroll offset during the
/// same layout pass, so there is no one-frame jump.
///
/// Place it directly before the sliver the user is interacting with.
class OneUISliverScrollAnchor extends LeafRenderObjectWidget {
  final OneUIScrollAnchorController controller;

  const OneUISliverScrollAnchor({super.key, required this.controller});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSliverScrollAnchor(controller);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSliverScrollAnchor).controller = controller;
  }
}

class _RenderSliverScrollAnchor extends RenderSliver {
  _RenderSliverScrollAnchor(this.controller);

  OneUIScrollAnchorController controller;

  /// Scroll extent of everything above this sliver at the last layout.
  double? _lastPreceding;

  @override
  void performLayout() {
    final preceding = constraints.precedingScrollExtent;
    final last = _lastPreceding;
    _lastPreceding = preceding;
    if (controller.isHolding && last != null) {
      final delta = preceding - last;
      if (delta.abs() > 0.01) {
        // The viewport shifts the offset by delta and lays out again in this frame.
        geometry = SliverGeometry(scrollOffsetCorrection: delta);
        return;
      }
    }
    geometry = SliverGeometry.zero;
  }
}

/// Bottom spacer for a scroll view that uses [OneUISliverScrollAnchor]: normally [minExtent]
/// tall, but while [controller] is holding it stretches to fill the rest of the viewport, so
/// content shrinking below the anchor can't clamp the scroll offset and drag everything down.
/// The extra space is released as the user scrolls away from it.
class OneUISliverScrollAnchorSpacer extends LeafRenderObjectWidget {
  final OneUIScrollAnchorController controller;
  final double minExtent;

  const OneUISliverScrollAnchorSpacer({super.key, required this.controller, this.minExtent = 140});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAnchorSpacer(controller, minExtent);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderAnchorSpacer)
      ..controller = controller
      ..minExtent = minExtent;
  }
}

class _RenderAnchorSpacer extends RenderSliver {
  _RenderAnchorSpacer(this.controller, this.minExtent);

  OneUIScrollAnchorController controller;
  double minExtent;
  double _kept = 0;

  @override
  void performLayout() {
    // Space between the content above and the bottom of the viewport.
    final visibleGap = constraints.remainingPaintExtent;
    // Holding: fill the gap. Otherwise: never grow, and shrink as the gap shrinks (scrolling up).
    _kept = controller.isHolding ? visibleGap : (visibleGap < _kept ? visibleGap : _kept);
    final extent = _kept > minExtent ? _kept : minExtent;
    final paintExtent = calculatePaintOffset(constraints, from: 0, to: extent);
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: paintExtent,
      maxPaintExtent: extent,
      cacheExtent: calculateCacheOffset(constraints, from: 0, to: extent),
    );
  }
}
