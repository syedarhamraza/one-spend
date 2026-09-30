import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_budget_card.dart';

void main() {
  group('OneUIBudgetCard.trackColorAt', () {
    test('matches the gradient ends and stops', () {
      expect(OneUIBudgetCard.trackColorAt(0), OneUIBudgetCard.trackColors.first);
      expect(OneUIBudgetCard.trackColorAt(1), OneUIBudgetCard.trackColors.last);
      expect(OneUIBudgetCard.trackColorAt(1.5), OneUIBudgetCard.trackColors.last);
      expect(OneUIBudgetCard.trackColorAt(0.5), OneUIBudgetCard.trackColors[4]); // apricot stop
    });

    test('moves from blue to red as spending rises', () {
      double hue(double t) => HSLColor.fromColor(OneUIBudgetCard.trackColorAt(t)).hue;
      expect(hue(0.2), inInclusiveRange(200, 240)); // blue
      expect(hue(0.7), inInclusiveRange(15, 40)); // orange
      final red = hue(0.95);
      expect(red < 10 || red > 350, isTrue);
    });
  });

  group('OneUITheme.glowTint', () {
    test('greys, black and white fall back to the default glow', () {
      expect(OneUITheme.glowTint(const Color(0xFF000000)), OneUITheme.glowDefault);
      expect(OneUITheme.glowTint(const Color(0xFFFFFFFF)), OneUITheme.glowDefault);
      expect(OneUITheme.glowTint(const Color(0xFF808080)), OneUITheme.glowDefault);
    });

    test('dark saturated colours are lifted, hue is kept', () {
      const ruby = Color(0xFF8B0000);
      final tinted = HSLColor.fromColor(OneUITheme.glowTint(ruby));
      expect(tinted.lightness, closeTo(0.45, 0.01));
      expect(tinted.hue, closeTo(HSLColor.fromColor(ruby).hue, 1));
    });
  });
}
