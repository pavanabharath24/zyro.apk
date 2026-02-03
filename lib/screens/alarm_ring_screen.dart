import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../services/native_alarm_service.dart';

class AlarmRingScreen extends StatefulWidget {
  // We might receive data via the router extra logic or just show generic "Alarm"
  // Since we rely on notification payload, we might just fetch current active alarm?
  // For simplicity, we just show a generic active screen.
  final Map<String, dynamic>? extra;

  const AlarmRingScreen({super.key, this.extra});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  String? _title;
  String? _body;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Initialize with initial data
    _title = widget.extra?['title'] as String?;
    _body = widget.extra?['body'] as String?;

    // Listen for updates (merges)
    _subscription = NativeAlarmService().alarmUpdateStream.listen((data) {
      if (mounted) {
        setState(() {
          _title = data['title'] as String?;
          _body = data['body'] as String?;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    // Stop the ringtone/vibration via native service
    await NativeAlarmService().stopAlarm();

    if (mounted) {
      // Create a new task/habit completion logic if needed?
      // Or just close user flows.
      // Usually we just go back home.
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulsing Animation or Icon
              const Icon(Icons.alarm, color: Colors.white, size: 80),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _title ?? 'Alarm',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_body != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    _body!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ),
              const SizedBox(height: 64),

              // Stop Button
              GestureDetector(
                onTap: _stopAlarm,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.red, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'STOP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
