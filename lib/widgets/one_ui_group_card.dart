import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUIGroupItem {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? customSubtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const OneUIGroupItem({
    this.leading,
    required this.title,
    this.subtitle,
    this.customSubtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });
}

class OneUIGroupCard extends StatelessWidget {
  final List<OneUIGroupItem> items;
  final String? headerTitle;
  final EdgeInsetsGeometry? margin;

  const OneUIGroupCard({
    super.key,
    required this.items,
    this.headerTitle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerTitle != null)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 8, top: 18),
                child: Text(
                  headerTitle!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ),
            Container(
              margin: margin ?? const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: OneUITheme.cardColor,
                borderRadius: OneUITheme.cardBorderRadius,
                border: OneUITheme.cardBorder,
                boxShadow: OneUITheme.cardShadow,
              ),
              child: Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isLast = index == items.length - 1;

                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: item.onTap,
                          onLongPress: item.onLongPress,
                          borderRadius: BorderRadius.vertical(
                            top: index == 0 ? const Radius.circular(26) : Radius.zero,
                            bottom: isLast ? const Radius.circular(26) : Radius.zero,
                          ),
                          splashColor: Colors.white.withValues(alpha: 0.06),
                          highlightColor: Colors.white.withValues(alpha: 0.03),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                if (item.leading != null) ...[
                                  item.leading!,
                                  const SizedBox(width: 16),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                          color: OneUITheme.textPrimary,
                                        ),
                                      ),
                                      if (item.customSubtitle != null) ...[
                                        const SizedBox(height: 2),
                                        item.customSubtitle!,
                                      ] else if (item.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.subtitle!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.normal,
                                            color: item.subtitleColor ?? OneUITheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                if (item.trailing != null)
                                  item.trailing!
                                else
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: OneUITheme.textTertiary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          indent: item.leading != null ? 58 : 16,
                          endIndent: 16,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
