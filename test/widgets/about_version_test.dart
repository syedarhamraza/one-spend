import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/config/feature_flags.dart';
import 'package:onespend/screens/settings/about_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('About shows the version and channel in one plain line', (tester) async {
    // AppVersion.current() caches the first answer, so this file sets it once.
    PackageInfo.setMockInitialValues(
      appName: 'One Spend',
      packageName: 'com.syedarhamraza.onespend',
      version: '1.0.0-beta.2',
      buildNumber: '7',
      buildSignature: '',
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(routedTestApp(const AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.0.0 Beta 2'), findsOneWidget);
    expect(find.text('Beta 2'), findsNothing); // no separate chip
    expect(find.textContaining('Build'), findsNothing); // that's in Software information
  });

  testWidgets('About links the privacy policy in release builds', (tester) async {
    FeatureFlags.showPlannedFeatures = false;
    addTearDown(() => FeatureFlags.showPlannedFeatures = true);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(routedTestApp(const AboutScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Privacy policy'), 200);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Opens in your browser'), findsNothing); // it opens in the app now
  });

  testWidgets('About fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(720, 1280); // 360 x 640 dp
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      routedTestApp(
        const MediaQuery(
          data: MediaQueryData(size: Size(360, 640), textScaler: TextScaler.linear(1.6)),
          child: AboutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // no overflow: it scrolls instead
    await tester.scrollUntilVisible(find.text('Privacy policy'), 200);
    expect(find.text('Privacy policy'), findsOneWidget);
  });
}
