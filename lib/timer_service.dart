

import 'dart:async';
import 'package:flutter/material.dart';

class TimerService with ChangeNotifier {
  Timer? _timer;
  Duration _duration = const Duration(hours: 4);
  bool _isRunning = false; // Initialize as false to reflect actual state

  Duration get duration => _duration;
  bool get isRunning => _isRunning;

  void startTimer() {
    if (_isRunning) return; // Prevent multiple timers from starting
    _isRunning = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration.inSeconds == 0) {
        _timer?.cancel();
        _isRunning = false;
        notifyListeners();
      } else {
        _duration -= const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void resetTimer(Duration newDuration) {
    _timer?.cancel();
    _duration = newDuration;
    _isRunning = false;
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void updateRemainingTime(Duration newDuration) {
    _duration = newDuration;
    notifyListeners();
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Duration convertToDuration(String formattedDuration) {
    final parts = formattedDuration.split(':');
    if (parts.length != 3) return const Duration();

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }
}
