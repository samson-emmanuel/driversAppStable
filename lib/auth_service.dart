
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  final String _userIdKey = 'userId';  
  final String _boxName = 'authBox';
  final String _tokenKey = 'authToken';
  final String _loginTimeKey = 'loginTime';
  final String _firstRunKey = 'firstRun'; // Key to track first run
  final int _sessionDurationHours = 23;
  final int _maxRetries =
      3; // Maximum number of retries before clearing storage

  Box? _box;

  // Ensure the Hive box is opened only once and reused across different methods
  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  // Save token and login time
  Future<void> saveToken(String token, userId) async {
    try {
      var box = await _getBox();
      await box.put(_tokenKey, token);
      await box.put(_loginTimeKey, DateTime.now().toIso8601String());
        await box.put(_userIdKey, userId);

      // print('Token and login time saved successfully.');
    } catch (e) {
      // print('Error saving token: $e');
    }
  }

  // Retrieve token
  Future<String?> getToken() async {
    try {
      var box = await _getBox();
      return box.get(_tokenKey);
    } catch (e) {
      // print('Error retrieving token: $e');
      return null;
    }
  }

  // Check if the session is still valid
  Future<bool> isSessionValid() async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        var box = await _getBox();
        String? token = box.get(_tokenKey);
        String? loginTimeStr = box.get(_loginTimeKey);

        if (token == null || loginTimeStr == null) {
          // print('Session invalid: Missing token or login time.');
          retryCount++;
          continue;
        }

        DateTime loginTime = DateTime.parse(loginTimeStr);
        if (DateTime.now().difference(loginTime).inHours <
            _sessionDurationHours) {
          // print('Session is valid.');
          return true;
        } else {
          // print('Session expired.');
          await removeToken();
          return false;
        }
      } catch (e) {
        // print('Error checking session validity: $e');
        retryCount++;
      }
    }

    // If retries exhausted and it's not the first run, clear storage and return false
    var box = await _getBox();
    bool isFirstRun = box.get(_firstRunKey) == null;
    if (!isFirstRun) {
      // print('Max retries reached. Clearing storage.');
      await clearStorage();
    } else {
      // Mark that the app has been run at least once
      await box.put(_firstRunKey, 'false');
    }
    return false;
  }


  // Remove token (logout)
  Future<void> removeToken() async {
    try {
      var box = await _getBox();
      await box.delete(_tokenKey);
      await box.delete(_loginTimeKey);
      // print('Token and login time removed.');
    } catch (e) {
      // print('Error removing token: $e');
    }
  }

  // Clear entire storage
  Future<void> clearStorage() async {
    try {
      var box = await _getBox();
      await box.clear();
      // print('Hive storage cleared.');
    } catch (e) {
      // print('Error clearing Hive storage: $e');
    }
  }

  // Function to handle app startup logic
  Future<void> handleAppStart(BuildContext context) async {
    var box = await _getBox();
    bool isFirstRun = box.get(_firstRunKey) == null;

    if (isFirstRun) {
      // Mark that the app has been run at least once
      await box.put(_firstRunKey, 'false');
      return; // Bypass session validation on the first run
    }

    bool sessionValid = await isSessionValid();
    if (!sessionValid) {
      // Redirect to the welcome screen if the session is not valid
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }
}
