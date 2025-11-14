import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class UsageTimeService with WidgetsBindingObserver {
  static const maxDailyUsage = Duration(hours: 4);
  static const warningBefore = Duration(minutes: 15);

  Timer? _timer;
  Duration _todayUsage = Duration.zero;
  DateTime? _lastTick;

  Function()? onWarning15min;
  Function()? onLimitReached;

  UsageTimeService() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final lastSavedDay = prefs.getString("day") ?? "";
    final today = DateTime.now().toIso8601String().split("T")[0];

    if (lastSavedDay != today) {
      // Nouveau jour : reset
      prefs.setString("day", today);
      prefs.setInt("usage", 0);
      _todayUsage = Duration.zero;
    } else {
      _todayUsage = Duration(seconds: prefs.getInt("usage") ?? 0);
    }

    _startTimer();
  }

  void _startTimer() {
    _lastTick = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _tick());
  }

  void _tick() async {
    final now = DateTime.now();
    final diff = now.difference(_lastTick!);
    _lastTick = now;

    _todayUsage += diff;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("usage", _todayUsage.inSeconds);

    // 🔔 Avertissement 15 min avant
    if (_todayUsage >= maxDailyUsage - warningBefore &&
        _todayUsage < maxDailyUsage &&
        onWarning15min != null) {
      onWarning15min!();
      onWarning15min = null; // éviter répétition
    }

    // ❌ Temps max atteint
    if (_todayUsage >= maxDailyUsage) {
      onLimitReached?.call();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }
}
