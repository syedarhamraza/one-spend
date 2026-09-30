import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';

/// Floating glass search capsule that sits above the keyboard (Subscriptions, Settings).
/// Shows a clear button while [controller] has text.
class OneUIFloatingSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after the text is cleared with the ✕ button.
  final VoidCallback? onCleared;
  final bool autofocus;

  const OneUIFloatingSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'What are you looking for?',
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: OneUITheme.floatingShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: OneUITheme.blurSigma, sigmaY: OneUITheme.blurSigma),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: is3d ? null : OneUITheme.floatingColor,
              gradient: is3d ? OneUITheme.floatingGradient : null,
              borderRadius: BorderRadius.circular(32),
              border: OneUITheme.floatingBorder,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmitted,
                    onChanged: onChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(color: Color(0xFF8E95B8), fontSize: 16, fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => controller.text.isEmpty
                      ? const SizedBox.shrink()
                      : Semantics(
                          button: true,
                          label: 'Clear search',
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              controller.clear();
                              onChanged?.call('');
                              onCleared?.call();
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
