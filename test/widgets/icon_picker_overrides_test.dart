import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/widgets/one_ui_brand_icon.dart';

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
  });
}
