import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/utils/one_ui_brand_catalog.dart';

void main() {
  group('Subscription Detail Hero Glow Colors', () {
    test('All popular presets have visible, radiant under-card glow colors', () {
      for (final preset in OneUIBrandCatalog.presets) {
        final glowColor = OneUIBrandCatalog.getGlowColor(
          color: preset.color,
          presetId: preset.id,
          name: preset.name,
        );

        // Glow color must be sufficiently luminous to radiate against dark glass
        expect(
          glowColor.computeLuminance(),
          greaterThanOrEqualTo(0.04),
          reason: 'Preset ${preset.name} (${preset.id}) glow color should be visible',
        );
      }
    });

    test('Dark and black presets resolve to their signature branded glow colors', () {
      // Apple One -> Apple Silver / Platinum
      final appleOneGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFF000000),
        presetId: 'apple_one',
        name: 'Apple One',
      );
      expect(appleOneGlow, equals(const Color(0xFFE5E5EA)));

      // Apple TV+ -> Titanium Silver
      final appleTvGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFF1C1C1E),
        presetId: 'apple_tv',
        name: 'Apple TV+',
      );
      expect(appleTvGlow, equals(const Color(0xFFD4D4D8)));

      // GitHub Copilot -> GitHub Copilot Electric Purple
      final copilotGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFF24292F),
        presetId: 'github_copilot',
        name: 'GitHub Copilot',
      );
      expect(copilotGlow, equals(const Color(0xFF8957E5)));

      // Notion -> Clean Ivory
      final notionGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFF2F3437),
        presetId: 'notion',
        name: 'Notion',
      );
      expect(notionGlow, equals(const Color(0xFFF1F5F9)));

      // Slack -> Vibrant Plum
      final slackGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFF4A154B),
        presetId: 'slack',
        name: 'Slack',
      );
      expect(slackGlow, equals(const Color(0xFF9E2A9B)));

      // X Premium -> Monochrome White
      final xGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFF000000),
        presetId: 'twitter_premium',
        name: 'X Premium',
      );
      expect(xGlow, equals(const Color(0xFFF8FAFC)));

      // Uber One -> Amber Gold
      final uberGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFF000000),
        presetId: 'uber_one',
        name: 'Uber One',
      );
      expect(uberGlow, equals(const Color(0xFFFBBF24)));
    });

    test('All 12 IconPickerScreen swatches have tuned radiant glow colors', () {
      final swatches = [
        const Color(0xFFE50914), // Red
        const Color(0xFF1DB954), // Spotify Green
        const Color(0xFF0066FF), // One UI Blue
        const Color(0xFF8A2BE2), // Purple
        const Color(0xFFFF9500), // Orange
        const Color(0xFF00C7BE), // Teal
        const Color(0xFFFF2D55), // Pink
        const Color(0xFF34AADC), // Light Blue
        const Color(0xFF10A37F), // Mint / OpenAI
        const Color(0xFF2C3440), // Dark Slate
        const Color(0xFF5856D6), // Indigo
        const Color(0xFF555555), // Charcoal
      ];

      for (final swatch in swatches) {
        final glowColor = OneUIBrandCatalog.getGlowColor(color: swatch);
        expect(
          glowColor.computeLuminance(),
          greaterThanOrEqualTo(0.04),
          reason: 'Swatch $swatch should radiate visible glow',
        );
      }

      // Verify dark swatches specifically map to luminous colors
      expect(
        OneUIBrandCatalog.getGlowColor(color: const Color(0xFF2C3440)),
        equals(const Color(0xFF64748B)),
      );
      expect(
        OneUIBrandCatalog.getGlowColor(color: const Color(0xFF555555)),
        equals(const Color(0xFF94A3B8)),
      );
    });

    test('Custom dark color automatically boosts lightness to create visible glow', () {
      // Very dark custom navy
      const darkNavy = Color(0xFF030D26);
      final boostedGlow = OneUIBrandCatalog.getGlowColor(color: darkNavy);

      expect(boostedGlow.computeLuminance(), greaterThan(0.08));
    });

    test('When a subscription like Netflix has its color customized to Green, glow turns Green instead of staying Red', () {
      // Default Netflix (Red)
      final defaultNetflixGlow = OneUIBrandCatalog.getGlowColor(
        color: const Color(0xFFE50914),
        presetId: 'netflix',
        name: 'Netflix',
      );
      expect(defaultNetflixGlow, equals(const Color(0xFFE50914)));

      // Customized Netflix with Spotify Green
      const greenColor = Color(0xFF1DB954);
      final customizedNetflixGlow = OneUIBrandCatalog.getGlowColor(
        color: greenColor,
        presetId: 'netflix',
        name: 'Netflix',
      );
      expect(customizedNetflixGlow, equals(greenColor));

      // Customized Netflix with One UI Blue
      const blueColor = Color(0xFF0066FF);
      final customizedBlueNetflixGlow = OneUIBrandCatalog.getGlowColor(
        color: blueColor,
        presetId: 'netflix',
        name: 'Netflix',
      );
      expect(customizedBlueNetflixGlow, equals(blueColor));
    });

    testWidgets('SubscriptionDetailScreen renders under-card RadialGradient with resolved glow', (WidgetTester tester) async {
      final testSub = Subscription(
        id: 'test_sub',
        name: 'Apple One',
        description: 'All-in-one subscription',
        price: 19.95,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.utilities,
        nextBillingDate: DateTime(2026, 10, 1),
        brandPresetId: 'apple_one',
        brandColorValue: const Color(0xFF000000).toARGB32(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // Find radial gradient containers
      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          if (box.gradient is RadialGradient) {
            final gradient = box.gradient as RadialGradient;
            // Check if gradient colors contain the Apple One silver glow
            return gradient.colors.any((c) => c.r == const Color(0xFFE5E5EA).r && c.g == const Color(0xFFE5E5EA).g);
          }
        }
        return false;
      });

      expect(containerFinder, findsOneWidget);
    });
  });
}
