import 'package:flutter/material.dart';

/// A money amount for a row's trailing slot: one line, at most [maxWidth] wide, shrinking
/// to fit when the currency has large units (e.g. "₫999,000,000") instead of overflowing
/// the row. Short amounts render at full size.
class OneUIFitAmount extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  const OneUIFitAmount(this.text, {super.key, required this.style, this.maxWidth = 120});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(text, maxLines: 1, style: style),
      ),
    );
  }
}
