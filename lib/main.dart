import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_flow/theme/theme.dart';
import 'package:habit_flow/screens/home_screen.dart';
import 'package:habit_flow/screens/stats_screen.dart';
import 'package:habit_flow/screens/profile_screen.dart';
import 'package:habit_flow/screens/habit_details_screen.dart';
import 'package:habit_flow/screens/add_options_screen.dart';
import 'package:habit_flow/screens/new_habit_screen.dart';
import 'package:habit_flow/screens/new_task_screen.dart';
import 'package:habit_flow/screens/settings_screen.dart';
import 'package:habit_flow/screens/daily_flow_details_screen.dart';
import 'package:habit_flow/screens/consistency_details_screen.dart';
import 'package:habit_flow/screens/streak_calendar_screen.dart';
import 'package:habit_flow/screens/alarm_ring_screen.dart';
import 'package:habit_flow/providers/habit_provider.dart';
import 'package:habit_flow/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_flow/models/habit.dart';
import 'package:habit_flow/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_flow/screens/onboarding_screen.dart';

bool? _onboardingCompleted;

// Global router key to allow navigation from streams
final _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(IconTypeAdapter());
    Hive.registerAdapter(AlarmModeAdapter());
    await Hive.openBox<Task>('tasks');
    await Hive.openBox<Habit>('habits');

    debugPrint('Initializing Services...');
    await NotificationService().init();
    // AlarmService init removed (handled natively)

    await NotificationService().requestPermissions();
    // await NotificationService().scheduleInactivityReminders();

    runApp(const KresdoApp());
  } catch (e) {
    debugPrint('Init Error: $e');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
}

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: (_onboardingCompleted ?? false) ? '/home' : '/onboarding',
  routes: [
    GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen()),
    GoRoute(
        path: '/',
        redirect: (context, state) =>
            (_onboardingCompleted ?? false) ? '/home' : '/onboarding'),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
    GoRoute(
        path: '/profile', builder: (context, state) => const ProfileScreen()),

    // Alarm Ring Screen (Full Screen)
    GoRoute(
      path: '/alarm-ring',
      pageBuilder: (context, state) {
        // No extra arguments needed for now, logic is self-contained or static
        return NoTransitionPage(child: const AlarmRingScreen());
      },
    ),

    GoRoute(
        path: '/habit/:id',
        builder: (context, state) =>
            HabitDetailsScreen(habitId: state.pathParameters['id'])),
    GoRoute(
        path: '/add',
        pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AddOptionsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            opaque: false)),
    GoRoute(
        path: '/new-habit',
        pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: NewHabitScreen(habit: state.extra as Habit?),
            transitionsBuilder: (c, a, s, child) =>
                FadeTransition(opacity: a, child: child),
            opaque: false)),
    GoRoute(
        path: '/new-task',
        pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: NewTaskScreen(task: state.extra as Task?),
            transitionsBuilder: (c, a, s, child) =>
                FadeTransition(opacity: a, child: child),
            opaque: false)),
    GoRoute(
        path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(
        path: '/daily-flow-details',
        builder: (context, state) =>
            DailyFlowDetailsScreen(filter: state.extra as String?)),
    GoRoute(
        path: '/consistency-details',
        builder: (context, state) => const ConsistencyDetailsScreen()),
    GoRoute(
        path: '/streak-calendar',
        builder: (context, state) => const StreakCalendarScreen()),
  ],
);

class KresdoApp extends StatefulWidget {
  const KresdoApp({super.key});

  @override
  State<KresdoApp> createState() => _KresdoAppState();
}

class _KresdoAppState extends State<KresdoApp> {
  StreamSubscription<String?>? notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initNotificationListener();
    _checkNotificationLaunch();
  }

  void _initNotificationListener() {
    notificationSubscription =
        NotificationService.selectNotificationStream.stream.listen((payload) {
      if (payload == 'ALARM_SCREEN') {
        _navigateToAlarm();
      }
    });
  }

  Future<void> _checkNotificationLaunch() async {
    final details = await NotificationService()
        .flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      if (details.notificationResponse?.payload == 'ALARM_SCREEN') {
        _navigateToAlarm();
      }
    }
  }

  void _navigateToAlarm() {
    // Check if we are already on the alarm screen
    final GoRouter router = GoRouter.of(_rootNavigatorKey.currentContext!);
    final String loc =
        router.routerDelegate.currentConfiguration.uri.toString();

    if (!loc.contains('/alarm-ring')) {
      _router.push('/alarm-ring');
    }
  }

  @override
  void dispose() {
    notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp.router(
            title: 'Zyro',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
