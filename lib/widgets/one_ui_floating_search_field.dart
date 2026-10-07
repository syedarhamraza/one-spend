import 'package:flutter/material.dart';
import 'one_ui_glass_surface.dart';
import '../core/haptics/haptics.dart';

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
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {

    return OneUIGlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      height: 56,
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
                              Haptics.tap();
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
    );
  }
}
