import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/screens/icon_picker_screen.dart';
import 'package:onespend/utils/one_ui_brand_catalog.dart';
import 'package:onespend/widgets/one_ui_brand_icon.dart';
import 'package:onespend/widgets/one_ui_icon_picker_modal.dart';

import '../helpers/test_app.dart';

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

  group('IconPickerScreen One UI Subpages Architecture Tests', () {
    testWidgets('renders One UI hero card and group items with navigation chevrons', (tester) async {
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

      // Hero Live Preview Card (flat, no extra pills)
      expect(find.text('Spotify Premium'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget); // Group item subtitle

      // Group Items
      expect(find.text('Icon style'), findsOneWidget);
      expect(find.text('Brand logos'), findsOneWidget);
      expect(find.text('System icon'), findsOneWidget);
      expect(find.text('Custom image URL'), findsOneWidget);

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Background color'), findsOneWidget);
      expect(find.text('#0066FF'), findsWidgets);

      // Bottom floating pill
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Brand logos opens dedicated subpage and selecting a brand updates hero', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: IconPickerScreen(
            initialColor: Color(0xFF0066FF),
            initialIcon: Icons.tv_rounded,
            subscriptionName: 'My Subscription',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Brand logos group item
      await tester.tap(find.text('Brand logos'));
      await tester.pumpAndSettle();

      // Verify Brand logos subpage
      expect(find.text('Brand logos'), findsWidgets); // Header & Section

      // Tap header search button to reveal floating search bar
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Search 40+ brand logos...'), findsOneWidget);

      // Search for Nintendo
      await tester.enterText(find.byType(TextField), 'Nintendo');
      await tester.pumpAndSettle();

      expect(find.text('Nintendo Switch Online'), findsOneWidget);

      // Tap on Nintendo Switch Online to select it
      await tester.tap(find.text('Nintendo Switch Online'));
      await tester.pumpAndSettle();

      // Back on main screen: verify hero and group item updated!
      expect(find.text('Nintendo Switch Online'), findsWidgets);
    });

    testWidgets('tapping System icon opens dedicated subpage and selecting an icon updates hero', (tester) async {
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

      // Tap on System icon group item
      await tester.tap(find.text('System icon'));
      await tester.pumpAndSettle();

      // Verify subpage
      expect(find.text('System icon'), findsWidgets);

      // Tap on gaming controller icon
      await tester.tap(find.byIcon(Icons.sports_esports_rounded));
      await tester.pumpAndSettle();

      // Returned to main screen: verify system icon updated!
      expect(find.text('Gaming Controller'), findsWidgets);
      expect(find.byIcon(Icons.sports_esports_rounded), findsWidgets);
    });

    testWidgets('tapping Background color opens dedicated subpage and selecting a color updates hero', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: IconPickerScreen(
            initialColor: Color(0xFF0066FF),
            initialIcon: Icons.movie_filter_rounded,
            subscriptionName: 'Color Test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#0066FF'), findsWidgets);

      // Tap on Background color group item
      await tester.tap(find.text('Background color'));
      await tester.pumpAndSettle();

      // Verify subpage
      expect(find.text('Background color'), findsWidgets);
      expect(find.text('#1DB954'), findsOneWidget);

      // Tap on #1DB954 swatch
      await tester.tap(find.text('#1DB954'));
      await tester.pumpAndSettle();

      // Back on main screen: verify subtitle updated
      expect(find.text('#1DB954'), findsWidgets);
    });

    testWidgets('tapping Custom image URL opens subpage and saves entered link', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));

      IconPickerResult? result;

      await tester.pumpWidget(
        routedTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await IconPickerScreen.open(
                  context,
                  currentColor: const Color(0xFF0066FF),
                  currentIcon: Icons.tv_rounded,
                  subscriptionName: 'Custom Web Link Sub',
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Tap Custom image URL item
      await tester.tap(find.text('Custom image URL'));
      await tester.pumpAndSettle();

      expect(find.text('Apply URL'), findsOneWidget);

      // Enter URL
      await tester.enterText(find.byType(TextField), 'https://example.com/logo.svg');
      await tester.pumpAndSettle();

      // Tap Apply URL button
      await tester.tap(find.text('Apply URL'));
      await tester.pumpAndSettle();

      // On main screen: verify URL subtitle
      expect(find.text('https://example.com/logo.svg'), findsWidgets);

      // Save on main screen
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.logoUrl, 'https://example.com/logo.svg');
    });
  });
}
