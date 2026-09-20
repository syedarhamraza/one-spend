import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Samsung One UI 9 Signature Floating Modal Container & Dialog System.
///
/// Matches Samsung One UI Reference Screenshots 1:1:
/// - 16dp margins on left, right, and bottom.
/// - 28dp fully rounded corners.
/// - Dynamic 3D elevation / rim highlight or clean flat appearance based on OneUIEffectsController.
/// - Standard "Cancel  |  Action" footer.
class OneUIFloatingModal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const OneUIFloatingModal({
    super.key,
    required this.child,
    this.padding,
  });

  /// Shows a generic One UI floating modal bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      useRootNavigator: true,
      builder: (ctx) => OneUIFloatingModal(
        child: builder(ctx),
      ),
    );
  }

  /// Shows a One UI Signature Confirmation / Action Dialog matching Screenshot 1:1
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    String? message,
    Widget? customContent,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Delete',
    Color? confirmTextColor,
    VoidCallback? onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => OneUIFloatingModal(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),

            // Optional Message Body
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 15.5,
                  color: Color(0xFFC4C4CA),
                  height: 1.35,
                  letterSpacing: -0.2,
                ),
              ),
            ],

            // Optional Custom Content (e.g. text inputs)
            if (customContent != null) ...[
              const SizedBox(height: 16),
              customContent,
            ],

            const SizedBox(height: 20),

            // Footer: Cancel  |  Confirm
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 18,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx, true);
                      onConfirm?.call();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: confirmTextColor ?? Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + keyboardInset),
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: is3d ? null : const Color(0xFF212123),
                  gradient: is3d
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF262628),
                            Color(0xFF1C1C1E),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(28),
                  border: is3d
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.85,
                        )
                      : null,
                  boxShadow: is3d
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : const [],
                ),
                padding: padding ?? const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
