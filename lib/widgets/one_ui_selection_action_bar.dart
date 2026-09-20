import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Bottom multi-selection floating action bar matching Screenshot 1 1:1.
/// Displays 5 actions: Move, Lock (Pause), Share, Delete, More.
class OneUISelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onMove;
  final VoidCallback onToggleLock;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMore;

  const OneUISelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onMove,
    required this.onToggleLock,
    required this.onShare,
    required this.onDelete,
    required this.onMore,
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
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionItem(
                    icon: Icons.drive_file_move_outlined,
                    label: 'Move',
                    isEnabled: hasSelection,
                    onTap: onMove,
                  ),
                  _buildActionItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Lock',
                    isEnabled: hasSelection,
                    onTap: onToggleLock,
                  ),
                  _buildActionItem(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    isEnabled: hasSelection,
                    onTap: onShare,
                  ),
                  _buildActionItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isEnabled: hasSelection,
                    color: hasSelection ? OneUITheme.accentRed : null,
                    onTap: onDelete,
                  ),
                  _buildActionItem(
                    icon: Icons.more_vert_rounded,
                    label: 'More',
                    isEnabled: hasSelection,
                    onTap: onMore,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
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
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                fontSize: 11.5,
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
