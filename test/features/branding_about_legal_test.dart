import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/about/presentation/screens/about_screen.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:legal_unity_network/features/help/presentation/screens/help_support_screen.dart';
import 'package:legal_unity_network/features/legal/presentation/screens/legal_screen.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/user_settings_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:legal_unity_network/shared/widgets/app_brand.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';

void main() {
  final testUser = AuthUser(
    uid: 'adv-001',
    email: 'advocate.sharma@legalunity.org',
    firstName: 'Devendra',
    lastName: 'Sharma',
    stateBarAssociation: 'Bar Council of Delhi',
    enrollmentNumber: 'D/456/2015',
    status: UserStatus.approved,
    role: UserRole.member,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('Branding & Brand Widgets', () {
    testWidgets('AppLogo renders legal scales motif and styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogo(size: 80),
            ),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byIcon(Icons.balance_rounded), findsOneWidget);
    });

    testWidgets('AppLogo.asset constructor renders logo widget with fallback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogo.asset(size: 64),
            ),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('AppBrandHeader renders logo, app name, motto, and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppBrandHeader(),
          ),
        ),
      );

      expect(find.text(AppConfig.appName), findsOneWidget);
      expect(find.text(AppConfig.appMotto), findsOneWidget);
      expect(find.text(AppConfig.appSubtitle), findsOneWidget);
    });

    testWidgets('InviteAdvocatesDialog renders invite message and copy button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: InviteAdvocatesDialog(),
          ),
        ),
      );

      expect(find.text('Invite Colleagues'), findsOneWidget);
      expect(find.text('Copy Invitation'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });
  });

  group('About Screen', () {
    testWidgets('AboutScreen renders Dr. Ambedkar vision, pillars, contact, and licenses',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AboutScreen(),
        ),
      );

      expect(find.text('About Union'), findsOneWidget);
      expect(find.text(AppConfig.appName), findsOneWidget);
      expect(find.text(AppConfig.appMotto), findsOneWidget);
      expect(find.text('Foundational Vision'), findsOneWidget);
      expect(find.text('Core Pillars & Mission'), findsOneWidget);
      expect(find.text('Verified Advocate Fraternity'), findsOneWidget);
      expect(find.text('Democratic Self-Governance'), findsOneWidget);
      expect(find.text('Secretariat & Contact Info'), findsOneWidget);
      expect(find.text(AppConfig.supportEmail), findsOneWidget);
      expect(find.text('Open Source Licenses & Attributions'), findsOneWidget);
    });
  });

  group('Legal & Compliance Hub', () {
    testWidgets('LegalScreen displays 4 tabs and allows switching between policies',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LegalScreen(),
        ),
      );

      expect(find.text('Legal & Compliance'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('BCI Disclaimer'), findsOneWidget);
      expect(find.text('Code of Conduct'), findsOneWidget);

      // Verify Terms of Service content
      expect(find.text('Eligibility & Bar Enrollment Verification'), findsOneWidget);

      // Switch to Privacy Policy tab
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('Advocate Data Privacy Policy'), findsOneWidget);
      expect(find.text('Member Directory Privacy Controls'), findsOneWidget);

      // Switch to BCI Disclaimer tab
      await tester.tap(find.text('BCI Disclaimer'));
      await tester.pumpAndSettle();
      expect(find.text('Bar Council Regulatory Disclaimer'), findsOneWidget);
      expect(find.text('Statutory Bar Council Compliance'), findsOneWidget);

      // Switch to Code of Conduct tab
      await tester.tap(find.text('Code of Conduct'));
      await tester.pumpAndSettle();
      expect(find.text('Advocate Code of Conduct & Ethics'), findsOneWidget);
      expect(find.text('Constitutional Morality & Equality'), findsOneWidget);
    });
  });

  group('Help, Support & FAQ Screen', () {
    testWidgets('HelpSupportScreen renders FAQs, category filters, and search query',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HelpSupportScreen(),
        ),
      );

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Union Helpdesk & Grievance Cell'), findsOneWidget);
      expect(find.text('Submit Ticket'), findsOneWidget);

      // Verify initial FAQs present
      expect(find.text('How do I get my Join Request approved?'), findsOneWidget);

      // Test Search filtering
      await tester.enterText(find.byType(TextField), 'elections');
      await tester.pumpAndSettle();

      expect(find.text('How do Union Elections work?'), findsOneWidget);
      expect(find.text('How do I get my Join Request approved?'), findsNothing);

      // Tap Submit Ticket to open Grievance Dialog
      await tester.tap(find.text('Submit Ticket'));
      await tester.pumpAndSettle();

      expect(find.text('Submit Support Query'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });

  group('User Settings & Top Bar Menu Integration', () {
    testWidgets('UserSettingsScreen links to About, Invite, Help, and Legal screens',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: UserSettingsScreen(currentUser: testUser),
          ),
        ),
      );

      expect(find.text('User Settings'), findsOneWidget);
      expect(find.text('Union & Fraternity'), findsOneWidget);
      expect(find.text('About Union'), findsOneWidget);
      expect(find.text('Invite Colleague Advocates'), findsOneWidget);
      expect(find.text('Help, FAQ & Support Desk'), findsOneWidget);
      expect(find.text('Terms of Service & By-Laws'), findsOneWidget);
      expect(find.text('Advocate Data Privacy Policy'), findsOneWidget);
      expect(find.text('Bar Council Disclaimer'), findsOneWidget);

      // Tap About Union and verify navigation
      await tester.tap(find.text('About Union'));
      await tester.pumpAndSettle();
      expect(find.text('Foundational Vision'), findsOneWidget);
    });

    testWidgets('AppTopBarActions menu includes About, Legal, Help, and Invite actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  AppTopBarActions(),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap profile menu
      await tester.tap(find.byKey(const Key('top_right_profile_avatar_menu')));
      await tester.pumpAndSettle();

      expect(find.text('About Union'), findsOneWidget);
      expect(find.text('Legal & Compliance'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Invite Colleagues'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  group('PhoneLoginScreen Branding & Footer Links', () {
    testWidgets('PhoneLoginScreen displays AppLogo, motto, and legal footer links',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhoneLoginScreen(),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text(AppConfig.welcomeTitle), findsOneWidget);
      expect(find.text(AppConfig.appMotto), findsOneWidget);
      expect(find.text('About Union'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Help & FAQ'), findsOneWidget);

      // Tap Terms of Service from login footer
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();
      expect(find.text('Legal & Compliance'), findsOneWidget);
      expect(find.text('Eligibility & Bar Enrollment Verification'), findsOneWidget);
    });
  });
}
