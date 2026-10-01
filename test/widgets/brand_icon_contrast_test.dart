import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/utils/one_ui_brand_catalog.dart';
import 'package:onespend/widgets/one_ui_brand_icon.dart';

void main() {
  test('foregroundOn picks a dark glyph on light colours and white on dark ones', () {
    expect(OneUIBrandCatalog.foregroundOn(Colors.white), const Color(0xFF1C1C1E));
    expect(OneUIBrandCatalog.foregroundOn(const Color(0xFFFFF59D)), const Color(0xFF1C1C1E));
    expect(OneUIBrandCatalog.foregroundOn(const Color(0xFFE50914)), Colors.white);
    expect(OneUIBrandCatalog.foregroundOn(const Color(0xFF2C3440)), Colors.white);
  });

  testWidgets('a white custom icon draws its monogram in dark', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: OneUIBrandIcon(name: 'Zzz Custom', brandColor: Colors.white, brandPresetId: '__none__')),
    ));
    final text = tester.widget<Text>(find.descendant(of: find.byType(OneUIBrandIcon), matching: find.byType(Text)));
    expect(text.style!.color, const Color(0xFF1C1C1E));
  });

  test('Google presets default to a white background', () {
    for (final id in ['google_one', 'google_workspace']) {
      final preset = OneUIBrandCatalog.findById(id)!;
      expect(preset.color, const Color(0xFFFFFFFF), reason: id);
      expect(OneUIBrandCatalog.foregroundOn(preset.color), isNot(Colors.white));
    }
  });
}
