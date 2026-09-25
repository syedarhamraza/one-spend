import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';

/// Standardized Samsung One UI 9 Floating Stadium "Cancel | Save" Pill
/// Matches reference screenshots with translucent smoked glass backdrop,
/// optional 3D specular highlight & shadows, and tactile haptic response.
class OneUIFloatingCancelSavePill extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final bool canSave;
  final String cancelLabel;
  final String saveLabel;

  const OneUIFloatingCancelSavePill({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.canSave = true,
    this.cancelLabel = 'Cancel',
    this.saveLabel = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        return Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: OneUITheme.floatingShadow,
            ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: OneUIEffectsController.instance.blurSigma,
                sigmaY: OneUIEffectsController.instance.blurSigma,
              ),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: is3d ? null : OneUITheme.floatingColor,
                  gradient: is3d ? OneUIEffectsController.instance.floatingGradient : null,
                  borderRadius: BorderRadius.circular(30),
                  border: is3d
                      ? OneUIEffectsController.instance.floatingBorder
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 0.85,
                        ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cancel Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onCancel();
                        },
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
                        splashColor: Colors.white.withValues(alpha: 0.08),
                        highlightColor: Colors.white.withValues(alpha: 0.04),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            cancelLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: OneUITheme.textPrimary,
                            ),
                          ),
                        ),
                      ),

                      // 1px Subtle Vertical Divider
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),

                      // Save Button
                      InkWell(
                        onTap: canSave
                            ? () {
                                HapticFeedback.mediumImpact();
                                onSave?.call();
                              }
                            : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
                        splashColor: Colors.white.withValues(alpha: 0.08),
                        highlightColor: Colors.white.withValues(alpha: 0.04),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            saveLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: canSave ? OneUITheme.textPrimary : const Color(0xFF8E8E93),
                            ),
                          ),
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
}
