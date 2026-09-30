import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Samsung One UI Compact Toast matching reference screenshot 1:1.
/// Features a centered, compact stadium capsule with frosted glass background,
/// gentle scale and fade transition, and automatic cleanup.
class OneUIToast {
  static OverlayEntry? _currentEntry;

  /// Shows a clean One UI floating capsule toast.
  ///
  /// With [actionLabel] and [onAction] (e.g. "Undo"), a blue text button is shown inside
  /// the capsule and the toast stays up longer (4 s by default) so it can be tapped.
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
    double bottom = 120.0,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final hasAction = actionLabel != null && onAction != null;
    final effectiveDuration =
        duration ?? (hasAction ? const Duration(seconds: 4) : const Duration(milliseconds: 1800));
    // Dismiss existing toast immediately
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _OneUIToastWidget(
        message: message,
        bottom: bottom,
        duration: effectiveDuration,
        actionLabel: hasAction ? actionLabel : null,
        onAction: hasAction
            ? () {
                dismiss();
                onAction();
              }
            : null,
        onDismiss: () {
          if (_currentEntry == entry) {
            _currentEntry?.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Dismiss any currently showing toast immediately.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _OneUIToastWidget extends StatefulWidget {
  final String message;
  final double bottom;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _OneUIToastWidget({
    required this.message,
    required this.bottom,
    required this.duration,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_OneUIToastWidget> createState() => _OneUIToastWidgetState();
}

class _OneUIToastWidgetState extends State<_OneUIToastWidget>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _controller.forward();

    // Auto dismiss after duration
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom > 0
        ? (mediaQuery.viewInsets.bottom + 24.0)
        : (mediaQuery.padding.bottom + widget.bottom);

    return Positioned(
      left: 24,
      right: 24,
      bottom: bottomPadding,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xF025252B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 0.85,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: OneUITheme.textPrimary,
                            letterSpacing: -0.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null) ...[
                        const SizedBox(width: 14),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onAction,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              widget.actionLabel!,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: OneUITheme.accentBlue,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
