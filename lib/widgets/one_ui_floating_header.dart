import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUIFloatingHeader extends StatelessWidget {
  final String title;
  final Widget? leadingIcon;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onMore;
  final List<Widget>? customActions;

  const OneUIFloatingHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onBack,
    this.onSearch,
    this.onMore,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left back pill button (if onBack provided)
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: OneUIEffectsController.instance.blurSigma,
                    sigmaY: OneUIEffectsController.instance.blurSigma,
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xCC202126),
                      shape: BoxShape.circle,
                      border: OneUITheme.subtleBorder,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 26,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Center pill with Icon + Title
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: OneUIEffectsController.instance.blurSigma,
                  sigmaY: OneUIEffectsController.instance.blurSigma,
                ),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xCC202126),
                    borderRadius: BorderRadius.circular(24),
                    border: OneUITheme.subtleBorder,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      if (leadingIcon != null) ...[
                        leadingIcon!,
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: OneUITheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right pill with Search & More actions (matching Screenshot 2)
          if (customActions != null || onSearch != null || onMore != null) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: OneUIEffectsController.instance.blurSigma,
                  sigmaY: OneUIEffectsController.instance.blurSigma,
                ),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xCC202126),
                    borderRadius: BorderRadius.circular(24),
                    border: OneUITheme.subtleBorder,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: customActions ??
                        [
                          if (onSearch != null)
                            IconButton(
                              icon: const Icon(Icons.search_rounded, size: 22),
                              color: OneUITheme.textPrimary,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: onSearch,
                            ),
                          if (onSearch != null && onMore != null)
                            const SizedBox(width: 4),
                          if (onMore != null)
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, size: 22),
                              color: OneUITheme.textPrimary,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: onMore,
                            ),
                        ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
