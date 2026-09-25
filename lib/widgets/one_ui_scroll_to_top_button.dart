import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Floating scroll-to-top circular button matching Screenshot 2.
/// Appears when actively scrolling down past [threshold], and automatically
/// disappears when scrolling stops after [hideDelay].
class OneUIScrollToTopButton extends StatefulWidget {
  final ScrollController scrollController;
  final double threshold;
  final Duration hideDelay;

  const OneUIScrollToTopButton({
    super.key,
    required this.scrollController,
    this.threshold = 120.0,
    this.hideDelay = const Duration(milliseconds: 1000),
  });

  @override
  State<OneUIScrollToTopButton> createState() => _OneUIScrollToTopButtonState();
}

class _OneUIScrollToTopButtonState extends State<OneUIScrollToTopButton> {
  bool _isVisible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant OneUIScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final offset = widget.scrollController.offset;

    if (offset <= widget.threshold) {
      if (_isVisible) {
        _hideTimer?.cancel();
        _hideTimer = null;
        setState(() {
          _isVisible = false;
        });
      }
      return;
    }

    // Actively scrolling past threshold: show button and refresh auto-hide timer
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }

    // Cancel existing timer and restart
    if (_hideTimer?.isActive ?? false) {
      _hideTimer!.cancel();
    }
    _hideTimer = Timer(widget.hideDelay, () {
      if (mounted && _isVisible) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _scrollToTop() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_isVisible) {
      setState(() {
        _isVisible = false;
      });
    }
    widget.scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        return IgnorePointer(
          ignoring: !_isVisible,
          child: AnimatedScale(
            scale: _isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: GestureDetector(
                onTap: _scrollToTop,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                        spreadRadius: 1.0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: OneUITheme.blurSigma,
                        sigmaY: OneUITheme.blurSigma,
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: is3d ? null : OneUITheme.floatingColor,
                          gradient: is3d ? OneUIEffectsController.instance.floatingGradient : null,
                          border: is3d ? OneUIEffectsController.instance.floatingBorder : null,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: OneUITheme.textPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
