import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Device Care style key-value row for the hero cards' panels: a grey label on the left,
/// a bold value over a grey caption on the right.
///
/// Only the label and the value share a line; the caption sits under them and may use the
/// whole width, so a long caption never pushes the value off its line. When the value itself
/// doesn't fit beside the label (huge amounts, long names, bigger text), it moves under the
/// label instead of being cut off. Amounts and captions wrap rather than truncate, and the
/// value gets two lines before it ellipsizes.
class OneUIKeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;

  /// Shown before [value], e.g. a 20dp brand icon; [leadingSize] is its width.
  final Widget? leading;
  final double leadingSize;

  static const double _gap = 12;
  static const double _leadingGap = 6;

  static const TextStyle labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: OneUITheme.textSecondary,
  );
  static const TextStyle captionStyle = TextStyle(fontSize: 12, color: OneUITheme.textSecondary);

  const OneUIKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.leading,
    this.leadingSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: valueColor ?? OneUITheme.textPrimary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        // Measure with the inherited font (the theme's), exactly as the Text widgets draw.
        final base = DefaultTextStyle.of(context).style;
        double width(String text, TextStyle style) => (TextPainter(
              text: TextSpan(text: text, style: base.merge(style)),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout())
                .width;

        final leadingWidth = leading == null ? 0.0 : leadingSize + _leadingGap;
        final sideBySide =
            width(label, labelStyle) + _gap + leadingWidth + width(value, valueStyle) <= constraints.maxWidth;

        final valueLine = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: _leadingGap)],
            Flexible(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 1), child: Text(label, style: labelStyle)),
                  const SizedBox(width: _gap),
                  Expanded(child: valueLine),
                ],
              )
            else ...[
              Text(label, style: labelStyle),
              const SizedBox(height: 4),
              valueLine,
            ],
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(caption!, textAlign: TextAlign.right, style: captionStyle),
            ],
          ],
        );
      },
    );
  }
}
