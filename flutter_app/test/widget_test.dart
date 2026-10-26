import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rise/main.dart';
import 'package:rise/providers/auth_provider.dart';
import 'package:rise/providers/app_provider.dart';
import 'package:rise/features/onboarding/welcome_screen.dart';
import 'package:rise/features/auth/auth_screen.dart';
import 'package:rise/shared/widgets/task_tile.dart';
import 'package:rise/shared/widgets/mountain_hero_card.dart';
import 'package:rise/models/task_model.dart';
import 'package:rise/models/journey_model.dart';
import 'package:rise/core/network/api_client.dart';

void main() {
  testWidgets('RISE App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const RiseApp(),
      ),
    );

    // Initial splash or welcome renders RISE title
    expect(find.text('RISE'), findsOneWidget);
  });

  testWidgets('WelcomeScreen displays brand and call to action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.text('RISE'), findsOneWidget);
    expect(find.text('Start Your Journey'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('TaskTile renders title, duration, and responds to tap', (WidgetTester tester) async {
    bool toggled = false;
    final sampleTask = TaskModel(
      id: 'task_1',
      title: 'Review Thevenin Circuit Theorem',
      category: 'GATE 2027',
      section: 'Morning Focus',
      priority: 'high',
      estimatedMinutes: 35,
      xpReward: 15,
      isCompleted: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: sampleTask,
            onToggle: () {
              toggled = true;
            },
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Review Thevenin Circuit Theorem'), findsOneWidget);
    expect(find.text('35m'), findsOneWidget);
    expect(find.text('+15 XP'), findsOneWidget);

    // Tap complete checkbox
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    expect(toggled, isTrue);
  });

  testWidgets('MountainHeroCard renders stage name and progress', (WidgetTester tester) async {
    final journey = JourneySummaryModel(
      level: 3,
      stageName: 'Finding Rhythm',
      totalXp: 350,
      mountainProgressPercent: 17.5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MountainHeroCard(
            journey: journey,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Finding Rhythm'), findsOneWidget);
    expect(find.text('Summit is 18% conquered'), findsOneWidget);
    expect(find.text('LVL 3'), findsOneWidget);
    expect(find.text('350 XP'), findsOneWidget);
  });

  testWidgets('AuthScreen shows only Username, Password, and Confirm Password on Register', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const MaterialApp(
          home: AuthScreen(initialIsRegister: true),
        ),
      ),
    );

    // Verify registration fields
    expect(find.byKey(const Key('field_username')), findsOneWidget);
    expect(find.byKey(const Key('field_password')), findsOneWidget);
    expect(find.byKey(const Key('field_confirm_password')), findsOneWidget);

    // Verify button
    expect(find.byKey(const Key('btn_create_account')), findsOneWidget);
    expect(find.text('Create My Account'), findsWidgets);

    // Ensure email is completely gone
    expect(find.text('Email Address'), findsNothing);
    expect(find.text('Display Name'), findsNothing);
  });

  testWidgets('AuthScreen shows only Username and Password on Login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const MaterialApp(
          home: AuthScreen(initialIsRegister: false),
        ),
      ),
    );

    // Verify login fields
    expect(find.byKey(const Key('field_username')), findsOneWidget);
    expect(find.byKey(const Key('field_password')), findsOneWidget);
    expect(find.byKey(const Key('field_confirm_password')), findsNothing);

    // Verify button
    expect(find.byKey(const Key('btn_sign_in')), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);

    // Ensure email is completely gone
    expect(find.text('Email Address'), findsNothing);
  });

  test('ApiClient buildUri ensures /api is appended exactly once and handles custom base URLs', () {
    // 1. Default base URL
    final uri1 = ApiClient.buildUri('/auth/login');
    expect(uri1.path, '/api/auth/login');

    // 2. Endpoint already has /api prefix
    final uri2 = ApiClient.buildUri('/api/auth/login');
    expect(uri2.path, '/api/auth/login');
    expect(uri2.path.contains('/api/api'), isFalse);

    // 3. Endpoint without leading slash
    final uri3 = ApiClient.buildUri('auth/register');
    expect(uri3.path, '/api/auth/register');

    // 4. Custom LAN IP without /api
    ApiClient.setCustomBaseUrl('http://192.168.1.100:8000');
    final uri4 = ApiClient.buildUri('/auth/login');
    expect(uri4.toString(), 'http://192.168.1.100:8000/api/auth/login');

    // 5. Custom LAN IP with /api and trailing slash
    ApiClient.setCustomBaseUrl('http://192.168.1.100:8000/api/');
    final uri5 = ApiClient.buildUri('/auth/login');
    expect(uri5.toString(), 'http://192.168.1.100:8000/api/auth/login');

    // Reset custom base URL
    ApiClient.setCustomBaseUrl(null);
  });
}

