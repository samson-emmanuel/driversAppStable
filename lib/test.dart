import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DataProvider with ChangeNotifier {
  Map<String, dynamic>? _hosData;
  bool _isTimerRunning = false;
  String? _token;
  Duration _remainingTime = Duration.zero;

  Map<String, dynamic>? get hosData => _hosData;
  bool get isTimerRunning => _isTimerRunning;
  String? get token => _token;
  Duration get remainingTime => _remainingTime;
  String get currentStatusDescription => _hosData?['currentStatusDescription'] ?? 'Not Driving';
  String? get availableDrivingBeforeBreak => _hosData?['availableDrivingBeforeBreak'];

  void setHosData(Map<String, dynamic> data) {
    _hosData = data;
    if (currentStatusDescription == 'Driving' && !_isTimerRunning) {
      final remainingTime = parseDuration(_hosData?['availableDrivingBeforeBreak'] ?? 'PT4H');
      updateRemainingTime(remainingTime);
      startTimer();
    }
    notifyListeners();
  }

  Duration parseDuration(String duration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);

    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
    return Duration.zero;
  }

  void updateRemainingTime(Duration time) {
    _remainingTime = time;
    notifyListeners();
  }

  void startTimer() {
    _isTimerRunning = true;
    notifyListeners();
  }

  void stopTimer() {
    _isTimerRunning = false;
    notifyListeners();
  }

  Future<void> fetchHosData(String mixId, String token) async {
    await _ensureTokenAndMixIdLoaded();

    try {
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/driver/$mixId/hos',
        ),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        _hosData = jsonDecode(response.body)['result'];
        notifyListeners();
        if (currentStatusDescription == 'Driving' && !_isTimerRunning) {
          final remainingTime = parseDuration(
            _hosData?['availableDrivingBeforeBreak'] ?? 'PT4H',
          );
          updateRemainingTime(remainingTime);
          startTimer();
        }
        notifyListeners();
      } else {
        throw Exception('OperationError: Failed to fetch HOS data');
      }
    } catch (e) {
      throw Exception('OperationError: Failed to fetch HOS data');
    }
  }

  Future<void> _ensureTokenAndMixIdLoaded() async {
    // Placeholder for token and mixId loading logic
    _token = _token ?? 'your-token-here';
  }
}