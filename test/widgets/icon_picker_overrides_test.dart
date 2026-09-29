import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/screens/icon_picker_screen.dart';
import 'package:onespend/widgets/one_ui_brand_icon.dart';
import 'package:onespend/widgets/one_ui_icon_picker_modal.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OneUIBrandIcon override and multi-color tests', () {
    testWidgets('system icon overrides brand name matching when preset is none', (tester) async {
      // Subscription named "Spotify", but user picked a system icon
      final sub = Subscription(
        id: 'test_sub',
        name: 'Spotify',
        description: 'Music',
        price: 9.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        iconData: Icons.sports_esports_rounded,
        brandPresetId: '__none__',
        nextBillingDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUIBrandIcon(
              subscription: sub,
              size: 60,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render the gaming controller icon, NOT the Spotify SVG
      expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('custom image URL overrides brand name matching', (tester) async {
      // Subscription named "Netflix", but user provided a custom web image URL
      final sub = Subscription(
        id: 'test_sub_2',
        name: 'Netflix',
        description: 'Movies',
        price: 15.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        logoUrl: 'https://images.example.com/custom_logo.png',
        brandPresetId: '__none__',
        nextBillingDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUIBrandIcon(
              subscription: sub,
              size: 60,
            ),
          ),
        ),
      );
      await tester.pump();

      // Should render Image.network, NOT the Netflix SVG
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    test('multi-color SVGs are properly identified and preserve color palette', () {
      expect(OneUIBrandIcon.isMultiColorSvg('google_one', 'Google One'), isTrue);
      expect(OneUIBrandIcon.isMultiColorSvg('google_workspace', 'Google Workspace'), isTrue);
      expect(OneUIBrandIcon.isMultiColorSvg('google', 'Google'), isTrue);
      expect(OneUIBrandIcon.isMultiColorSvg('spotify', 'Spotify'), isFalse);
    });

    test('brand SVG assets resolution', () {
      expect(OneUIBrandIcon.resolveBrandSvg('Google One', 'google_one'), 'assets/logos/brands/googleone.svg');
      expect(OneUIBrandIcon.resolveBrandSvg('Google Workspace', 'google_workspace'), 'assets/logos/brands/google.svg');
      expect(OneUIBrandIcon.resolveBrandSvg('Amazon Prime', 'amazon_prime'), 'assets/logos/brands/amazonprime.svg');
      expect(OneUIBrandIcon.resolveBrandSvg('LinkedIn Premium', 'linkedin_premium'), 'assets/logos/brands/linkedin.svg');
      expect(OneUIBrandIcon.resolveBrandSvg('Spotify', '__none__'), isNull);
    });

    testWidgets('IconPickerScreen remove custom image URL button clears URL completely', (tester) async {
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
                  currentLogoUrl: 'https://example.com/stuck_logo.png',
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

      // Open Custom image URL subpage
      await tester.tap(find.text('Custom image URL'));
      await tester.pumpAndSettle();

      // Verify Remove custom image URL button exists
      expect(find.text('Remove custom image URL'), findsOneWidget);

      // Tap Remove custom image URL
      await tester.tap(find.text('Remove custom image URL'));
      await tester.pumpAndSettle();

      // On main screen: custom URL subtitle should now be None
      expect(find.text('https://example.com/stuck_logo.png'), findsNothing);

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.logoUrl, isNull);
    });

    testWidgets('Selecting system icon on existing Netflix subscription saves __none__ preset', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));

      IconPickerResult? result;

      await tester.pumpWidget(
        routedTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await IconPickerScreen.open(
                  context,
                  currentColor: const Color(0xFFE50914),
                  currentIcon: Icons.movie_filter_rounded,
                  currentPresetId: 'netflix',
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

      // Tap System icon group item
      await tester.tap(find.text('System icon'));
      await tester.pumpAndSettle();

      // Tap on music note icon
      await tester.tap(find.byIcon(Icons.music_note_rounded));
      await tester.pumpAndSettle();

      // Main screen: save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.brandPresetId, '__none__');
      expect(result!.iconData, Icons.music_note_rounded);
      expect(result!.logoUrl, isNull);

      // Verify that OneUIBrandIcon with this result does NOT render Netflix brand SVG
      final updatedSub = Subscription(
        id: 'netflix_sub',
        name: 'Netflix',
        description: 'Streaming',
        price: 15.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        iconData: result!.iconData,
        brandPresetId: result!.brandPresetId,
        nextBillingDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUIBrandIcon(
              subscription: updatedSub,
              size: 60,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });
  });
}
