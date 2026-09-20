import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';

/// Bottom multi-selection floating action bar.
/// Streamlined according to user instructions:
/// - Primary bar actions: Share, Delete, More (...)
/// - Secondary options (Move, Lock/Pause) are accessible via the three-dots More menu.
class OneUISelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onMove;
  final VoidCallback? onToggleLock;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMore;
  final GlobalKey? moreButtonKey;

  const OneUISelectionActionBar({
    super.key,
    required this.selectedCount,
    this.onMove,
    this.onToggleLock,
    required this.onShare,
    required this.onDelete,
    required this.onMore,
    this.moreButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;
        final hasSelection = selectedCount > 0;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
            child: DecoratedBox(
              decoration: is3d
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.50),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : const BoxDecoration(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: OneUITheme.blurSigma,
                    sigmaY: OneUITheme.blurSigma,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    height: 64,
                    decoration: BoxDecoration(
                      color: is3d ? null : OneUITheme.floatingColor,
                      gradient: is3d ? OneUIEffectsController.instance.floatingGradient : null,
                      borderRadius: BorderRadius.circular(34),
                      border: is3d ? OneUIEffectsController.instance.floatingBorder : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 1. Share
                        Expanded(
                          child: _buildActionItem(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            isEnabled: hasSelection,
                            onTap: onShare,
                          ),
                        ),

                        // 2. Delete
                        Expanded(
                          child: _buildActionItem(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            isEnabled: hasSelection,
                            color: hasSelection ? OneUITheme.accentRed : null,
                            onTap: onDelete,
                          ),
                        ),

                        // 3. More (...)
                        Expanded(
                          child: _buildActionItem(
                            key: moreButtonKey,
                            icon: Icons.more_vert_rounded,
                            label: 'More',
                            isEnabled: hasSelection,
                            onTap: onMore,
                          ),
                        ),
                      ],
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

  Widget _buildActionItem({
    Key? key,
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = isEnabled
        ? (color ?? OneUITheme.textPrimary)
        : OneUITheme.textSecondary.withValues(alpha: 0.4);

    return InkWell(
      key: key,
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: itemColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
