

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'timer_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

Future<void> startTimerLogic(BuildContext context) async {
  final dataProvider = Provider.of<DataProvider>(context, listen: false);
  final timerService = Provider.of<TimerService>(context, listen: false);
  final FlutterTts flutterTts = FlutterTts();

  int? _lastNotifiedMinutes; // State variable to track the last notified time
  Timer? _voiceNotificationTimer;

  // Method to show voice notifications using TTS
  Future<void> _showNotification(String message) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(message);
  }

  // Handles voice notifications at specific times
  void _handleVoiceNotifications(Duration remainingTime) {
    final int minutes = remainingTime.inMinutes;

    if (_lastNotifiedMinutes != minutes) {
      if ([59, 30, 15, 10, 5, 3, 2, 1].contains(minutes)) {
        _showNotification('You have $minutes minutes left to drive');
        _lastNotifiedMinutes = minutes;
      } else if (minutes == 0 && remainingTime.inSeconds == 0) {
        _showNotification('You need to rest');
        _lastNotifiedMinutes = minutes;
      }
    }
  }

  void _startTimer(Duration initialDuration) {
    if (!timerService.isRunning &&
        dataProvider.currentStatusDescription == 'Driving') {
      timerService.resetTimer(initialDuration);
      timerService.startTimer();
    }

    // Cancel any existing voice notification timer before starting a new one
    _voiceNotificationTimer?.cancel();

    // Timer to update the remaining time and handle voice notifications every second
    _voiceNotificationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (dataProvider.currentStatusDescription != 'Driving') {
        timer.cancel();
        timerService.stopTimer();
        _voiceNotificationTimer
            ?.cancel(); // Cancel the voice notification timer when driving stops
      } else {
        final newRemainingTime =
            dataProvider.remainingTime - const Duration(seconds: 1);

        if (newRemainingTime <= Duration.zero) {
          // Stop the timer when it reaches 00:00:00
          timer.cancel();
          timerService.stopTimer();
          _voiceNotificationTimer
              ?.cancel(); // Cancel the voice notification timer
          dataProvider.updateRemainingTime(Duration.zero);
          _showNotification(
              'You need to rest'); // Final notification when time runs out
        } else {
          dataProvider.updateRemainingTime(newRemainingTime);
          _handleVoiceNotifications(newRemainingTime);
        }
      }
    });
  }

  // Centralized method to fetch HOS data and apply logic
  Future<void> _initializeHosDataAndStartLogic() async {
    try {
      final mixId = dataProvider.profileData?['mixDriverId'] ?? '';
      final token = dataProvider.token ?? '';

      await dataProvider.fetchHosData(mixId, token);
      final hosData = dataProvider.hosData;

      if (hosData != null &&
          dataProvider.currentStatusDescription == 'Driving') {
        final initialDuration = dataProvider.remainingTime;
        _startTimer(initialDuration);
      }

      // Schedule the next HOS data fetch and logic update in 8 minutes
      Timer(const Duration(minutes: 8), _initializeHosDataAndStartLogic);
    } catch (e) {
      // Handle error
    }
  }

  // Initial call to fetch HOS data and start the timer logic
  await _initializeHosDataAndStartLogic();
}
