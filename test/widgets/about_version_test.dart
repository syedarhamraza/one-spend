import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/screens/settings/about_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('About shows the version, its pre-release channel and the build', (tester) async {
    // AppVersion.current() caches the first answer, so this file sets it once.
    PackageInfo.setMockInitialValues(
      appName: 'OneSpend',
      packageName: 'com.onespend.onespend',
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

    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Beta 2'), findsOneWidget);
    expect(find.textContaining('Build 7'), findsOneWidget);
  });
}
