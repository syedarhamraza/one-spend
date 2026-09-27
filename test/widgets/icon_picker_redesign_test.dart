import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/screens/icon_picker_screen.dart';
import 'package:onespend/utils/one_ui_brand_catalog.dart';
import 'package:onespend/widgets/one_ui_brand_icon.dart';
import 'package:onespend/widgets/one_ui_icon_picker_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('Brand Catalog & Vector Asset Verification', () {
    test('NYT preset is completely removed from catalog', () {
      expect(OneUIBrandCatalog.findById('nytimes'), isNull);
      expect(OneUIBrandCatalog.findPreset('The New York Times'), isNull);
      expect(OneUIBrandCatalog.findPreset('NYT'), isNull);
      expect(
        OneUIBrandCatalog.presets.any((p) => p.id == 'nytimes' || p.name.contains('New York Times')),
        isFalse,
      );
    });

    test('All 12 requested brands resolve to bundled SVG assets', () {
      final requestedBrands = [
        ('Nintendo Switch Online', 'nintendo_switch_online'),
        ('Xbox Game Pass', 'xbox_game_pass'),
        ('Microsoft 365', 'microsoft_365'),
        ('Google Workspace', 'google_workspace'),
        ('Google One', 'google_one'),
        ('Canva Pro', 'canva'),
        ('Adobe Creative Cloud', 'adobe_cc'),
        ('Slack', 'slack'),
        ('Claude Pro', 'claude'),
        ('ChatGPT Plus', 'chatgpt'),
        ('Amazon Prime', 'amazon_prime'),
        ('Disney+', 'disney_plus'),
      ];

      for (final (name, presetId) in requestedBrands) {
        final svg = OneUIBrandIcon.resolveBrandSvg(name, presetId);
        expect(
          svg,
          isNotNull,
          reason: 'Expected $name ($presetId) to resolve to an SVG asset, but got null',
        );
      }
    });

    test('Alternative brand name lookups resolve properly to vector SVGs', () {
      expect(OneUIBrandIcon.resolveBrandSvg('Nintendo'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('Xbox'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('Microsoft'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('Slack'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('Claude'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('ChatGPT'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('OpenAI'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('Amazon'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('Disney'), isNotNull);
      expect(OneUIBrandIcon.resolveBrandSvg('D+'), isNotNull);
    });
  });

  group('IconPickerScreen Redesign Widget Tests', () {
    testWidgets('renders One UI header, hero card, swatches, and segmented capsules', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: IconPickerScreen(
            initialColor: Color(0xFF0066FF),
            initialIcon: Icons.movie_filter_rounded,
            initialPresetId: 'spotify',
            subscriptionName: 'Spotify Premium',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Subscription icon'), findsOneWidget);

      // Hero Live Preview Card
      expect(find.text('Spotify Premium'), findsOneWidget);
      expect(find.text('Spotify'), findsWidgets); // Status pill badge and grid text

      // Background Color Section
      expect(find.text('Background color'), findsOneWidget);

      // Segmented Capsule Bar (Replacing ugly tabs)
      expect(find.text('Icon style'), findsOneWidget);
      expect(find.text('Brand presets'), findsOneWidget);
      expect(find.text('System icons'), findsOneWidget);
      expect(find.text('Custom URL'), findsOneWidget);

      // Search Capsule
      expect(find.text('Search 40+ brands...'), findsOneWidget);

      // Save pill
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('switches between Brand Presets, System Icons, and Custom URL seamlessly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));

      IconPickerResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await IconPickerScreen.open(
                  context,
                  currentColor: const Color(0xFF0066FF),
                  currentIcon: Icons.tv_rounded,
                  currentPresetId: 'netflix',
                  subscriptionName: 'Netflix Standard',
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Initial state is brand presets
      expect(find.text('Search 40+ brands...'), findsOneWidget);

      // Switch to System Icons mode
      await tester.tap(find.text('System icons'));
      await tester.pumpAndSettle();

      // Brand search should now be hidden
      expect(find.text('Search 40+ brands...'), findsNothing);

      // Tap a system icon (e.g. music note)
      await tester.tap(find.byIcon(Icons.music_note_rounded));
      await tester.pumpAndSettle();

      // Switch to Custom URL mode
      await tester.tap(find.text('Custom URL'));
      await tester.pumpAndSettle();

      expect(find.text('Image link / URL'), findsOneWidget);
      expect(find.text('https://example.com/logo.png'), findsOneWidget);

      // Enter a URL
      await tester.enterText(find.byType(TextField).last, 'https://cdn.example.com/icon.png');
      await tester.pumpAndSettle();

      // Save and verify result
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.logoUrl, 'https://cdn.example.com/icon.png');
      expect(result!.brandPresetId, isNull);
    });

    testWidgets('search capsule filters brand presets live and handles empty results', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: IconPickerScreen(
            initialColor: Color(0xFF0066FF),
            initialIcon: Icons.movie_filter_rounded,
            subscriptionName: 'Gaming Sub',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for Nintendo
      await tester.enterText(find.byType(TextField), 'Nintendo');
      await tester.pumpAndSettle();

      expect(find.text('Nintendo Switch Online'), findsOneWidget);
      expect(find.text('Spotify'), findsNothing);

      // Search for nonexistent brand
      await tester.enterText(find.byType(TextField), 'NonExistentBrand12345');
      await tester.pumpAndSettle();

      expect(find.text('No matching brand preset found'), findsOneWidget);

      // Clear search via cancel icon
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      expect(find.text('No matching brand preset found'), findsNothing);
      expect(find.text('Spotify'), findsOneWidget);
    });
  });
}
