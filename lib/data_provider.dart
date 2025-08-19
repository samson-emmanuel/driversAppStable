// ignore_for_file: prefer_final_fields, unused_local_variable

import 'dart:convert';
// import 'package:driversapp/current_trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'timer_service.dart';
import 'auth_service.dart';

class DataProvider with ChangeNotifier {
  bool _isTimerRunning = false;
  final TimerService _timerService = TimerService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _profileData;
  List<dynamic>? _eventData;
  Map<String, dynamic>? _hosData;
  List<dynamic>? _driverIncentiveLogs;
  Map<String, dynamic>? _currentTripData;
  Map<String, dynamic>? _violationData;
  List<dynamic>? _tripsData;
  List<dynamic>? _notificationsData;
  String? _token;
  String? _mixId;
  String? _sapId;

  bool get isTimerRunning => _isTimerRunning;
  Map<String, dynamic>? get profileData => _profileData;
  List<dynamic>? get eventData => _eventData;
  Map<String, dynamic>? get hosData => _hosData;
  List<dynamic>? get driverIncentiveLogs => _driverIncentiveLogs;
  Map<String, dynamic>? get currentTripData => _currentTripData;
  Map<String, dynamic>? get violationData => _violationData;
  List<dynamic>? get tripsData => _tripsData;
  List<dynamic>? get notificationsData => _notificationsData;
  String? get token => _token;
  String? get mixId => _mixId;
  String? get sapId => _sapId;
  String get currentStatusDescription =>
      _hosData?['currentStatusDescription'] ?? 'Not driving';
  Duration get remainingTime => _timerService.duration;
  Duration get availableDrivingBeforeBreak =>
      parseDuration(_hosData?['availableDrivingBeforeBreak'] ?? 'PT4H');
  String get safetyCategory => _hosData?['safetyCategory'] ?? 'UNKNOWN';

  Box? _box;

  List<Map<String, String>> _notificationsData2 = [];

  List<Map<String, String>> get notificationsData2 => _notificationsData2;

  WebSocketChannel? _channel;

  List<dynamic>? _assignmentsData;
  List<dynamic>? get assignmentsData => _assignmentsData;

  List<Map<String, String>> _banks = [];
  List<Map<String, String>> get banks => _banks;

  Map<String, dynamic>? _ratingResponse; // Store the rating response

  // Getter to expose the response
  Map<String, dynamic>? get ratingResponse => _ratingResponse;

  // Ensure the Hive box is opened only once and reused across different methods
  Future<Box> _getBox() async {
    _box ??= await Hive.openBox('dataBox');
    return _box!;
  }

  Future<void> _ensureTokenAndMixIdLoaded() async {
    try {
      var box = await _getBox();
      _token ??= box.get('token');
      _mixId ??= box.get('mixId');
      _sapId ??= box.get('sapId'); // Load sapId from storage

      if (_token == null ||
          _mixId == null ||
          _mixId!.isEmpty ||
          _sapId == null ||
          _sapId!.isEmpty) {
        throw Exception('User not authenticated or Driver ID is missing');
      }
    } catch (e) {
      throw Exception('OperationError: Failed to load token, mixId, or sapId');
    }
  }

  Future<bool> isSessionValid() async {
    try {
      bool isValid = await _authService.isSessionValid();
      // print('Session valid: $isValid');
      return isValid;
    } catch (e) {
      // print('Error checking session validity: $e');
      throw Exception('OperationError: Failed to check session validity');
    }
  }

  Future<void> loadInitialData() async {
    try {
      await _ensureTokenAndMixIdLoaded();

      await fetchProfile(_mixId!);
      await fetchHosData(_mixId!, _token!);
      // print('Loading violations from $startDate to $endDate');
      await fetchViolations(_mixId!);
      await fetchTrips(_mixId!, last100Days: true);
      await fetchNotifications();
    } catch (e) {
      // print('Error during data loading: $e');
      throw Exception('OperationError: Failed to load initial data');
    }
  }

  Future<void> setToken(String token) async {
    try {
      _token = token;
      var box = await _getBox();
      await box.put('token', token);
      // print('Token set: $token');
      notifyListeners();
    } catch (e) {
      // print('Error setting token: $e');
      throw Exception('OperationError: Failed to set token');
    }
  }

  Future<void> setMixId(String mixId) async {
    try {
      _mixId = mixId;
      var box = await _getBox();
      await box.put('mixId', mixId);
      // print('MixId set: $mixId');
      notifyListeners();
    } catch (e) {
      // print('Error setting mixId: $e');
      throw Exception('OperationError: Failed to set mixId');
    }
  }

  Future<void> setSapId(String sapId) async {
    try {
      _sapId = sapId;
      var box = await _getBox();
      await box.put('sapId', sapId); // Persist sapId in the Hive box
      notifyListeners();
    } catch (e) {
      throw Exception('OperationError: Failed to set sapId');
    }
  }

  void handleOtpResponse(Map<String, dynamic> otpResponse) async {
    try {
      print('OTP Response: $otpResponse'); // Debugging line
      if (otpResponse['isSuccessful'] == true) {
        final result = otpResponse['result'];

        if (result != null) {
          // Set the token
          setToken(
            result['token']?.toString() ?? '',
          ); // Convert token to string safely

          // Extract profile information from `user` -> `profile`
          final user = result['user'];
          if (user != null) {
            final profile = user['profile'];
            if (profile != null) {
              setMixId(
                profile['mixDriverId']?.toString() ?? '',
              ); // Ensure mixDriverId is a string
              setSapId(
                profile['sapId']?.toString() ?? '',
              ); // Ensure sapId is a string
              _profileData = profile; // Set _profileData correctly
            } else {
              print('Profile is null');
            }
          } else {
            print('User section is null');
          }

          notifyListeners();
        } else {
          print('Result section is null');
        }
      } else {
        throw Exception('OTP response was not successful');
      }
    } catch (e) {
      print('Error handling OTP response: ${e.toString()}');
    }
  }

  Future<void> fetchProfile(String sapId) async {
    // await _ensureTokenAndMixIdLoaded();

    try {
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/profile/driver/$sapId',
        ),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'app-version': '1.12',
          'app-name': 'driver app',
        },
      );

      if (response.statusCode == 200) {
        // print(response.body);
        _profileData = jsonDecode(response.body)['result'];
        print('Profile data fetched successfully. ${_profileData}');
        // print(UR);
        notifyListeners();
      } else {
        // print('Failed to fetch profile: ${response.body}');
        throw Exception('OperationError: Failed to fetch profile');
      }
    } catch (e) {
      // print('Error fetching profile: $e');
      throw Exception('No Network');
    }
  }

  Future<void> fetchProfileData() async {
    if (_sapId != null) {
      await fetchProfile(_sapId!);
    } else {
      throw Exception('SAP ID is not available for fetching profile data.');
    }
  }

  Future<void> loadTokenAndMixId() async {
    var box = await _getBox();
    _token = box.get('token');
    _mixId = box.get('mixId');
    if (_token == null || _mixId == null) {
      print('Failed to load token or mixId');
    } else {
      print('Token and mixId loaded successfully');
    }
    notifyListeners();
  }
  // Method for data HOS CACHE
  void setHosData(Map<String, dynamic> data) {
    _hosData = data;
    if (currentStatusDescription == 'Driving' && !_isTimerRunning) {
      final remainingTime = parseDuration(_hosData?['availableDrivingBeforeBreak'] ?? 'PT4H');
      updateRemainingTime(remainingTime);
      startTimer();
    }
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
      debugPrint("This from HOS FUNCTION: ${response.body}");

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

  Future<void> driverIncentiveLog(String sapId, String token) async {
    // await _ensureTokenAndMixIdLoaded();

    try {
      final url = Uri.parse(
        'https://staging-812204315267.us-central1.run.app/incentive/logs/driver?driverSapId=$sapId',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('$data');
        if (data['isSuccessful'] == true) {
          _driverIncentiveLogs = data['result']; // Assign directly to a list
          notifyListeners();
        } else {
          throw Exception('Failed to fetch incentive logs: ${data['message']}');
        }
      } else {
        throw Exception('Failed to fetch incentive logs: ${response.body}');
      }
    } catch (e) {
      print('Error fetching incentive logs: $e');
      throw Exception('Failed to fetch incentive logs');
    }
  }

  // Future<void> fetchCurrentTrip(String token) async {
  //   try {
  //     final url = Uri.parse(
  //       'https://staging-812204315267.us-central1.run.app/trip/current',
  //     );

  //     final response = await http.get(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json; charset=UTF-8',
  //         'Authorization': 'Bearer $token',
  //         'app-version': '1.12',
  //         'app-name': 'drivers app',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       print('$data');
  //       if (data['isSuccessful'] == true) {
  //         _currentTripData = data['result']; // Assign directly to a list or map
  //         notifyListeners();
  //       } else {
  //         throw Exception('Failed to fetch current trip: ${data['message']}');
  //       }
  //     } else {
  //       throw Exception('Failed to fetch current trip: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Error fetching current trip: $e');
  //     throw Exception('Failed to fetch current trip');
  //   }
  // }

  Future<void> fetchCurrentTrip(String token) async {
    try {
      final url = Uri.parse(
        'https://staging-812204315267.us-central1.run.app/trip/current',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseBody['isSuccessful'] == true) {
          _currentTripData = responseBody['result'];
          notifyListeners();
        } else {
          // ❗Throw only the 'message' field as the exception
          throw Exception(responseBody['message']);
        }
      } else {
        throw Exception(
          responseBody['message'] ??
              'Failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching current trip: $e');
      rethrow;
    }
  }

  Future<void> fetchViolations(String mixId) async {
    await _ensureTokenAndMixIdLoaded();

    try {
      // Use the updated URL format
      final url =
          'https://staging-812204315267.us-central1.run.app/violations/$sapId/violations/today';

      print('Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );
      debugPrint('Violation for today: ${response.body}');

      if (response.statusCode == 200) {
        _violationData = jsonDecode(response.body)['result'];
        // print('Violations data fetched successfully.');
        print(response.body);
        notifyListeners();
      } else {
        throw Exception('Failed to fetch violations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch violations');
    }
  }

  Future<void> fetchAssignments() async {
    // await _ensureTokenAndMixIdLoaded();

    try {
      // Send HTTP GET request
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/assignment/all/driver',
        ),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result') &&
            jsonResponse['result'] != null &&
            jsonResponse['result'] is List) {
          final List<dynamic> assignmentsData = jsonResponse['result'];

          if (assignmentsData.isNotEmpty) {
            _assignmentsData =
                assignmentsData; // Assign the data to the provider variable
            notifyListeners(); // Notify listeners to update the UI
            print('Assignments data fetched successfully: $_assignmentsData');
          } else {
            print('No assignments found.');
            _assignmentsData = []; // Ensure the variable is a valid empty list
            notifyListeners();
          }
        } else {
          print('Invalid response structure: $jsonResponse');
          _assignmentsData = []; // Fallback to an empty list
          notifyListeners();
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.reasonPhrase}');
        throw Exception('Failed to fetch assignments: ${response.body}');
      }
    } catch (e) {
      print('Error fetching assignments: $e');
      throw Exception('Failed to fetch assignments');
    }
  }

  Future<http.Response> confirmPayment(String referenceId, String token) async {
    final url =
        "https://staging-812204315267.us-central1.run.app/payout/payment/confirm?referenceId=$referenceId";

    try {
      // Make the HTTP GET request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token', // Include the token
          'Content-Type': 'application/json',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      // Return the raw response to be processed by the caller
      return response;
    } catch (e) {
      throw Exception("Failed to confirm payment: $e");
    }
  }

  Future<Map<String, dynamic>> fetch10Trips(
    String mixId, {
    required bool last1000Days,
  }) async {
    await _ensureTokenAndMixIdLoaded();

    final DateFormat formatter = DateFormat('yyyyMMddHHmmss');
    final String startDate =
        last1000Days
            ? formatter.format(
              DateTime.now().subtract(const Duration(days: 1000)),
            )
            : formatter.format(
              DateTime(DateTime.now().year, DateTime.now().month, 1),
            );

    try {
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/driver/$sapId/orders/latest?limit=10',
        ),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _tripsData = responseData['result']['shipmentData'];
        notifyListeners();
        return responseData;
      } else {
        throw Exception('Failed to fetch trips: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch trips: $e');
    }
  }

  Future<Map<String, dynamic>> fetchTrips(
    String mixId, {
    required bool last100Days,
  }) async {
    await _ensureTokenAndMixIdLoaded();

    final DateFormat formatter = DateFormat('yyyyMMddHHmmss');
    final String startDate =
        last100Days
            ? formatter.format(
              DateTime.now().subtract(const Duration(days: 100)),
            )
            : formatter.format(
              DateTime(DateTime.now().year, DateTime.now().month, 1),
            );

    final String endDate = formatter.format(DateTime.now());

    try {
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/driver/$sapId/orders?startDate=$startDate&endDate=$endDate',
        ),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _tripsData = responseData['result']['shipmentData'];
        notifyListeners();
        return responseData; // Return the response data
      } else {
        throw Exception('Failed to fetch trips: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch trips');
    }
  }

  Future<void> fetchNotifications() async {
    await _ensureTokenAndMixIdLoaded();

    try {
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/driver/$sapId/notifications',
        ),
        // 'http://driverappservice.lapapps.ng:5124/driver/$sapId/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'App-Version': '1.12',
        },
      );

      if (response.statusCode == 200) {
        _notificationsData = jsonDecode(response.body)['result'];
        // print('Notifications data fetched successfully.');
        notifyListeners();
      } else {
        // print('Failed to fetch notifications: ${response.body}');
        throw Exception('Failed to fetch notifications: ${response.body}');
      }
    } catch (e) {
      // print('Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications: ${e.toString()}');
    }
  }

  Duration parseDuration(String duration) {
    final match = RegExp(r'PT(\d+H)?(\d+M)?(\d+S)?').firstMatch(duration);
    if (match == null) return const Duration();

    final hours = int.parse(match.group(1)?.replaceAll('H', '') ?? '0');
    final minutes = int.parse(match.group(2)?.replaceAll('M', '') ?? '0');
    final seconds = int.parse(match.group(3)?.replaceAll('S', '') ?? '0');
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  void updateRemainingTime(Duration duration) {
    _timerService.updateRemainingTime(duration);
    notifyListeners();
  }

  void startTimer() {
    _isTimerRunning = true;
    _timerService.startTimer();
    // print('Timer started.');
    notifyListeners();
  }

  void stopTimer() {
    _isTimerRunning = false;
    _timerService.stopTimer();
    // print('Timer stopped.');
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _mixId = null;
    var box = await _getBox();
    await box.delete('mixId'); // Clear mixId on logout
    await box.delete('token'); // Clear token on logout
    // print('User logged out. Token and mixId cleared.');
    notifyListeners();
  }

  void addNotification(String message, BuildContext context) {
    final newNotification = {
      'message': message,
      'elapsedTime': calculateElapsedTime(
        DateTime.now(),
      ), // Calculate elapsed time
    };
    _notificationsData2.add(newNotification);

    // Show a pop-up message (Snackbar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New Notification: $message'),
        duration: Duration(seconds: 3),
      ),
    );

    // Optionally save the notification to persistent storage
    _saveNotificationsToStorage();

    notifyListeners(); // Notify the UI to update
  }

  String calculateElapsedTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Method to fetch driver rating report and store the response
  Future<void> fetchDriverRatingReport(
    String startDate,
    String endDate,
    String sapId,
  ) async {
    await _ensureTokenAndMixIdLoaded(); // Ensure token and mixId are loaded

    final String url =
        'https://staging-812204315267.us-central1.run.app/rating/driver/report?startDate=$startDate&endDate=$endDate&driverNumber=$sapId&addRatings=true';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token', // Use the loaded token
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );
      // print(url);
      if (response.statusCode == 200) {
        _ratingResponse = jsonDecode(response.body); // Store the API response
        notifyListeners(); // Notify listeners to rebuild UI if needed
      } else {
        throw Exception(
          'Failed to fetch driver rating report: ${response.body}',
        );
      }
    } catch (e) {
      print("$startDate and $endDate $sapId");
      // print('Error fetching driver rating report: $e');
      throw Exception('OperationError: Failed to fetch driver rating report');
    }
  }

  Future<void> fetchBanks() async {
    // await _ensureTokenAndMixIdLoaded();

    try {
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/payout/banks',
        ),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        // Debug to check if `result` exists and what it contains
        if (decodedResponse.containsKey('result') &&
            decodedResponse['result'] is List) {
          final bankList = decodedResponse['result'];
          print(
            'Parsed bank list: $bankList',
          ); // To verify the structure of bankList

          _banks =
              bankList.map<Map<String, String>>((bank) {
                return {
                  "name": bank["name"].toString(),
                  "code": bank["code"].toString(),
                };
              }).toList();

          print(
            'Mapped banks: $_banks',
          ); // To verify final structure of `_banks`
          notifyListeners();
        } else {
          throw Exception(
            'Unexpected response format: "result" key missing or not a list',
          );
        }
      } else {
        throw Exception('Failed to fetch bank list: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('OperationError: Failed to fetch banks ${e.toString()}');
    }
  }

  Future<Map<String, String>> verifyAccount(
    String accountNumber,
    String bankCode,
  ) async {
    // await _ensureTokenAndMixIdLoaded();

    final url =
        'https://staging-812204315267.us-central1.run.app/payout/verify?accountNumber=$accountNumber&bankCode=$bankCode';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token', // Pass the token in the headers
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['isSuccessful'] == true) {
          final data = responseData['result']['data'];
          return {
            "account_name": data['account_name'],
            "account_number": data['account_number'],
          };
        } else {
          throw Exception('Verification failed: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to verify account: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OperationError: Failed to verify account: $e');
    }
  }

  Future<void> _saveNotificationsToStorage() async {
    var box = await _getBox();
    await box.put('notifications', _notificationsData2);
  }

  void connectWebSocket(BuildContext context) {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://your-websocket-url'), // Replace with your WebSocket URL
    );

    _channel?.stream.listen(
      (message) {
        addNotification(
          message,
          context,
        ); // Call addNotification on new message
      },
      onError: (error) {
        // print('WebSocket error: $error');
      },
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}

class LanguageProvider with ChangeNotifier {
  Map<String, String> _localizedStrings = {};
  String _currentLanguage = 'en';

  LanguageProvider() {
    loadLanguage(_currentLanguage);
  }

  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/lang/$languageCode.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      _currentLanguage = languageCode;
      // print('Language loaded: $languageCode');
      notifyListeners();
    } catch (e) {
      // print('Error loading language file: $e');
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
