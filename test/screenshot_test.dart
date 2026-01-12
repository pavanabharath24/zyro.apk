import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:habit_flow/models/habit.dart';
import 'package:habit_flow/providers/habit_provider.dart';
import 'package:habit_flow/providers/settings_provider.dart';
import 'package:habit_flow/screens/home_screen.dart';
import 'package:habit_flow/screens/stats_screen.dart';
import 'package:habit_flow/theme/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'dart:io';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('App Screenshots', () {
    late HabitProvider habitProvider;
    late SettingsProvider settingsProvider;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('habit_flow_test');
      Hive.init(tempDir.path);

      // Register adapters if not already
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TaskAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(IconTypeAdapter());

      // Open boxes
      await Hive.openBox<Habit>('habits');
      await Hive.openBox<Task>('tasks');
      await Hive.openBox(
          'settings'); // SettingsProvider might use this or SharedPrefs?

      // Clear existing data
      await Hive.box<Habit>('habits').clear();
      await Hive.box<Task>('tasks').clear();

      // Seed Data
      habitProvider = HabitProvider();
      settingsProvider = SettingsProvider();
      // Add Sample Habits
      final today = DateTime.now();

      // Completed Habit
      habitProvider.addHabit(Habit(
        id: '1',
        name: 'Drink Water',
        icon: IconType.water,
        completedDates: [today], // Completed today
        createdAt: today.subtract(const Duration(days: 7)),
      ));

      // Pending Habit
      habitProvider.addHabit(Habit(
        id: '2',
        name: 'Read 30 mins',
        icon: IconType.book,
        completedDates: [],
        createdAt: today.subtract(const Duration(days: 7)),
      ));

      // Another Completed Habit
      habitProvider.addHabit(Habit(
        id: '3',
        name: 'Meditation',
        icon: IconType.meditation,
        completedDates: [today],
        createdAt: today.subtract(const Duration(days: 7)),
      ));
    });

    // Define device
    const deviceEnum = GoldenScreenshotDevices.iphone;

    testGoldens('Home Screen - Light', (tester) async {
      ScreenshotDevice.screenshotsFolder = 'test/goldens/';

      await tester.pumpWidget(
        ScreenshotApp(
          device: deviceEnum.device,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: habitProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        ),
      );

      await tester.waitForAssets(); // Ensure fonts/icons load
      await tester.pumpAndSettle();

      await tester.expectScreenshot(deviceEnum.device, '1_home_light');
    });

    testGoldens('Stats Screen - Light', (tester) async {
      ScreenshotDevice.screenshotsFolder = 'test/goldens/';

      await tester.pumpWidget(
        ScreenshotApp(
          device: deviceEnum.device,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: habitProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const StatsScreen(),
            ),
          ),
        ),
      );

      await tester.waitForAssets();
      await tester.pumpAndSettle();

      await tester.expectScreenshot(deviceEnum.device, '2_stats_light');
    });

    testGoldens('Home Screen - Dark', (tester) async {
      ScreenshotDevice.screenshotsFolder = 'test/goldens/';

      await tester.pumpWidget(
        ScreenshotApp(
          device: deviceEnum.device,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: habitProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme, // Force dark theme
              home: const HomeScreen(),
            ),
          ),
        ),
      );

      await tester.waitForAssets();
      await tester.pumpAndSettle();

      await tester.expectScreenshot(deviceEnum.device, '3_home_dark');
    });
  });
}

// Extension to help wait for images/fonts
extension TesterExtensions on WidgetTester {
  Future<void> waitForAssets() async {
    await runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await pumpAndSettle();
  }
}
