import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_floating_menu.dart';
import 'one_ui_status_bar_scrim.dart';

/// Reusable action item for One UI top header bar
class OneUIHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double? size;
  final GlobalKey? actionKey;

  const OneUIHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        key: actionKey,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: size ?? 21,
            color: OneUITheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Samsung One UI 9 Signature Collapsible Header Delegate.
///
/// Features:
/// 1. [hasBigHeader == true] (Main Pages):
///    - Initial (unscrolled): Big centered title perfectly centered vertically between the status bar
///      and the action bar row. Buttons (< and actions) sit directly above the first card.
///    - Scrolled: Big header fades out; the buttons row travels with the scrolling cards up to the pinned
///      top bar; the small title fades in beside the back button (or at left: 20 if no back button).
///    - Deep scroll: Small title hides INSTANTLY; buttons gain 3D floating pill backgrounds matching the navbar.
/// 2. [hasBigHeader == false] (Sub Setting Pages):
///    - Compact top bar with `< Title` (no big viewing area).
///    - Deep scroll: Title hides INSTANTLY; buttons gain 3D floating pill backgrounds.
class OneUICollapsibleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final bool hasBigHeader;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final GlobalKey? actionsPillKey;
  final double expandedHeight;
  final double collapsedHeight;
  final bool isSelectionMode;
  final Widget? selectionLeading;
  final Widget? selectionTrailing;

  const OneUICollapsibleHeaderDelegate({
    required this.title,
    this.subtitle,
    this.hasBigHeader = true,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.actionsPillKey,
    this.expandedHeight = 270.0, // Balanced One UI viewing area with reduced bottom space
    this.collapsedHeight = 92.0,  // Compact top bar height including status bar
    this.isSelectionMode = false,
    this.selectionLeading,
    this.selectionTrailing,
  });

  @override
  double get maxExtent => hasBigHeader ? expandedHeight : collapsedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;

    return _OneUIHeaderContent(
      title: title,
      subtitle: subtitle,
      hasBigHeader: hasBigHeader,
      showBackButton: showBackButton,
      onBack: onBack,
      actions: actions,
      actionsPillKey: actionsPillKey,
      shrinkOffset: shrinkOffset,
      topPadding: topPadding,
      expandedHeight: maxExtent,
      collapsedHeight: minExtent,
      isSelectionMode: isSelectionMode,
      selectionLeading: selectionLeading,
      selectionTrailing: selectionTrailing,
    );
  }

  @override
  bool shouldRebuild(covariant OneUICollapsibleHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.hasBigHeader != hasBigHeader ||
        oldDelegate.showBackButton != showBackButton ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.actions != actions ||
        oldDelegate.actionsPillKey != actionsPillKey ||
        oldDelegate.isSelectionMode != isSelectionMode ||
        oldDelegate.selectionLeading != selectionLeading ||
        oldDelegate.selectionTrailing != selectionTrailing;
  }
}

class _OneUIHeaderContent extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool hasBigHeader;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final GlobalKey? actionsPillKey;
  final double shrinkOffset;
  final double topPadding;
  final double expandedHeight;
  final double collapsedHeight;
  final bool isSelectionMode;
  final Widget? selectionLeading;
  final Widget? selectionTrailing;

  const _OneUIHeaderContent({
    required this.title,
    this.subtitle,
    required this.hasBigHeader,
    required this.showBackButton,
    this.onBack,
    this.actions,
    this.actionsPillKey,
    required this.shrinkOffset,
    required this.topPadding,
    required this.expandedHeight,
    required this.collapsedHeight,
    this.isSelectionMode = false,
    this.selectionLeading,
    this.selectionTrailing,
  });

  @override
  State<_OneUIHeaderContent> createState() => _OneUIHeaderContentState();
}

class _OneUIHeaderContentState extends State<_OneUIHeaderContent> {
  ScrollPosition? _position;
  double _lastPixels = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (_position != newPosition) {
      _position?.removeListener(_onScroll);
      _position = newPosition;
      _position?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final pixels = _position?.pixels ?? 0.0;
    // During active collapse (0-175px), SliverPersistentHeader already rebuilds with shrinkOffset.
    // Only setState when in deep scroll territory (>175px) or transitioning out of it.
    if (pixels > 175.0 || _lastPixels > 175.0) {
      _lastPixels = pixels;
      setState(() {});
    } else {
      _lastPixels = pixels;
    }
  }

  /// Builds the back button with clean 3D or flat One UI styling
  Widget _buildBackButton(BuildContext context, double pillProgress) {
    if (!widget.showBackButton) return const SizedBox.shrink();
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    final buttonContent = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: pillProgress > 0.05
            ? (is3d ? null : OneUITheme.floatingColor.withValues(alpha: pillProgress * 0.65))
            : Colors.transparent,
        gradient: (is3d && pillProgress > 0.05)
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x9935353A).withValues(alpha: pillProgress * 0.60),
                  const Color(0xB31E1E22).withValues(alpha: pillProgress * 0.70),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: is3d
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.15 * pillProgress),
                width: 0.85,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: OneUITheme.textPrimary,
      ),
    );

    return GestureDetector(
      onTap: widget.onBack ?? () => Navigator.maybePop(context),
      behavior: HitTestBehavior.opaque,
      child: pillProgress > 0.05
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: OneUITheme.blurSigma * pillProgress,
                  sigmaY: OneUITheme.blurSigma * pillProgress,
                ),
                child: buttonContent,
              ),
            )
          : buttonContent,
    );
  }

  /// Builds the right action buttons pill with clean 3D or flat One UI styling
  Widget _buildActionPill(BuildContext context, double pillProgress) {
    if (widget.actions == null || widget.actions!.isEmpty) {
      return const SizedBox.shrink();
    }
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    final pillContent = Container(
      key: widget.actionsPillKey,
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: pillProgress > 0.05
            ? (is3d ? null : OneUITheme.floatingColor.withValues(alpha: pillProgress * 0.65))
            : Colors.transparent,
        gradient: (is3d && pillProgress > 0.05)
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x9935353A).withValues(alpha: pillProgress * 0.60),
                  const Color(0xB31E1E22).withValues(alpha: pillProgress * 0.70),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: is3d
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.15 * pillProgress),
                width: 0.85,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < widget.actions!.length; i++) ...[
            widget.actions![i],
            if (i < widget.actions!.length - 1)
              const SizedBox(width: 4.0),
          ],
        ],
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: OneUIFloatingMenu.isOpen,
      builder: (context, isMenuOpen, child) {
        return AnimatedOpacity(
          opacity: isMenuOpen ? 0.0 : 1.0,
          duration: Duration(milliseconds: isMenuOpen ? 100 : 160),
          curve: isMenuOpen ? Curves.easeIn : Curves.easeOut,
          child: child!,
        );
      },
      child: pillProgress > 0.05
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: OneUITheme.blurSigma * pillProgress,
                  sigmaY: OneUITheme.blurSigma * pillProgress,
                ),
                child: pillContent,
              ),
            )
          : pillContent,
    );
  }

  /// Small Title in top bar
  Widget _buildSmallTitle(double smallTitleOpacity) {
    if (smallTitleOpacity <= 0.01) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: smallTitleOpacity,
      child: Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: OneUITheme.textPrimary,
        ),
      ),
    );
  }

  /// Big centered viewing header with generous space and fixed height to prevent overflow
  Widget _buildBigHeader(double bigHeaderOpacity) {
    if (!widget.hasBigHeader || bigHeaderOpacity <= 0.01) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: bigHeaderOpacity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 34.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: OneUITheme.textPrimary,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: OneUITheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = widget.topPadding;
    final double currentOffset = (_position?.hasPixels == true
            ? _position!.pixels
            : widget.shrinkOffset)
        .clamp(0.0, double.infinity);

    final double bigHeaderOpacity;
    final double smallTitleOpacity;
    final double pillProgress;

    // Keep top space identical to before (~75dp below status bar), while bottom space is reduced
    const double bigHeaderHeight = 75.0;
    final double bigHeaderTop = topPadding + 75.0;

    if (widget.hasBigHeader) {
      // 1. Big header fades out gracefully as user scrolls
      bigHeaderOpacity = (1.0 - (currentOffset / 100.0)).clamp(0.0, 1.0);

      // 2. Small title:
      // Fades in between 50px and 115px as the action bar row travels up to the top.
      // Stays fully visible while in top bar (115px to 190px).
      // On deep scroll (> 190px), hides INSTANTLY!
      if (currentOffset <= 50.0) {
        smallTitleOpacity = 0.0;
      } else if (currentOffset < 115.0) {
        smallTitleOpacity = ((currentOffset - 50.0) / 65.0).clamp(0.0, 1.0);
      } else if (currentOffset <= 190.0) {
        smallTitleOpacity = 1.0;
      } else {
        // Hides instantly on deep scroll!
        smallTitleOpacity = 0.0;
      }

      // 3. Floating 3D Pill Progress: appears smoothly with scroll as user scrolls deeper!
      if (currentOffset <= 190.0) {
        pillProgress = 0.0;
      } else {
        pillProgress = ((currentOffset - 190.0) / 60.0).clamp(0.0, 1.0);
      }
    } else {
      // Sub setting pages: no big header, compact top bar from the start
      bigHeaderOpacity = 0.0;

      // Small title: visible at top (0 to 50px) -> hides INSTANTLY on deep scroll (> 50px)!
      if (currentOffset <= 50.0) {
        smallTitleOpacity = 1.0;
        pillProgress = 0.0;
      } else {
        smallTitleOpacity = 0.0;
        pillProgress = ((currentOffset - 50.0) / 50.0).clamp(0.0, 1.0);
      }
    }

    return ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 0. Status Bar Scrim (Edge-to-Edge Progressive Blur & Gradient Scrim, strictly 80% of status bar)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OneUIStatusBarScrim(),
          ),

          // 1. Big Centered Header (Strictly centered vertically in viewing area)
          if (widget.hasBigHeader && bigHeaderOpacity > 0.01)
            Positioned(
              top: bigHeaderTop,
              left: 0,
              right: 0,
              height: bigHeaderHeight,
              child: _buildBigHeader(bigHeaderOpacity),
            ),

          // 2. Action Bar Row (Buttons & Small Title OR Selection Controls)
          // Anchored to bottom: 4.0 of the sliver, directly above the first card!
          Positioned(
            bottom: 4.0,
            left: 20.0,
            right: 20.0,
            height: 44.0,
            child: widget.isSelectionMode
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.selectionLeading != null) widget.selectionLeading!,
                      const Spacer(),
                      if (widget.selectionTrailing != null) widget.selectionTrailing!,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Back button (if enabled)
                      if (widget.showBackButton) ...[
                        _buildBackButton(context, pillProgress),
                        const SizedBox(width: 10.0),
                      ],

                      // Center / Left: Small Title
                      // If no back button, starts directly at left: 20 on screen!
                      // If back button, starts beside the back button!
                      Expanded(
                        child: _buildSmallTitle(smallTitleOpacity),
                      ),

                      // Right: Action Buttons Pill (if actions present)
                      if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                        const SizedBox(width: 8.0),
                        _buildActionPill(context, pillProgress),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
