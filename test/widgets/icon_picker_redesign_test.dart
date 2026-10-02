import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/screens/icon_picker_screen.dart';
import 'package:onespend/utils/one_ui_brand_catalog.dart';
import 'package:onespend/widgets/one_ui_icon_picker_modal.dart';
import 'package:onespend/widgets/one_ui_logo_framer.dart';

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

    test('every preset has plain letters for its initials tile', () {
      for (final preset in OneUIBrandCatalog.presets) {
        expect(preset.monogram, isNotEmpty, reason: preset.id);
        expect(preset.monogram.length, lessThanOrEqualTo(3), reason: preset.id);
      }
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
      expect(find.text('Sp'), findsWidgets); // Initials tile + its row subtitle

      // Group Items
      expect(find.text('Icon style'), findsOneWidget);
      expect(find.text('Initials'), findsOneWidget);
      expect(find.text('Brand logos'), findsNothing); // no third-party logos to pick
      expect(find.text('System icon'), findsOneWidget);
      expect(find.text('Custom image URL'), findsOneWidget);

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Background color'), findsOneWidget);
      expect(find.text('#0066FF'), findsWidgets);

      // Bottom floating pill
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Initials switches a system icon or image back to letters', (tester) async {
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
                  currentIcon: Icons.sports_esports_rounded,
                  currentPresetId: '__none__',
                  currentLogoUrl: 'https://example.com/a.png',
                  subscriptionName: 'Netflix',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Initials'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result!.logoUrl, isNull);
      expect(result!.brandPresetId, 'netflix'); // the preset's letters ("NF")
      expect(result!.iconData.codePoint, Icons.subscriptions_rounded.codePoint);
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

    testWidgets('framing set in the image editor comes back with the result', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1200));
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
                  currentLogoUrl: 'https://example.com/logo.png',
                  subscriptionName: 'Framed',
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
      await tester.tap(find.text('Custom image URL'));
      await tester.pumpAndSettle();

      // Zoom in with the slider.
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(120, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result!.logoUrl, 'https://example.com/logo.png');
      expect(result!.logoTransform, isNotNull);
      expect(result!.logoTransform!.scale, greaterThan(1.0));
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

      expect(find.text('Image link'), findsOneWidget);
      expect(find.byType(OneUILogoFramer), findsNothing); // no image yet

      // Enter URL: the image editor appears
      await tester.enterText(find.byType(TextField), 'https://example.com/logo.svg');
      await tester.pump();
      expect(find.byType(OneUILogoFramer), findsNothing); // preview waits for typing to pause
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byType(OneUILogoFramer), findsOneWidget);

      // Save the subpage (Cancel | Save pill)
      await tester.tap(find.text('Save').last);
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
