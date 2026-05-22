import 'package:adr_mobile/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('login hero keeps product image without duplicate title', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'ADR Mobile',
      packageName: 'com.example.adr_mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('ADR Monitor'), findsNothing);
    expect(find.byKey(const Key('login-hero-image')), findsOneWidget);
    expect(find.text('Masuk ke Akun'), findsOneWidget);
  });

  testWidgets('login form panel is full width and reaches the bottom', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'ADR Mobile',
      packageName: 'com.example.adr_mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final panelFinder = find.byKey(const Key('login-form-panel'));
    final panelSize = tester.getSize(panelFinder);
    final panelBottom = tester.getBottomLeft(panelFinder).dy;
    final panelLeft = tester.getTopLeft(panelFinder).dx;
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(panelSize.height, greaterThanOrEqualTo(370));
    expect(panelSize.height, lessThanOrEqualTo(455));
    expect(panelLeft, 0);
    expect(panelBottom, screenHeight);
  });

  testWidgets('login hero image is larger after removing title text', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'ADR Mobile',
      packageName: 'com.example.adr_mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final heroSize = tester.getSize(find.byKey(const Key('login-hero-image')));
    expect(heroSize.height, greaterThanOrEqualTo(190));
  });
}
