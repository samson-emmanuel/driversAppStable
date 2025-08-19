// // ignore_for_file: unused_field, prefer_final_fields

// import 'dart:async';
// import 'dart:convert';
// import 'package:driversapp/hos_display.dart';
// import 'package:driversapp/licence_date_provider.dart';
// import 'package:driversapp/notification.dart';
// import 'package:driversapp/notification_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:location/location.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'data_provider.dart';
// import 'theme_provider.dart';
// import 'widgets/bottom_navigation.dart';

// class HomePage2 extends StatefulWidget {
//   const HomePage2({super.key});

//   @override
//   State<HomePage2> createState() => _HomePage2State();
// }

// class _HomePage2State extends State<HomePage2> with TickerProviderStateMixin {
//   bool _isSendingLocation = false;
//   Timer? _violationTimer;
//   Timer? _notificationTimer;
//   FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
//   final FlutterTts _flutterTts = FlutterTts();
//   String? _lastSpokenViolationTitle;
//   bool _isSpeaking = false;
//   Timer? _debounceTimer;
//   late AnimationController _blinkController;
//   Timer? _locationTimer;
//   bool _isPopupVisible = false;
//   double appVersion = 1.12;
//   Timer? _versionCheckTimer;
//   final FlutterLocalNotificationsPlugin localNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // Using ValueNotifier to track changes in violation data
//   Map<String, ValueNotifier<int>> _violationData = {
//     'totalViolations': ValueNotifier(0),
//     'dailyRestViolations': ValueNotifier(0),
//     'weeklyRestViolations': ValueNotifier(0),
//     'continuousDrivingViolations': ValueNotifier(0),
//     'overSpeedingViolations': ValueNotifier(0),
//     'harshBrakingViolations': ValueNotifier(0),
//     'harshAccelerationViolations': ValueNotifier(0),
//   };

//   Map<String, dynamic> _scoreCardData = {};
//   bool _isApiCallInProgress = false;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();

//     // Fetch violations data immediately
//     _fetchViolations(context);
//     _startLocationUpdates();

//     // Fetch HOS data immediately
//     _fetchHosData(context);

//     // Observe changes in the driver's status and manage the timer accordingly
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeNotifications();
//       _observeDriverStatus(context);
//       _startViolationTimer();
//       // _fetchLatestVersion();
//       _fetchAndShowNotification(context);
//     });

//     // Check for the latest version immediately
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _fetchLatestVersion();
//     });

//     // Add listeners to each ValueNotifier to handle changes
//     _violationData.forEach((key, notifier) {
//       notifier.addListener(() => _handleViolationChange(key, notifier.value));
//     });

//     // Initialize the blinking animation controller
//     _blinkController = AnimationController(
//       duration: const Duration(milliseconds: 500), // Speed of blinking
//       vsync: this,
//     )..repeat(reverse: true);
//   }

//   void _initializeNotifications() {
//     _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//     _flutterLocalNotificationsPlugin!.initialize(initializationSettings);
//   }

//   void _showNotification(String message) async {
//     if (_flutterLocalNotificationsPlugin == null) return;

//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//           'channel_id',
//           'channel_name',
//           importance: Importance.max,
//           priority: Priority.high,
//           showWhen: false,
//         );

//     const NotificationDetails platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//     );

//     await _flutterLocalNotificationsPlugin!.show(
//       0,
//       'Driver App',
//       message,
//       platformChannelSpecifics,
//       payload: 'item x',
//     );

//     // Ensure speaking happens after the notification
//     _speak(message);

//     // Notify the NotificationProvider of the new notification
//     Provider.of<NotificationProvider>(
//       context,
//       listen: false,
//     ).setHasNewNotification(true);
//   }

//   Future<void> _speak(String message) async {
//     if (_isSpeaking) return; // **Return if already speaking**

//     _isSpeaking = true; // **Set speaking flag**
//     await _flutterTts.setLanguage('en-US');
//     await _flutterTts.setPitch(1.5);
//     await _flutterTts.setSpeechRate(0.5);
//     await _flutterTts.speak(message);

//     // **Set completion handlers to reset speaking flag**
//     _flutterTts.setCompletionHandler(() {
//       _isSpeaking = false;
//     });

//     // **Handle cancellations**
//     _flutterTts.setCancelHandler(() {
//       _isSpeaking = false;
//     });

//     // **Handle errors to ensure speaking flag is reset**
//     _flutterTts.setErrorHandler((message) {
//       _isSpeaking = false;
//     });
//   }

//   @override
//   void dispose() {
//     _blinkController.dispose();
//     _flutterTts.stop(); // **Stop any ongoing TTS operations**
//     _debounceTimer?.cancel(); // **Cancel debounce timer if active**
//     _locationTimer?.cancel();
//     _versionCheckTimer?.cancel();
//     super.dispose();
//   }

//   void _startViolationTimer() {
//     if (_violationTimer != null && _violationTimer!.isActive) return;

//     _fetchViolations(context); // Initial fetch
//     _violationTimer = Timer.periodic(const Duration(seconds: 300), (timer) {
//       _fetchViolations(context);
//     });
//   }

//   Future<void> _fetchHosData(BuildContext context) async {
//     if (_isApiCallInProgress) return;

//     _isApiCallInProgress = true;
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);

//     try {
//       final mixId = dataProvider.profileData?['mixDriverId'] ?? '';
//       final token = dataProvider.token ?? '';
//       await dataProvider.fetchHosData(mixId, token);
//       final hosData = dataProvider.hosData;

//       if (hosData != null &&
//           dataProvider.currentStatusDescription == 'Driving') {
//         final initialDuration = _parseDuration(
//           dataProvider.availableDrivingBeforeBreak as String,
//         );
//         _startTimer(initialDuration);
//       }
//     } catch (e) {
//       // Handle exception
//     } finally {
//       _isApiCallInProgress = false;
//     }
//   }

//   void _startLocationUpdates() {
//     print('Starting location updates...');
//     _locationTimer?.cancel(); // Ensure existing timer is cleared
//     _sendingLocation(context);
//     _locationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
//       print('Triggering location update at ${DateTime.now()}');
//       _sendingLocation(context);
//     });
//   }

//   Future<void> _sendingLocation(BuildContext context) async {
//     print('Sending location at: ${DateTime.now()}');
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final token = dataProvider.token ?? '';
//     Location location = Location();

//     bool serviceEnabled = await location.serviceEnabled();
//     // print('Service enabled: $serviceEnabled');
//     if (!serviceEnabled) {
//       serviceEnabled = await location.requestService();
//       if (!serviceEnabled) {
//         debugPrint('Location service denied');
//         return;
//       }
//     }

//     PermissionStatus permissionGranted = await location.hasPermission();
//     print('Permission granted: $permissionGranted');
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) {
//         debugPrint('Location permission denied');
//         return;
//       }
//     }

//     if (permissionGranted == PermissionStatus.deniedForever) {
//       debugPrint('Location permission denied forever');
//       return;
//     }

//     LocationData locationData = await location.getLocation();
//     // print('Location: ${locationData.latitude}, ${locationData.longitude}');

//     final String apiUrl =
//         'https://staging-812204315267.us-central1.run.app/driver/location/update';
//     // 'http://driverappservice.lapapps.ng:5124/driver/location/update';
//     final Map<String, dynamic> payload = {
//       "longitude": locationData.longitude,
//       "latitude": locationData.latitude,
//     };

//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//           'app-version': '1.12',
//           'app-name': 'drivers app',
//         },
//         body: jsonEncode(payload),
//       );
//       print('$payload');

//       if (response.statusCode == 200) {
//         debugPrint('Location sent successfully.');
//       } else {
//         debugPrint('Failed to send location: ${response.body}');
//         debugPrint(response.statusCode.toString());
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error sending location: $e');
//       debugPrint('Stack trace: $stackTrace');
//     }
//   }

//   Duration _parseDuration(String duration) {
//     final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
//     final match = regex.firstMatch(duration);

//     if (match != null) {
//       final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
//       final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
//       final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
//       return Duration(hours: hours, minutes: minutes, seconds: seconds);
//     }

//     return Duration.zero;
//   }

//   void _startTimer(Duration initialDuration) {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);

//     // If status is Driving and timer is not already running
//     if (dataProvider.currentStatusDescription == 'Driving' &&
//         !dataProvider.isTimerRunning) {
//       // Set the timer to start from availableDrivingBeforeBreak
//       dataProvider.updateRemainingTime(initialDuration);
//       dataProvider.startTimer();

//       _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//         if (dataProvider.currentStatusDescription != 'Driving') {
//           timer.cancel();
//           dataProvider.stopTimer();
//           // When status changes to Not Driving, display availableDrivingBeforeBreak
//           dataProvider.updateRemainingTime(
//             _parseDuration(dataProvider.availableDrivingBeforeBreak as String),
//           );
//         } else {
//           final newRemainingTime =
//               dataProvider.remainingTime - const Duration(seconds: 1);
//           dataProvider.updateRemainingTime(newRemainingTime);
//         }
//       });
//     }
//   }

//   void _stopTimer() {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     dataProvider.stopTimer();
//     _notificationTimer?.cancel();
//   }

//   void _observeDriverStatus(BuildContext context) {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     dataProvider.addListener(() {
//       if (dataProvider.currentStatusDescription == 'Driving') {
//         final initialDuration = _parseDuration(
//           dataProvider.availableDrivingBeforeBreak as String,
//         );
//         _startTimer(initialDuration);
//       } else if (dataProvider.currentStatusDescription == 'Not Driving') {
//         _stopTimer();
//       }
//     });
//   }

//   Future<void> _fetchViolations(BuildContext context) async {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final mixId = dataProvider.profileData?['mixDriverId'] ?? '';

//     try {
//       await dataProvider.fetchViolations(mixId);
//       final violations = dataProvider.violationData;
//       final scoreCard = violations?['scoreCard'];

//       // Update each ValueNotifier with new data
//       _updateViolation('totalViolations', violations?['totalViolations'] ?? 0);
//       _updateViolation(
//         'dailyRestViolations',
//         violations?['dailyRestViolations'] ?? 0,
//       );
//       _updateViolation(
//         'weeklyRestViolations',
//         violations?['weeklyRestViolations'] ?? 0,
//       );
//       _updateViolation(
//         'continuousDrivingViolations',
//         violations?['continuousDrivingViolations'] ?? 0,
//       );
//       _updateViolation(
//         'overSpeedingViolations',
//         violations?['overSpeedingViolations'] ?? 0,
//       );
//       _updateViolation(
//         'harshBrakingViolations',
//         violations?['harshBrakingViolations'] ?? 0,
//       );
//       _updateViolation(
//         'harshAccelerationViolations',
//         violations?['harshAccelerationViolations'] ?? 0,
//       );

//       if (scoreCard != null) {
//         _scoreCardData['totalDistance'] =
//             scoreCard['totalDistance']?.toString() ?? '0';
//         _scoreCardData['totalDuration'] =
//             scoreCard['totalDuration']?.toString() ?? '0';
//         _scoreCardData['totalTrips'] =
//             scoreCard['totalTrips']?.toString() ?? '0';
//         _scoreCardData['totalScore'] =
//             scoreCard['totalScore']?.toString() ?? '0';
//         _scoreCardData['safetyCategory'] =
//             scoreCard['safetyCategory']?.toString() ?? 'UNKNOWN';
//       }
//     } catch (e) {
//       // Handle exception
//     }
//   }

//   // Helper method to update the ValueNotifier
//   void _updateViolation(String key, int newValue) {
//     if (_violationData[key]?.value != newValue) {
//       _violationData[key]?.value = newValue;
//     }
//   }

//   // **Modified to include debounce mechanism and TTS control**
//   void _handleViolationChange(String key, int newValue) {
//     final currentTitle = _getViolationTitle(key);
//     final message = '$currentTitle increased to $newValue. Drive carefully.';

//     // **Debouncing to prevent multiple triggers**
//     _debounceTimer?.cancel();
//     _debounceTimer = Timer(const Duration(milliseconds: 300), () {
//       if (_lastSpokenViolationTitle != currentTitle && !_isSpeaking) {
//         // **Check if speaking is ongoing**
//         _lastSpokenViolationTitle = currentTitle;
//         _showNotification(message);
//       }
//     });
//   }

//   String _getViolationTitle(String key) {
//     switch (key) {
//       case 'totalViolations':
//         return 'Total Violations';
//       case 'dailyRestViolations':
//         return 'Daily Rest Violations';
//       case 'weeklyRestViolations':
//         return 'Weekly Rest Violations';
//       case 'continuousDrivingViolations':
//         return 'Continuous Driving Violations';
//       case 'overSpeedingViolations':
//         return 'Over Speeding Violations';
//       case 'harshBrakingViolations':
//         return 'Harsh Braking Violations';
//       case 'harshAccelerationViolations':
//         return 'Harsh Acceleration Violations';
//       default:
//         return 'Violation';
//     }
//   }

//   Future<void> _sendLocation(BuildContext context) async {
//     if (_isApiCallInProgress) return;

//     _isApiCallInProgress = true;
//     setState(() {
//       _isSendingLocation = true;
//     });

//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final token = dataProvider.token ?? '';
//     final sapId = dataProvider.profileData?['sapId'] ?? '';

//     Location location = Location();

//     bool serviceEnabled;
//     PermissionStatus permissionGranted;
//     LocationData locationData;

//     serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await location.requestService();
//       if (!serviceEnabled) {
//         setState(() {
//           _isSendingLocation = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Location services are disabled. Please enable them to continue.',
//             ),
//           ),
//         );
//         return;
//       }
//     }

//     permissionGranted = await location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await location.requestPermission();
//       if (permissionGranted == PermissionStatus.denied) {
//         setState(() {
//           _isSendingLocation = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Location permissions are denied. Please allow location access to continue.',
//             ),
//           ),
//         );
//         return;
//       }
//     }

//     if (permissionGranted == PermissionStatus.deniedForever) {
//       setState(() {
//         _isSendingLocation = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Location permissions are permanently denied. Please enable them from settings.',
//           ),
//         ),
//       );
//       return;
//     }

//     try {
//       locationData = await location.getLocation();
//     } catch (e) {
//       setState(() {
//         _isSendingLocation = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to get location. Please try again.'),
//         ),
//       );
//       return;
//     }

//     const String apiUrl =
//         'http://staging-812204315267.us-central1.run.app/support/submit';
//     // 'http://driverappservice.lapapps.ng:5124/support/submit';
//     final Map<String, dynamic> payload = {
//       "supportType": "PANIC",
//       "description": "",
//       "driverSapId": sapId,
//       "longitude": "${locationData.longitude}",
//       "latitude": "${locationData.latitude}",
//     };

//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//           'app-version': '1.12',
//           'app-name': 'drivers app',
//         },
//         body: jsonEncode(payload),
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Message sent successfully')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to send message. Please try again.'),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Error occurred while sending message. Please try again.',
//           ),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isSendingLocation = false;
//       });
//     }
//     _isApiCallInProgress = false;
//   }

//   Color getSafetyCategoryColor(String category) {
//     switch (category) {
//       case 'GREEN':
//         return Colors.green;
//       case 'AMBER':
//         return Colors.amber;
//       case 'RED':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Future<void> _fetchLatestVersion() async {
//     debugPrint("Checking for the latest version...");

//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final String token = dataProvider.token ?? '';

//     const String url =
//         "https://staging-812204315267.us-central1.run.app/driver-app/latest";

//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//           'app-version': '1.12',
//           'app-name': 'drivers app',
//         },
//       );

//       debugPrint("Response status: ${response.statusCode}");
//       debugPrint("Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data.containsKey("result") &&
//             data["result"].containsKey("version")) {
//           final latestVersion =
//               double.tryParse(data["result"]["version"].toString()) ?? 0.0;
//           final downloadLink = data["result"]["link"] ?? '';

//           debugPrint(
//             "App Version: $appVersion, Latest Version: $latestVersion",
//           );

//           // SHOW POPUP AS LONG AS THE VERSIONS ARE NOT EQUAL
//           if (appVersion != latestVersion) {
//             debugPrint("Version mismatch! Showing update popup...");
//             await _showDownloadPopup(downloadLink);
//           }
//         } else {
//           debugPrint("Invalid API response: $data");
//         }
//       } else {
//         debugPrint("Failed to fetch version. Status: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Error fetching version: $e");
//     }
//   }

//   Future<void> _showDownloadPopup(String downloadUrl) async {
//     if (!mounted) return;

//     setState(() {
//       _isPopupVisible = true;
//     });

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Update Available"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "A new version of the app is available. Please download the update.",
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   final Uri url = Uri.parse(downloadUrl);
//                   if (!await launchUrl(
//                     url,
//                     mode: LaunchMode.externalApplication,
//                   )) {
//                     throw 'Could not launch $url';
//                   }
//                 },
//                 child: const Text("Download"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Close"),
//             ),
//           ],
//         );
//       },
//     );

//     setState(() {
//       _isPopupVisible = false;
//     });
//   }

//   // Function to fect Notification from the backend unread notification
//   Future<void> _fetchAndShowNotification(BuildContext context) async {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final String token = dataProvider.token ?? '';

//     const String url =
//         "https://staging-812204315267.us-central1.run.app/notification/all";

//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//           'app-version': '1.12',
//           'app-name': 'drivers app',
//         },
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = jsonDecode(response.body);
//         if (data["isSuccessful"] == true) {
//           List<dynamic> notifications = data["result"];

//           // Find the first unread notification
//           var unreadNotification = notifications.firstWhere(
//             (notif) => notif["isRead"] == false,
//             orElse: () => null,
//           );

//           if (unreadNotification != null) {
//             _showNotificationPopup(
//               context,
//               unreadNotification["title"],
//               unreadNotification["message"],
//             );
//           }
//         }
//       } else {
//         debugPrint(
//           "Failed to fetch notifications. Status: ${response.statusCode}",
//         );
//       }
//     } catch (e) {
//       debugPrint("Error fetching notifications: $e");
//     }
//   }

//   // Function to display the popup notification
//   Future<void> _showNotificationPopup(
//     BuildContext context,
//     String title,
//     String message,
//   ) async {
//     if (!context.mounted) return;

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text(title, style: const TextStyle(color: Colors.white)),
//           content: Text(message, style: const TextStyle(color: Colors.white)),
//           backgroundColor: Colors.grey[900],
//           actions: [
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(context).pop(); // Close popup
//                 await _markNotificationsAsRead(); // Mark as read
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Function to mark as read
//   Future<void> _markNotificationsAsRead() async {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final String token = dataProvider.token ?? '';

//     const String url =
//         "https://staging-812204315267.us-central1.run.app/notification/all/mark-as-read";

//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//           'app-version': '1.12',
//           'app-name': 'drivers app',
//         },
//       );

//       if (response.statusCode == 200) {
//         debugPrint("Notifications marked as read successfully.");
//       } else {
//         debugPrint(
//           "Failed to mark notifications as read. Status: ${response.statusCode}",
//         );
//       }
//     } catch (e) {
//       debugPrint("Error marking notifications as read: $e");
//     }
//   }

//   // function responsible for periodic check
//   // void _startVersionCheck() {
//   //   _versionCheckTimer?.cancel(); // Cancel any existing timer

//   //   _versionCheckTimer = Timer.periodic(const Duration(hours: 12), (
//   //     timer,
//   //   ) async {
//   //     final latestVersionData = await _fetchLatestVersion();
//   //     if (latestVersionData != null) {
//   //       final double latestVersion = latestVersionData["version"];
//   //       final String downloadLink = latestVersionData["link"];

//   //       if (appVersion < latestVersion && !_isPopupVisible) {
//   //         _showDownloadPopup(downloadLink);
//   //       }
//   //     }
//   //   });
//   // }

//   void _startVersionCheck() {
//     _versionCheckTimer?.cancel(); // Cancel any existing timer

//     _versionCheckTimer = Timer.periodic(const Duration(hours: 12), (timer) {
//       debugPrint("Periodic version check triggered...");
//       _fetchLatestVersion(); // Fetch latest version every 12 hours
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final languageProvider = Provider.of<LanguageProvider>(context);
//     final profileData = Provider.of<DataProvider>(context).profileData;
//     final violationData = Provider.of<DataProvider>(context).violationData;
//     final driverName = profileData?['driverName'] ?? 'User';
//     final safetyCategory = _scoreCardData['safetyCategory'] ?? 'UNKNOWN';
//     final safetyCategoryColor = getSafetyCategoryColor(safetyCategory);
//     final hasNewNotification =
//         Provider.of<NotificationProvider>(context).hasNewNotification;

//     // Sections for the licence dates
//     final licenseExpiryDateStr = profileData?['licenseExpiryDate'] ?? 'N/A';
//     final ddtExpiryDateStr = profileData?['ddtExpiryDate'] ?? 'N/A';
//     final isDarkMode = themeProvider.isDarkMode;
//     final dataProvider = Provider.of<DataProvider>(context, listen: false); 

//     // section for days left
//     DateTime? licenseExpiryDate = LicenseDateProvider.parseDate(
//       licenseExpiryDateStr,
//     );
//     DateTime? ddtExpiryDate = LicenseDateProvider.parseDate(ddtExpiryDateStr);

//     int licenseDaysLeft = LicenseDateProvider.calculateDaysLeft(
//       licenseExpiryDate,
//     );
//     int ddtDaysLeft = LicenseDateProvider.calculateDaysLeft(ddtExpiryDate);

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
//         appBar: AppBar(
//           backgroundColor: const Color.fromARGB(
//             255,
//             36,
//             98,
//             38,
//           ), // Green color for the app bar
//           leading: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
//             child: Row(
//               children: [
//                 Flexible(
//                   child: FloatingActionButton(
//                     onPressed: () {
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return StatefulBuilder(
//                             builder: (context, setState) {
//                               return AlertDialog(
//                                 title: Text(
//                                   languageProvider.translate('Panic Button'),
//                                   style: const TextStyle(color: Colors.white),
//                                 ),
//                                 backgroundColor:
//                                     Colors
//                                         .grey[800], // Grey color for the popup
//                                 content: Text(
//                                   languageProvider.translate(
//                                     'Are you sure you want to trigger the panic action?',
//                                   ),
//                                   style: const TextStyle(color: Colors.white),
//                                 ),
//                                 actions: <Widget>[
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                     },
//                                     style: TextButton.styleFrom(
//                                       foregroundColor: Colors.white,
//                                       backgroundColor: Colors.grey,
//                                     ),
//                                     child: Text(
//                                       languageProvider.translate('No'),
//                                     ),
//                                   ),
//                                   ElevatedButton(
//                                     onPressed: () async {
//                                       setState(() {
//                                         _isSendingLocation = true;
//                                       });
//                                       await _sendLocation(context);
//                                       setState(() {
//                                         _isSendingLocation = false;
//                                       });
//                                       Navigator.of(context).pop();

//                                       showDialog(
//                                         context: context,
//                                         builder: (BuildContext context) {
//                                           return AlertDialog(
//                                             backgroundColor: Colors.black,
//                                             content: SizedBox(
//                                               height: 100,
//                                               child: Center(
//                                                 child: Column(
//                                                   mainAxisSize:
//                                                       MainAxisSize.min,
//                                                   children: [
//                                                     Text(
//                                                       languageProvider
//                                                           .translate(
//                                                             'Message sent',
//                                                           ),
//                                                       style: const TextStyle(
//                                                         color: Colors.white,
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 10),
//                                                     SizedBox(
//                                                       width: 80,
//                                                       child: ElevatedButton(
//                                                         onPressed: () {
//                                                           Navigator.of(
//                                                             context,
//                                                           ).pop();
//                                                         },
//                                                         style:
//                                                             ElevatedButton.styleFrom(
//                                                               backgroundColor:
//                                                                   Colors.grey,
//                                                             ),
//                                                         child: Text(
//                                                           languageProvider
//                                                               .translate(
//                                                                 'Close',
//                                                               ),
//                                                           style:
//                                                               const TextStyle(
//                                                                 fontSize: 9,
//                                                                 color:
//                                                                     Colors
//                                                                         .white,
//                                                               ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       );
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green[900],
//                                     ),
//                                     child:
//                                         _isSendingLocation
//                                             ? const SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               child: CircularProgressIndicator(
//                                                 color: Colors.white,
//                                                 strokeWidth: 2,
//                                               ),
//                                             )
//                                             : Text(
//                                               languageProvider.translate('Yes'),
//                                               style: const TextStyle(
//                                                 color: Colors.white,
//                                               ),
//                                             ),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                       );
//                     },
//                     backgroundColor: Colors.red[900],
//                     mini: true,
//                     child: const Icon(Icons.warning),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           automaticallyImplyLeading: false,
//           centerTitle: true,
//           title: const Text(
//             "Drivers App",
//             style: TextStyle(color: Colors.white),
//           ),
//           actions: [
//             IconButton(
//               onPressed: () {
//                 // Reset the notification indicator when the notifications page is opened
//                 Provider.of<NotificationProvider>(
//                   context,
//                   listen: false,
//                 ).setHasNewNotification(false);

//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const NotificationPage(),
//                   ),
//                 );
//               },
//               icon: Icon(
//                 Icons.notifications,
//                 color:
//                     hasNewNotification
//                         ? Colors.white
//                         : Colors.red, // Change icon color based on state
//               ),
//             ),


//             IconButton(
//               onPressed:
//                   dataProvider.currentStatusDescription == 'Driving'
//                       ? null
//                       : () {
//                         showDialog(
//                           context: context,
//                           builder: (BuildContext context) {
//                             return AlertDialog(
//                               title: Text(
//                                 languageProvider.translate('Want to Talk?'),
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                               backgroundColor: Colors.grey[800],
//                               content: ElevatedButton(
//                                 onPressed: () {
//                                   const whatsappUrl =
//                                       'https://api.whatsapp.com/send?phone=2349062964972';
//                                   launchUrl(Uri.parse(whatsappUrl));
//                                 },
//                                 style: TextButton.styleFrom(
//                                   backgroundColor: const Color.fromARGB(
//                                     255,
//                                     22,
//                                     144,
//                                     49,
//                                   ),
//                                 ),
//                                 child: Text(
//                                   languageProvider.translate(
//                                     'Talk to Customer Service',
//                                   ),
//                                   style: const TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                               actions: <Widget>[
//                                 ElevatedButton(
//                                   onPressed: () {
//                                     Navigator.of(context).pop();
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.grey,
//                                   ),
//                                   child: Text(
//                                     languageProvider.translate('Close'),
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         );
//                       },
//               icon: const Icon(Icons.wechat, color: Colors.white),
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.person_rounded,
//                       color:
//                           themeProvider.isDarkMode
//                               ? Colors.white
//                               : Colors.black,
//                     ),
//                     Text(
//                       '${languageProvider.translate('Hi')} $driverName',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//                 ProfileDetail(
//                   icon: Icons.score_outlined,
//                   title: languageProvider.translate('Daily Score Card'),
//                   value:
//                       violationData?['scoreCard']?['safetyCategory']
//                           ?.toString() ??
//                       'UNKNOWN',
//                   iconColor: safetyCategoryColor,
//                 ),
//                 const SizedBox(width: 10),
//                 Container(
//                   // color: isDarkMode ? Colors.black : Colors.white,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 3.0,
//                       vertical: 3,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         _buildDetailCard(
//                           'License Status',
//                           licenseDaysLeft < 0
//                               ? 'License has expired'
//                               : '$licenseDaysLeft days left',
//                           isDarkMode,
//                           _blinkController,
//                           LicenseDateProvider.getDaysLeftColor(
//                             licenseDaysLeft,
//                             isDarkMode,
//                           ),
//                         ),
//                         // const SizedBox(height: 0),
//                         _buildDetailCard(
//                           'DDT Status',
//                           ddtDaysLeft < 0
//                               ? 'DDT has expired'
//                               : '$ddtDaysLeft days left',
//                           isDarkMode,
//                           _blinkController,
//                           LicenseDateProvider.getDaysLeftColor(
//                             ddtDaysLeft,
//                             isDarkMode,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   violationData?['scoreCard']?['totalScore']?.toString() ?? '0',
//                   style: TextStyle(fontSize: 20, color: safetyCategoryColor),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   languageProvider.translate(
//                     Provider.of<DataProvider>(context).currentStatusDescription,
//                   ),
//                   style: TextStyle(
//                     fontSize: 18,
//                     color:
//                         themeProvider.isDarkMode ? Colors.white : Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Center(
//                   child: CircularIndicator(
//                     duration: Provider.of<DataProvider>(context).remainingTime,
//                     onUpdate: (duration) {
//                       Provider.of<DataProvider>(
//                         context,
//                         listen: false,
//                       ).updateRemainingTime(duration);
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Column(
//                   children: [
//                     Text(
//                       languageProvider.translate('Violation Count'),
//                       style: const TextStyle(color: Colors.green, fontSize: 14),
//                     ),
//                     const SizedBox(height: 2),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ValueListenableBuilder<int>(
//                             valueListenable:
//                                 _violationData['dailyRestViolations']!,
//                             builder: (context, value, child) {
//                               return InfoCard(
//                                 identifier: 'dailyRestViolations',
//                                 title: languageProvider.translate('Daily Rest'),
//                                 value: value.toString(),
//                                 scoreValue:
//                                     (violationData?['dailyRestViolationsScore'] ??
//                                             '0')
//                                         .toString(),
//                                 icon: Icons.warning,
//                                 thresholdGreen: 1,
//                                 thresholdAmber: 21,
//                                 thresholdRed: 51,
//                                 iconColor: const Color.fromARGB(
//                                   255,
//                                   255,
//                                   184,
//                                   90,
//                                 ),
//                                 context: context,
//                                 violationData: {},
//                               );
//                             },
//                           ),
//                         ),
//                         Expanded(
//                           child: ValueListenableBuilder<int>(
//                             valueListenable:
//                                 _violationData['weeklyRestViolations']!,
//                             builder: (context, value, child) {
//                               return InfoCard(
//                                 identifier: 'weeklyRestViolations',
//                                 title: languageProvider.translate(
//                                   'Weekly Rest',
//                                 ),
//                                 value: value.toString(),
//                                 scoreValue:
//                                     (violationData?['weeklyRestViolationsScore'] ??
//                                             '0')
//                                         .toString(),
//                                 icon: Icons.warning,
//                                 thresholdGreen: 1,
//                                 thresholdAmber: 21,
//                                 thresholdRed: 51,
//                                 iconColor: const Color.fromARGB(
//                                   255,
//                                   255,
//                                   184,
//                                   90,
//                                 ),
//                                 context: context,
//                                 violationData: {},
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ValueListenableBuilder<int>(
//                         valueListenable:
//                             _violationData['continuousDrivingViolations']!,
//                         builder: (context, value, child) {
//                           return InfoCard(
//                             identifier: 'continuousDrivingViolations',
//                             title: languageProvider.translate(
//                               'Continuous Driving',
//                             ),
//                             value: value.toString(),
//                             scoreValue:
//                                 (violationData?['continuousDrivingViolationsScore'] ??
//                                         '0')
//                                     .toString(),
//                             icon: Icons.directions_car,
//                             thresholdGreen: 1,
//                             thresholdAmber: 21,
//                             thresholdRed: 51,
//                             iconColor: Colors.purple,
//                             context: context,
//                             violationData: {},
//                           );
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: ValueListenableBuilder<int>(
//                         valueListenable:
//                             _violationData['harshAccelerationViolations']!,
//                         builder: (context, value, child) {
//                           return InfoCard(
//                             identifier: 'harshAccelerationViolations',
//                             title: languageProvider.translate(
//                               'Harsh Acceleration',
//                             ),
//                             value: value.toString(),
//                             scoreValue:
//                                 (violationData?['harshAccelerationViolationsScore'] ??
//                                         '0')
//                                     .toString(),
//                             icon: Icons.sports_motorsports,
//                             thresholdGreen: 1,
//                             thresholdAmber: 21,
//                             thresholdRed: 51,
//                             iconColor: const Color.fromARGB(255, 13, 58, 14),
//                             context: context,
//                             violationData: {},
//                           );
//                         },
//                       ),

                
//                     ),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ValueListenableBuilder<int>(
//                         valueListenable:
//                             _violationData['overSpeedingViolations']!,
//                         builder: (context, value, child) {
//                           return InfoCard(
//                             identifier: 'overSpeedingViolations',
//                             title: languageProvider.translate('Over Speeding'),
//                             value: value.toString(),
//                             scoreValue:
//                                 (violationData?['overSpeedingViolationsScore'] ??
//                                         '0')
//                                     .toString(),
//                             icon: Icons.speed,
//                             thresholdGreen: 1,
//                             thresholdAmber: 21,
//                             thresholdRed: 51,
//                             iconColor: const Color.fromARGB(255, 81, 28, 25),
//                             context: context,
//                             violationData: {},
//                           );
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: ValueListenableBuilder<int>(
//                         valueListenable:
//                             _violationData['harshBrakingViolations']!,
//                         builder: (context, value, child) {
//                           return InfoCard(
//                             identifier: 'harshBrakingViolations',
//                             title: languageProvider.translate('Harsh Braking'),
//                             value: value.toString(),
//                             scoreValue:
//                                 (violationData?['harshBrakingViolationsScore'] ??
//                                         '0')
//                                     .toString(),
//                             icon: Icons.do_not_disturb,
//                             thresholdGreen: 1,
//                             thresholdAmber: 21,
//                             thresholdRed: 51,
//                             iconColor: const Color.fromARGB(255, 104, 90, 255),
//                             context: context,
//                             violationData: {},
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 ValueListenableBuilder<int>(
//                   valueListenable: _violationData['totalViolations']!,
//                   builder: (context, value, child) {
//                     return InfoCard(
//                       identifier: 'totalViolations',
//                       title: languageProvider.translate('Total Violations'),
//                       value: value.toString(),
//                       scoreValue: (violationData?[''] ?? '0').toString(),
//                       icon: Icons.error,
//                       thresholdGreen: 1,
//                       thresholdAmber: 21,
//                       thresholdRed: 51,
//                       iconColor: const Color.fromARGB(255, 81, 28, 25),
//                       context: context,
//                       violationData: {},
//                     );
//                   },
//                 ),
//                 InfoCard(
//                   identifier: 'totalDistance',
//                   title: languageProvider.translate('Total Distance (km)'),
//                   value: (violationData?['totalDistance'] ?? '0').toString(),
//                   scoreValue: '0',
//                   icon: Icons.directions,
//                   thresholdGreen: 1,
//                   thresholdAmber: 21,
//                   thresholdRed: 51,
//                   iconColor: Colors.green,
//                   context: context,
//                   violationData: {},
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Last Update:\n${violationData?['lastUpdated'] ?? 'N/A'}',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? const Color.fromARGB(255, 255, 255, 255)
//                                 : Colors.black,
//                       ),
//                     ),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const ProgressPage(),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                       ),
//                       child: Text(
//                         languageProvider.translate('Check other HOS Timer'),
//                         style: const TextStyle(
//                           fontSize: 10,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         bottomNavigationBar: const BottomNavigation(currentIndex: 0),
//       ),
//     );
//   }
// }

// class CircularIndicator extends StatefulWidget {
//   final Duration duration;
//   final void Function(Duration) onUpdate;

//   const CircularIndicator({
//     super.key,
//     required this.duration,
//     required this.onUpdate,
//   });

//   @override
//   _CircularIndicatorState createState() => _CircularIndicatorState();
// }

// class _CircularIndicatorState extends State<CircularIndicator> {
//   Timer? _timer;
//   late Duration _duration;
//   Map<int, bool> _notifiedIntervals = {};

//   @override
//   void initState() {
//     super.initState();
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);

//     if (dataProvider.currentStatusDescription == 'Driving') {
//       _duration = widget.duration;
//       _startTimer();
//     } else {
//       _duration = dataProvider.availableDrivingBeforeBreak;
//     }
//   }

//   void _startTimer() {
//     _notifiedIntervals.clear(); // Clear previously triggered intervals

//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_duration.inSeconds == 0) {
//         timer.cancel();
//       } else {
//         setState(() {
//           _duration = _duration - const Duration(seconds: 1);
//           widget.onUpdate(_duration);

//           // Handle voice notifications at specific intervals
//           _handleVoiceNotifications(_duration);
//         });
//       }
//     });
//   }

//   void _handleVoiceNotifications(Duration remainingTime) {
//     final int minutes = remainingTime.inMinutes;

//     if (_notifiedIntervals[minutes] == true) {
//       // Notification for this interval has already been triggered
//       return;
//     }

//     if ([59, 30, 15, 10, 5, 3, 2, 1].contains(minutes)) {
//       final int hours = remainingTime.inHours;
//       final message =
//           'You have ${hours > 0 ? '$hours hours and ' : ''}$minutes minutes left to drive';

//       _showNotification(message);

//       // Mark this interval as notified
//       _notifiedIntervals[minutes] = true;
//     }
//   }

//   Future<void> _showNotification(String message) async {
//     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//     final flutterTts = FlutterTts();

//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//           'channel_id',
//           'channel_name',
//           importance: Importance.max,
//           priority: Priority.high,
//           showWhen: false,
//         );

//     const NotificationDetails platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//     );

//     await flutterLocalNotificationsPlugin.show(
//       0,
//       'Driver App',
//       message,
//       platformChannelSpecifics,
//       payload: 'item x',
//     );

//     // Ensure speaking happens after the notification
//     await flutterTts.setLanguage('en-US');
//     await flutterTts.setPitch(2.0); // Adjusted to a more natural pitch
//     await flutterTts.speak(message);
//   }

//   Color _getColor() {
//     if (_duration.inHours >= 2) {
//       return Colors.green;
//     } else if (_duration.inHours >= 1) {
//       return Colors.amber;
//     } else {
//       return Colors.red;
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 150,
//       height: 150,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           CircularProgressIndicator(
//             value: _duration.inSeconds / (4 * 3600),
//             strokeWidth: 12,
//             backgroundColor: Colors.grey[800],
//             valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
//           ),
//           Center(
//             child: Text(
//               '${_duration.inHours.toString().padLeft(2, '0')}:${(_duration.inMinutes % 60).toString().padLeft(2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
//               style: const TextStyle(fontSize: 22, color: Colors.green),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class InfoCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final String scoreValue;
//   final IconData icon;
//   final int thresholdGreen;
//   final int thresholdAmber;
//   final int thresholdRed;
//   final Color iconColor;
//   final Map<String, dynamic> violationData;
//   final String identifier;
//   final BuildContext context;

//   const InfoCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.scoreValue,
//     required this.icon,
//     required this.thresholdGreen,
//     required this.thresholdAmber,
//     required this.thresholdRed,
//     required this.iconColor,
//     required this.violationData,
//     required this.identifier,
//     required this.context,
//   });

//   Color _getBackgroundColor() {
//     final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

//     // Special case for 'totalDistance' identifier
//     if (identifier == 'totalDistance') {
//       return const Color.fromARGB(
//         255,
//         17,
//         63,
//         19,
//       ); // Set background color to green
//     }

//     int score = int.tryParse(scoreValue) ?? 0;

//     // Determine the background color based on the score and theme mode
//     if (themeProvider.isDarkMode) {
//       if (score == 0) {
//         return Colors.grey[900]!;
//       } else if (score <= thresholdGreen) {
//         return Colors.green;
//       } else if (score > thresholdGreen && score <= thresholdAmber) {
//         return Colors.orange;
//       } else if (score > thresholdAmber) {
//         return Colors.red;
//       } else {
//         return Colors.grey[900]!;
//       }
//     } else {
//       if (score == 0) {
//         return Colors.grey[300]!;
//       } else if (score <= thresholdGreen) {
//         return Colors.green;
//       } else if (score > thresholdGreen && score <= thresholdAmber) {
//         return Colors.orange;
//       } else if (score > thresholdAmber) {
//         return Colors.red;
//       } else {
//         return Colors
//             .grey[300]!; // Light grey background for scores not meeting other conditions
//       }
//     }
//   }

//   Color _getTextColor() {
//     // Special case for 'totalDistance' identifier
//     if (identifier == 'totalDistance') {
//       return Colors.white; // Set text color to white
//     }

//     final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//     return themeProvider.isDarkMode ? Colors.white : Colors.black;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return InfoCardPopup(
//               title: title,
//               mixId:
//                   Provider.of<DataProvider>(
//                     context,
//                     listen: false,
//                   ).profileData?['mixDriverId'] ??
//                   '',
//               violationKey: identifier,
//               showAllViolations: identifier == 'totalViolations',
//             );
//           },
//         );
//       },
//       child: Card(
//         color: _getBackgroundColor(),
//         elevation: 4,
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Icon(icon, size: 40, color: iconColor),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(fontSize: 13, color: _getTextColor()),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       value,
//                       style: TextStyle(fontSize: 20, color: _getTextColor()),
//                       overflow: TextOverflow.visible,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class InfoCardPopup extends StatefulWidget {
//   final String title;
//   final String mixId;
//   final bool showAllViolations;
//   final String violationKey;

//   const InfoCardPopup({
//     super.key,
//     required this.title,
//     required this.mixId,
//     required this.showAllViolations,
//     required this.violationKey,
//   });

//   @override
//   _InfoCardPopupState createState() => _InfoCardPopupState();
// }

// class _InfoCardPopupState extends State<InfoCardPopup> {
//   Map<String, dynamic>? _result;
//   bool _loading = false;
//   String _selectedPeriod = '';

//   Future<void> _fetchViolationCounts(
//     BuildContext context,
//     String period,
//   ) async {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final String token = dataProvider.token ?? '';
//     final sapId = dataProvider.profileData?['sapId'] ?? '';
//     final now = DateTime.now();
//     late DateTime startDate;
//     late DateTime endDate;

//     if (period == '1_day') {
//       startDate = DateTime(
//         now.year,
//         now.month,
//         now.day,
//       ).subtract(const Duration(days: 1));
//       endDate = DateTime(
//         now.year,
//         now.month,
//         now.day,
//       ).subtract(const Duration(seconds: 1));
//     } else if (period == '7_days') {
//       startDate = DateTime(
//         now.year,
//         now.month,
//         now.day,
//       ).subtract(const Duration(days: 7));
//       endDate = now;
//     } else if (period == '30_days') {
//       startDate = DateTime(
//         now.year,
//         now.month,
//         now.day,
//       ).subtract(const Duration(days: 30));
//       endDate = now;
//     }

//     final String formattedStartDate = DateFormat(
//       'yyyyMMddHHmmss',
//     ).format(startDate);
//     final String formattedEndDate = DateFormat(
//       'yyyyMMddHHmmss',
//     ).format(endDate);

//     setState(() {
//       _loading = true;
//       _selectedPeriod = period;
//     });

//     try {
//       // Fetch violations data locally in the popup
//       final response = await http.get(
//         Uri.parse(
//           'https://staging-812204315267.us-central1.run.app/driver/$sapId/violations?startDate=$formattedStartDate&endDate=$formattedEndDate',
//         ),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//           'app-version': '1.12',
//           'app-name': 'drivers app',
//         },
//       );
//       debugPrint('$formattedStartDate and $formattedEndDate');
//       debugPrint(response.body);
//       debugPrint(token);
//       debugPrint('Token used: "$token"');

//       if (response.statusCode == 200) {
//         setState(() {
//           _loading = false;
//           _result = jsonDecode(response.body)['result'];
//         });
//       } else {
//         throw Exception('Failed to fetch data');
//       }
//     } catch (e) {
//       setState(() {
//         _loading = false;
//         _result = {'error': 'Error fetching data'};
//       });
//     }
//   }

//   Widget _buildContent() {
//     if (_result == null || _result!.isEmpty) {
//       return const Text(
//         'No data available',
//         style: TextStyle(color: Colors.white),
//       );
//     }

//     final data = _result!;
//     if (widget.showAllViolations) {
//       return Column(
//         children: [
//           _buildDataRow(
//             Icons.error,
//             "Total Violations",
//             data['totalViolations'].toString(),
//           ),
//           _buildDataRow(
//             Icons.warning,
//             "Daily Rest",
//             data['dailyRestViolations'].toString(),
//           ),
//           _buildDataRow(
//             Icons.warning,
//             "Weekly Rest",
//             data['weeklyRestViolations'].toString(),
//           ),
//           _buildDataRow(
//             Icons.directions_car,
//             "Continuous Driving",
//             data['continuousDrivingViolations'].toString(),
//           ),
//           _buildDataRow(
//             Icons.speed,
//             "Over Speeding",
//             data['overSpeedingViolations'].toString(),
//           ),
//           _buildDataRow(
//             Icons.do_not_disturb,
//             "Harsh Braking",
//             data['harshBrakingViolations'].toString(),
//           ),
//           _buildDataRow(
//             Icons.sports_motorsports,
//             "Harsh Acceleration",
//             data['harshAccelerationViolations'].toString(),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Score Card',
//             style: TextStyle(color: Colors.green, fontSize: 16),
//           ),
//           _buildDataRow(
//             Icons.directions,
//             "Total Distance (km)",
//             data['scoreCard']?['totalDistance'].toString() ?? '0',
//           ),
//           _buildDataRow(
//             Icons.timer,
//             "Total Duration",
//             data['scoreCard']?['totalDuration'].toString() ?? '0',
//           ),
//           _buildDataRow(
//             Icons.score,
//             "Total Score",
//             data['scoreCard']?['totalScore'].toString() ?? '0',
//           ),
//         ],
//       );
//     } else {
//       switch (widget.violationKey) {
//         case 'overSpeedingViolations':
//           return Column(
//             children: [
//               _buildDataRow(
//                 Icons.speed,
//                 "Over Speeding",
//                 data['overSpeedingViolations'].toString(),
//               ),
//               _buildDataRow(
//                 Icons.score,
//                 "Over Speeding Score",
//                 data['overSpeedingViolationsScore'].toString(),
//               ),
//             ],
//           );
//         case 'dailyRestViolations':
//           return Column(
//             children: [
//               _buildDataRow(
//                 Icons.warning,
//                 "Daily Rest",
//                 data['dailyRestViolations'].toString(),
//               ),
//               _buildDataRow(
//                 Icons.score,
//                 "Daily Rest Score",
//                 data['dailyRestViolationsScore'].toString(),
//               ),
//             ],
//           );
//         case 'weeklyRestViolations':
//           return Column(
//             children: [
//               _buildDataRow(
//                 Icons.warning,
//                 "Weekly Rest",
//                 data['weeklyRestViolations'].toString(),
//               ),
//               _buildDataRow(
//                 Icons.score,
//                 "Weekly Rest Score",
//                 data['weeklyRestViolationsScore'].toString(),
//               ),
//             ],
//           );
//         case 'continuousDrivingViolations':
//           return Column(
//             children: [
//               _buildDataRow(
//                 Icons.directions_car,
//                 "Continuous Driving",
//                 data['continuousDrivingViolations'].toString(),
//               ),
//               _buildDataRow(
//                 Icons.score,
//                 "Continuous Driving Score",
//                 data['continuousDrivingViolationsScore'].toString(),
//               ),
//             ],
//           );
//         case 'harshBrakingViolations':
//           return Column(
//             children: [
//               _buildDataRow(
//                 Icons.do_not_disturb,
//                 "Harsh Braking",
//                 data['harshBrakingViolations'].toString(),
//               ),
//               _buildDataRow(
//                 Icons.score,
//                 "Harsh Braking Score",
//                 data['harshBrakingViolationsScore'].toString(),
//               ),
//             ],
//           );
//         case 'harshAccelerationViolations':
//           return Column(
//             children: [
//               _buildDataRow(
//                 Icons.sports_motorsports,
//                 "Harsh Acceleration",
//                 data['harshAccelerationViolations'].toString(),
//               ),
//               _buildDataRow(
//                 Icons.score,
//                 "Harsh Acceleration Score",
//                 data['harshAccelerationViolationsScore'].toString(),
//               ),
//             ],
//           );
//         case 'totalDistance':
//           return Column(
//             children: [
//               _buildDataRow(
//                 Icons.directions,
//                 "Total Distance",
//                 data['totalDistance'].toString(),
//               ),
//             ],
//           );
//         default:
//           return const Text(
//             'Unknown violation key',
//             style: TextStyle(color: Colors.white),
//           );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       backgroundColor: Colors.grey[900],
//       title: Text(widget.title, style: const TextStyle(color: Colors.white)),
//       content:
//           _loading
//               ? const CircularProgressIndicator()
//               : _result != null
//               ? ConstrainedBox(
//                 constraints: BoxConstraints(
//                   maxHeight:
//                       widget.showAllViolations
//                           ? MediaQuery.of(context).size.height * 0.6
//                           : MediaQuery.of(context).size.height * 0.3,
//                 ),
//                 child: SingleChildScrollView(child: _buildContent()),
//               )
//               : Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () {
//                       _fetchViolationCounts(context, '1_day');
//                     },
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(horizontal: 24),
//                     ),
//                     child: const Text('1 Day'),
//                   ),
//                   const SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: () {
//                       _fetchViolationCounts(context, '7_days');
//                     },
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(horizontal: 24),
//                     ),
//                     child: const Text('7 Days'),
//                   ),
//                   const SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: () {
//                       _fetchViolationCounts(context, '30_days');
//                     },
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(horizontal: 24),
//                     ),
//                     child: const Text('30 Days'),
//                   ),
//                 ],
//               ),
//       actions: <Widget>[
//         ElevatedButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: const Text('Close'),
//         ),
//       ],
//     );
//   }

//   Widget _buildDataRow(IconData icon, String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             Icon(icon, color: Colors.white),
//             const SizedBox(width: 8),
//             Text(label, style: const TextStyle(color: Colors.white)),
//           ],
//         ),
//         Text(value, style: const TextStyle(color: Colors.white)),
//       ],
//     );
//   }
// }

// class ProfileDetail extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String value;
//   final Color iconColor;

//   const ProfileDetail({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 1.0),
//       child: Row(
//         children: [
//           Icon(icon, color: iconColor),
//           const SizedBox(width: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: iconColor,
//             ),
//           ),
//           const Spacer(),
//           Text(value, style: TextStyle(fontSize: 16, color: iconColor)),
//         ],
//       ),
//     );
//   }
// }

// Widget _buildDetailCard(
//   String title,
//   String value,
//   bool isDarkMode,
//   AnimationController blinkController, [
//   Color? textColor,
// ]) {
//   bool isExpired = value.contains('expired'); // Check if expired

//   return Card(
//     color: isDarkMode ? Colors.black : Colors.grey[300],
//     elevation: 5,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//     child: Padding(
//       padding: const EdgeInsets.only(top: 5, left: 20.0, right: 0, bottom: 5),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Text(
//               title,
//               style: TextStyle(
//                 color: textColor ?? (isDarkMode ? Colors.white : Colors.black),
//                 fontSize: 13,
//               ),
//             ),
//           ),
//           const SizedBox(width: 10), // Adjust spacing between title and value
//           Expanded(
//             child:
//                 isExpired
//                     ? AnimatedBuilder(
//                       animation: blinkController,
//                       builder: (context, child) {
//                         return Opacity(
//                           opacity: blinkController.value,
//                           child: Text(
//                             value,
//                             textAlign: TextAlign.right,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color:
//                                   textColor ??
//                                   (isDarkMode ? Colors.white : Colors.black),
//                             ),
//                           ),
//                         );
//                       },
//                     )
//                     : Text(
//                       value,
//                       textAlign: TextAlign.right,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color:
//                             textColor ??
//                             (isDarkMode ? Colors.white : Colors.black),
//                       ),
//                     ),
//           ),
//         ],
//       ),
//     ),
//   );
// }


// ignore_for_file: unused_field, prefer_final_fields

import 'dart:async';
import 'dart:convert';
import 'package:driversapp/hos_display.dart';
import 'package:driversapp/licence_date_provider.dart';
import 'package:driversapp/notification.dart';
import 'package:driversapp/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_provider.dart';
import 'theme_provider.dart';
import 'widgets/bottom_navigation.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> with TickerProviderStateMixin {
  bool _isSendingLocation = false;
  Timer? _violationTimer;
  Timer? _notificationTimer;
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  final FlutterTts _flutterTts = FlutterTts();
  String? _lastSpokenViolationTitle;
  bool _isSpeaking = false;
  Timer? _debounceTimer;
  late AnimationController _blinkController;
  Timer? _locationTimer;
  bool _isPopupVisible = false;
  double appVersion = 1.12;
  Timer? _versionCheckTimer;
  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = false;

  // Using ValueNotifier to track changes in violation data
  Map<String, ValueNotifier<int>> _violationData = {
    'totalViolations': ValueNotifier(0),
    'dailyRestViolations': ValueNotifier(0),
    'weeklyRestViolations': ValueNotifier(0),
    'continuousDrivingViolations': ValueNotifier(0),
    'overSpeedingViolations': ValueNotifier(0),
    'harshBrakingViolations': ValueNotifier(0),
    'harshAccelerationViolations': ValueNotifier(0),
  };

  Map<String, dynamic> _scoreCardData = {};
  bool _isApiCallInProgress = false;

  @override
  void initState() {
    super.initState();

    // Load cached data and initialize
    _loadCachedData();

    // Initialize other components
    _startLocationUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
      _observeDriverStatus(context);
      _startViolationTimer();
      _fetchAndShowNotification(context);
    });

    // Add listeners to each ValueNotifier
    _violationData.forEach((key, notifier) {
      notifier.addListener(() => _handleViolationChange(key, notifier.value));
    });

    // Initialize the blinking animation controller
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _loadCachedData() async {
    setState(() {
      _isLoading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mixId = dataProvider.profileData?['mixDriverId'] ?? '';
    final prefs = await SharedPreferences.getInstance();

    // Load cached violation data
    try {
      final cachedViolations = prefs.getString('violations_$mixId');
      if (cachedViolations != null) {
        final violations = jsonDecode(cachedViolations);
        _updateViolationData(violations);
      }
    } catch (e) {
      print('Error loading cached violations: $e');
    }

    // Load cached HOS data
    try {
      final cachedHos = prefs.getString('hos_$mixId');
      if (cachedHos != null) {
        dataProvider.setHosData(jsonDecode(cachedHos));
      }
    } catch (e) {
      print('Error loading cached HOS: $e');
    }

    // Load cached version data
    try {
      final cachedVersion = prefs.getString('version_$mixId');
      if (cachedVersion != null) {
        final versionData = jsonDecode(cachedVersion);
        final latestVersion = double.tryParse(versionData['version'].toString()) ?? 0.0;
        if (appVersion != latestVersion && !_isPopupVisible) {
          await _showDownloadPopup(versionData['link'] ?? '');
        }
      }
    } catch (e) {
      print('Error loading cached version: $e');
    }

    // Fetch fresh data if cache is empty or on refresh
    await _refreshData();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchViolations(context),
      _fetchHosData(context),
      _fetchLatestVersion(),
    ]);
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin!.initialize(initializationSettings);
  }

  void _showNotification(String message) async {
    if (_flutterLocalNotificationsPlugin == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin!.show(
      0,
      'Driver App',
      message,
      platformChannelSpecifics,
      payload: 'item x',
    );

    // Notify the NotificationProvider
    Provider.of<NotificationProvider>(context, listen: false)
        .setHasNewNotification(true);

    // Ensure speaking happens after the notification
    _speak(message);
  }

  Future<void> _speak(String message) async {
    if (_isSpeaking) return;

    _isSpeaking = true;
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.5);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(message);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });
    _flutterTts.setErrorHandler((message) {
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _flutterTts.stop();
    _debounceTimer?.cancel();
    _locationTimer?.cancel();
    _violationTimer?.cancel();
    _versionCheckTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startViolationTimer() {
    if (_violationTimer != null && _violationTimer!.isActive) return;

    _violationTimer = Timer.periodic(const Duration(seconds: 300), (timer) {
      _fetchViolations(context);
    });
  }

  Future<void> _fetchHosData(BuildContext context) async {
    if (_isApiCallInProgress) return;

    _isApiCallInProgress = true;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    try {
      final mixId = dataProvider.profileData?['mixDriverId'] ?? '';
      final token = dataProvider.token ?? '';
      await dataProvider.fetchHosData(mixId, token);
      final hosData = dataProvider.hosData;

      // Cache HOS data
      if (hosData != null) {
        await prefs.setString('hos_$mixId', jsonEncode(hosData));
      }

      if (hosData != null &&
          dataProvider.currentStatusDescription == 'Driving') {
        final initialDuration = _parseDuration(
          dataProvider.availableDrivingBeforeBreak as String,
        );
        _startTimer(initialDuration);
      }
    } catch (e) {
      print('Error fetching HOS data: $e');
    } finally {
      _isApiCallInProgress = false;
    }
  }

  void _startLocationUpdates() {
    print('Starting location updates...');
    _locationTimer?.cancel();
    _sendingLocation(context);
    _locationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      print('Triggering location update at ${DateTime.now()}');
      _sendingLocation(context);
    });
  }

  Future<void> _sendingLocation(BuildContext context) async {
    print('Sending location at: ${DateTime.now()}');
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final token = dataProvider.token ?? '';
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint('Location service denied');
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        debugPrint('Location permission denied');
        return;
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      debugPrint('Location permission denied forever');
      return;
    }

    LocationData locationData = await location.getLocation();

    final String apiUrl =
        'https://staging-812204315267.us-central1.run.app/driver/location/update';
    final Map<String, dynamic> payload = {
      "longitude": locationData.longitude,
      "latitude": locationData.latitude,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('Location sent successfully.');
      } else {
        debugPrint('Failed to send location: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending location: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Duration _parseDuration(String duration) {
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

  void _startTimer(Duration initialDuration) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    if (dataProvider.currentStatusDescription == 'Driving' &&
        !dataProvider.isTimerRunning) {
      dataProvider.updateRemainingTime(initialDuration);
      dataProvider.startTimer();

      _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (dataProvider.currentStatusDescription != 'Driving') {
          timer.cancel();
          dataProvider.stopTimer();
          dataProvider.updateRemainingTime(
            _parseDuration(dataProvider.availableDrivingBeforeBreak as String),
          );
        } else {
          final newRemainingTime =
              dataProvider.remainingTime - const Duration(seconds: 1);
          dataProvider.updateRemainingTime(newRemainingTime);
        }
      });
    }
  }

  void _stopTimer() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.stopTimer();
    _notificationTimer?.cancel();
  }

  void _observeDriverStatus(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.addListener(() {
      if (dataProvider.currentStatusDescription == 'Driving') {
        final initialDuration = _parseDuration(
          dataProvider.availableDrivingBeforeBreak as String,
        );
        _startTimer(initialDuration);
      } else if (dataProvider.currentStatusDescription == 'Not Driving') {
        _stopTimer();
      }
    });
  }

  Future<void> _fetchViolations(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mixId = dataProvider.profileData?['mixDriverId'] ?? '';
    final prefs = await SharedPreferences.getInstance();

    try {
      await dataProvider.fetchViolations(mixId);
      final violations = dataProvider.violationData;

      // Cache violation data
      if (violations != null) {
        await prefs.setString('violations_$mixId', jsonEncode(violations));
        _updateViolationData(violations);
      }
    } catch (e) {
      print('Error fetching violations: $e');
    }
  }

  void _updateViolationData(Map<String, dynamic>? violations) {
    if (violations == null) return;

    _updateViolation('totalViolations', violations['totalViolations'] ?? 0);
    _updateViolation('dailyRestViolations', violations['dailyRestViolations'] ?? 0);
    _updateViolation('weeklyRestViolations', violations['weeklyRestViolations'] ?? 0);
    _updateViolation('continuousDrivingViolations', violations['continuousDrivingViolations'] ?? 0);
    _updateViolation('overSpeedingViolations', violations['overSpeedingViolations'] ?? 0);
    _updateViolation('harshBrakingViolations', violations['harshBrakingViolations'] ?? 0);
    _updateViolation('harshAccelerationViolations', violations['harshAccelerationViolations'] ?? 0);

    final scoreCard = violations['scoreCard'];
    if (scoreCard != null) {
      _scoreCardData['totalDistance'] = scoreCard['totalDistance']?.toString() ?? '0';
      _scoreCardData['totalDuration'] = scoreCard['totalDuration']?.toString() ?? '0';
      _scoreCardData['totalTrips'] = scoreCard['totalTrips']?.toString() ?? '0';
      _scoreCardData['totalScore'] = scoreCard['totalScore']?.toString() ?? '0';
      _scoreCardData['safetyCategory'] = scoreCard['safetyCategory']?.toString() ?? 'UNKNOWN';
    }
  }

  void _updateViolation(String key, int newValue) {
    if (_violationData[key]?.value != newValue) {
      _violationData[key]?.value = newValue;
    }
  }

  void _handleViolationChange(String key, int newValue) {
    final currentTitle = _getViolationTitle(key);
    final message = '$currentTitle increased to $newValue. Drive carefully.';

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_lastSpokenViolationTitle != currentTitle && !_isSpeaking) {
        _lastSpokenViolationTitle = currentTitle;
        _showNotification(message);
      }
    });
  }

  String _getViolationTitle(String key) {
    switch (key) {
      case 'totalViolations':
        return 'Total Violations';
      case 'dailyRestViolations':
        return 'Daily Rest Violations';
      case 'weeklyRestViolations':
        return 'Weekly Rest Violations';
      case 'continuousDrivingViolations':
        return 'Continuous Driving Violations';
      case 'overSpeedingViolations':
        return 'Over Speeding Violations';
      case 'harshBrakingViolations':
        return 'Harsh Braking Violations';
      case 'harshAccelerationViolations':
        return 'Harsh Acceleration Violations';
      default:
        return 'Violation';
    }
  }

  Future<void> _sendLocation(BuildContext context) async {
    if (_isApiCallInProgress) return;

    _isApiCallInProgress = true;
    setState(() {
      _isSendingLocation = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final token = dataProvider.token ?? '';
    final sapId = dataProvider.profileData?['sapId'] ?? '';

    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isSendingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them to continue.'),
          ),
        );
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isSendingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied. Please allow location access to continue.'),
          ),
        );
        return;
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      setState(() {
        _isSendingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied. Please enable them from settings.'),
        ),
      );
      return;
    }

    LocationData locationData;
    try {
      locationData = await location.getLocation();
    } catch (e) {
      setState(() {
        _isSendingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location. Please try again.'),
        ),
      );
      return;
    }

    const String apiUrl = 'https://staging-812204315267.us-central1.run.app/support/submit';
    final Map<String, dynamic> payload = {
      "supportType": "PANIC",
      "description": "",
      "driverSapId": sapId,
      "longitude": "${locationData.longitude}",
      "latitude": "${locationData.latitude}",
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while sending message. Please try again.')),
      );
    } finally {
      setState(() {
        _isSendingLocation = false;
      });
      _isApiCallInProgress = false;
    }
  }

  Color getSafetyCategoryColor(String category) {
    switch (category) {
      case 'GREEN':
        return Colors.green;
      case 'AMBER':
        return Colors.amber;
      case 'RED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchLatestVersion() async {
    debugPrint("Checking for the latest version...");
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String token = dataProvider.token ?? '';
    final prefs = await SharedPreferences.getInstance();

    const String url = "https://staging-812204315267.us-central1.run.app/driver-app/latest";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey("result") && data["result"].containsKey("version")) {
          // Cache version data
          await prefs.setString('version_$dataProvider.profileData[mixDriverId]', jsonEncode(data['result']));
          final latestVersion = double.tryParse(data["result"]["version"].toString()) ?? 0.0;
          if (appVersion != latestVersion && !_isPopupVisible) {
            await _showDownloadPopup(data["result"]["link"] ?? '');
          }
        }
      } else {
        debugPrint("Failed to fetch version. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching version: $e");
    }
  }

  Future<void> _showDownloadPopup(String downloadUrl) async {
    if (!mounted) return;

    setState(() {
      _isPopupVisible = true;
    });

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Available"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("A new version of the app is available. Please download the update."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final Uri url = Uri.parse(downloadUrl);
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    throw 'Could not launch $url';
                  }
                },
                child: const Text("Download"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );

    setState(() {
      _isPopupVisible = false;
    });
  }

  Future<void> _fetchAndShowNotification(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String token = dataProvider.token ?? '';

    const String url = "https://staging-812204315267.us-central1.run.app/notification/all";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["isSuccessful"] == true) {
          List<dynamic> notifications = data["result"];
          var unreadNotification = notifications.firstWhere(
            (notif) => notif["isRead"] == false,
            orElse: () => null,
          );

          if (unreadNotification != null) {
            _showNotificationPopup(context, unreadNotification["title"], unreadNotification["message"]);
          }
        }
      } else {
        debugPrint("Failed to fetch notifications. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  Future<void> _showNotificationPopup(BuildContext context, String title, String message) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _markNotificationsAsRead();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markNotificationsAsRead() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String token = dataProvider.token ?? '';

    const String url = "https://staging-812204315267.us-central1.run.app/notification/all/mark-as-read";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Notifications marked as read successfully.");
      } else {
        debugPrint("Failed to mark notifications as read. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  void _startVersionCheck() {
    _versionCheckTimer?.cancel();
    _versionCheckTimer = Timer.periodic(const Duration(hours: 12), (timer) {
      debugPrint("Periodic version check triggered...");
      _fetchLatestVersion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final driverName = dataProvider.profileData?['driverName'] ?? 'User';
    final safetyCategory = _scoreCardData['safetyCategory'] ?? 'UNKNOWN';
    final safetyCategoryColor = getSafetyCategoryColor(safetyCategory);
    final hasNewNotification = Provider.of<NotificationProvider>(context).hasNewNotification;

    final licenseExpiryDateStr = dataProvider.profileData?['licenseExpiryDate'] ?? 'N/A';
    final ddtExpiryDateStr = dataProvider.profileData?['ddtExpiryDate'] ?? 'N/A';
    final isDarkMode = themeProvider.isDarkMode;

    DateTime? licenseExpiryDate = LicenseDateProvider.parseDate(licenseExpiryDateStr);
    DateTime? ddtExpiryDate = LicenseDateProvider.parseDate(ddtExpiryDateStr);

    int licenseDaysLeft = LicenseDateProvider.calculateDaysLeft(licenseExpiryDate);
    int ddtDaysLeft = LicenseDateProvider.calculateDaysLeft(ddtExpiryDate);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 36, 98, 38),
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
            child: Row(
              children: [
                Flexible(
                  child: FloatingActionButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text(
                                  languageProvider.translate('Panic Button'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.grey[800],
                                content: Text(
                                  languageProvider.translate('Are you sure you want to trigger the panic action?'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.grey,
                                    ),
                                    child: Text(languageProvider.translate('No')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isSendingLocation = true;
                                      });
                                      await _sendLocation(context);
                                      setState(() {
                                        _isSendingLocation = false;
                                      });
                                      Navigator.of(context).pop();
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.black,
                                            content: SizedBox(
                                              height: 100,
                                              child: Center(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      languageProvider.translate('Message sent'),
                                                      style: const TextStyle(color: Colors.white, fontSize: 18),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    SizedBox(
                                                      width: 80,
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                        },
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                                                        child: Text(
                                                          languageProvider.translate('Close'),
                                                          style: const TextStyle(fontSize: 9, color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[900]),
                                    child: _isSendingLocation
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : Text(
                                            languageProvider.translate('Yes'),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    backgroundColor: Colors.red[900],
                    mini: true,
                    child: const Icon(Icons.warning),
                  ),
                ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text("Drivers App", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              onPressed: () {
                Provider.of<NotificationProvider>(context, listen: false).setHasNewNotification(false);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
              },
              icon: Icon(
                Icons.notifications,
                color: hasNewNotification ? Colors.white : Colors.red,
              ),
            ),
            IconButton(
              onPressed: dataProvider.currentStatusDescription == 'Driving'
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              languageProvider.translate('Want to Talk?'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.grey[800],
                            content: ElevatedButton(
                              onPressed: () {
                                const whatsappUrl = 'https://api.whatsapp.com/send?phone=2349062964972';
                                launchUrl(Uri.parse(whatsappUrl));
                              },
                              style: TextButton.styleFrom(backgroundColor: const Color.fromARGB(255, 22, 144, 49)),
                              child: Text(
                                languageProvider.translate('Talk to Customer Service'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            actions: <Widget>[
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                                child: Text(
                                  languageProvider.translate('Close'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
              icon: const Icon(Icons.wechat, color: Colors.white),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.green,
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.green))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            Text(
                              '${languageProvider.translate('Hi')} $driverName',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        ProfileDetail(
                          icon: Icons.score_outlined,
                          title: languageProvider.translate('Daily Score Card'),
                          value: _scoreCardData['safetyCategory'] ?? 'UNKNOWN',
                          iconColor: safetyCategoryColor,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildDetailCard(
                                  'License Status',
                                  licenseDaysLeft < 0 ? 'License has expired' : '$licenseDaysLeft days left',
                                  isDarkMode,
                                  _blinkController,
                                  LicenseDateProvider.getDaysLeftColor(licenseDaysLeft, isDarkMode),
                                ),
                                _buildDetailCard(
                                  'DDT Status',
                                  ddtDaysLeft < 0 ? 'DDT has expired' : '$ddtDaysLeft days left',
                                  isDarkMode,
                                  _blinkController,
                                  LicenseDateProvider.getDaysLeftColor(ddtDaysLeft, isDarkMode),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _scoreCardData['totalScore'] ?? '0',
                          style: TextStyle(fontSize: 20, color: safetyCategoryColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          languageProvider.translate(dataProvider.currentStatusDescription),
                          style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: CircularIndicator(
                            duration: dataProvider.remainingTime,
                            onUpdate: (duration) {
                              dataProvider.updateRemainingTime(duration);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            Text(
                              languageProvider.translate('Violation Count'),
                              style: const TextStyle(color: Colors.green, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: _violationData['dailyRestViolations']!,
                                    builder: (context, value, child) {
                                      return InfoCard(
                                        identifier: 'dailyRestViolations',
                                        title: languageProvider.translate('Daily Rest'),
                                        value: value.toString(),
                                        scoreValue: (dataProvider.violationData?['dailyRestViolationsScore'] ?? '0').toString(),
                                        icon: Icons.warning,
                                        thresholdGreen: 1,
                                        thresholdAmber: 21,
                                        thresholdRed: 51,
                                        iconColor: const Color.fromARGB(255, 255, 184, 90),
                                        context: context,
                                        violationData: {},
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: _violationData['weeklyRestViolations']!,
                                    builder: (context, value, child) {
                                      return InfoCard(
                                        identifier: 'weeklyRestViolations',
                                        title: languageProvider.translate('Weekly Rest'),
                                        value: value.toString(),
                                        scoreValue: (dataProvider.violationData?['weeklyRestViolationsScore'] ?? '0').toString(),
                                        icon: Icons.warning,
                                        thresholdGreen: 1,
                                        thresholdAmber: 21,
                                        thresholdRed: 51,
                                        iconColor: const Color.fromARGB(255, 255, 184, 90),
                                        context: context,
                                        violationData: {},
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _violationData['continuousDrivingViolations']!,
                                builder: (context, value, child) {
                                  return InfoCard(
                                    identifier: 'continuousDrivingViolations',
                                    title: languageProvider.translate('Continuous Driving'),
                                    value: value.toString(),
                                    scoreValue: (dataProvider.violationData?['continuousDrivingViolationsScore'] ?? '0').toString(),
                                    icon: Icons.directions_car,
                                    thresholdGreen: 1,
                                    thresholdAmber: 21,
                                    thresholdRed: 51,
                                    iconColor: Colors.purple,
                                    context: context,
                                    violationData: {},
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _violationData['harshAccelerationViolations']!,
                                builder: (context, value, child) {
                                  return InfoCard(
                                    identifier: 'harshAccelerationViolations',
                                    title: languageProvider.translate('Harsh Acceleration'),
                                    value: value.toString(),
                                    scoreValue: (dataProvider.violationData?['harshAccelerationViolationsScore'] ?? '0').toString(),
                                    icon: Icons.sports_motorsports,
                                    thresholdGreen: 1,
                                    thresholdAmber: 21,
                                    thresholdRed: 51,
                                    iconColor: const Color.fromARGB(255, 13, 58, 14),
                                    context: context,
                                    violationData: {},
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _violationData['overSpeedingViolations']!,
                                builder: (context, value, child) {
                                  return InfoCard(
                                    identifier: 'overSpeedingViolations',
                                    title: languageProvider.translate('Over Speeding'),
                                    value: value.toString(),
                                    scoreValue: (dataProvider.violationData?['overSpeedingViolationsScore'] ?? '0').toString(),
                                    icon: Icons.speed,
                                    thresholdGreen: 1,
                                    thresholdAmber: 21,
                                    thresholdRed: 51,
                                    iconColor: const Color.fromARGB(255, 81, 28, 25),
                                    context: context,
                                    violationData: {},
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _violationData['harshBrakingViolations']!,
                                builder: (context, value, child) {
                                  return InfoCard(
                                    identifier: 'harshBrakingViolations',
                                    title: languageProvider.translate('Harsh Braking'),
                                    value: value.toString(),
                                    scoreValue: (dataProvider.violationData?['harshBrakingViolationsScore'] ?? '0').toString(),
                                    icon: Icons.do_not_disturb,
                                    thresholdGreen: 1,
                                    thresholdAmber: 21,
                                    thresholdRed: 51,
                                    iconColor: const Color.fromARGB(255, 104, 90, 255),
                                    context: context,
                                    violationData: {},
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _violationData['totalViolations']!,
                          builder: (context, value, child) {
                            return InfoCard(
                              identifier: 'totalViolations',
                              title: languageProvider.translate('Total Violations'),
                              value: value.toString(),
                              scoreValue: (dataProvider.violationData?[''] ?? '0').toString(),
                              icon: Icons.error,
                              thresholdGreen: 1,
                              thresholdAmber: 21,
                              thresholdRed: 51,
                              iconColor: const Color.fromARGB(255, 81, 28, 25),
                              context: context,
                              violationData: {},
                            );
                          },
                        ),
                        InfoCard(
                          identifier: 'totalDistance',
                          title: languageProvider.translate('Total Distance (km)'),
                          value: (_scoreCardData['totalDistance'] ?? '0').toString(),
                          scoreValue: '0',
                          icon: Icons.directions,
                          thresholdGreen: 1,
                          thresholdAmber: 21,
                          thresholdRed: 51,
                          iconColor: Colors.green,
                          context: context,
                          violationData: {},
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Last Update:\n${dataProvider.violationData?['lastUpdated'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProgressPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: Text(
                                languageProvider.translate('Check other HOS Timer'),
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      ),
    );
  }
}

class CircularIndicator extends StatefulWidget {
  final Duration duration;
  final void Function(Duration) onUpdate;

  const CircularIndicator({
    super.key,
    required this.duration,
    required this.onUpdate,
  });

  @override
  _CircularIndicatorState createState() => _CircularIndicatorState();
}

class _CircularIndicatorState extends State<CircularIndicator> {
  Timer? _timer;
  late Duration _duration;
  Map<int, bool> _notifiedIntervals = {};

  @override
  void initState() {
    super.initState();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    if (dataProvider.currentStatusDescription == 'Driving') {
      _duration = widget.duration;
      _startTimer();
    } else {
      _duration = dataProvider.availableDrivingBeforeBreak;
    }
  }

  void _startTimer() {
    _notifiedIntervals.clear();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration.inSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _duration = _duration - const Duration(seconds: 1);
          widget.onUpdate(_duration);
          _handleVoiceNotifications(_duration);
        });
      }
    });
  }

  void _handleVoiceNotifications(Duration remainingTime) {
    final int minutes = remainingTime.inMinutes;

    if (_notifiedIntervals[minutes] == true) {
      return;
    }

    if ([59, 30, 15, 10, 5, 3, 2, 1].contains(minutes)) {
      final int hours = remainingTime.inHours;
      final message = 'You have ${hours > 0 ? '$hours hours and ' : ''}$minutes minutes left to drive';

      _showNotification(message);
      _notifiedIntervals[minutes] = true;
    }
  }

  Future<void> _showNotification(String message) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final flutterTts = FlutterTts();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Driver App',
      message,
      platformChannelSpecifics,
      payload: 'item x',
    );

    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(2.0);
    await flutterTts.speak(message);
  }

  Color _getColor() {
    if (_duration.inHours >= 2) {
      return Colors.green;
    } else if (_duration.inHours >= 1) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: _duration.inSeconds / (4 * 3600),
            strokeWidth: 12,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
          ),
          Center(
            child: Text(
              '${_duration.inHours.toString().padLeft(2, '0')}:${(_duration.inMinutes % 60).toString().padLeft(2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 22, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String scoreValue;
  final IconData icon;
  final int thresholdGreen;
  final int thresholdAmber;
  final int thresholdRed;
  final Color iconColor;
  final Map<String, dynamic> violationData;
  final String identifier;
  final BuildContext context;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.scoreValue,
    required this.icon,
    required this.thresholdGreen,
    required this.thresholdAmber,
    required this.thresholdRed,
    required this.iconColor,
    required this.violationData,
    required this.identifier,
    required this.context,
  });

  Color _getBackgroundColor() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (identifier == 'totalDistance') {
      return const Color.fromARGB(255, 17, 63, 19);
    }

    int score = int.tryParse(scoreValue) ?? 0;

    if (themeProvider.isDarkMode) {
      if (score == 0) {
        return Colors.grey[900]!;
      } else if (score <= thresholdGreen) {
        return Colors.green;
      } else if (score > thresholdGreen && score <= thresholdAmber) {
        return Colors.orange;
      } else if (score > thresholdAmber) {
        return Colors.red;
      } else {
        return Colors.grey[900]!;
      }
    } else {
      if (score == 0) {
        return Colors.grey[300]!;
      } else if (score <= thresholdGreen) {
        return Colors.green;
      } else if (score > thresholdGreen && score <= thresholdAmber) {
        return Colors.orange;
      } else if (score > thresholdAmber) {
        return Colors.red;
      } else {
        return Colors.grey[300]!;
      }
    }
  }

  Color _getTextColor() {
    if (identifier == 'totalDistance') {
      return Colors.white;
    }
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return InfoCardPopup(
              title: title,
              mixId: Provider.of<DataProvider>(context, listen: false).profileData?['mixDriverId'] ?? '',
              violationKey: identifier,
              showAllViolations: identifier == 'totalViolations',
            );
          },
        );
      },
      child: Card(
        color: _getBackgroundColor(),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 13, color: _getTextColor()),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: TextStyle(fontSize: 20, color: _getTextColor()),
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCardPopup extends StatefulWidget {
  final String title;
  final String mixId;
  final bool showAllViolations;
  final String violationKey;

  const InfoCardPopup({
    super.key,
    required this.title,
    required this.mixId,
    required this.showAllViolations,
    required this.violationKey,
  });

  @override
  _InfoCardPopupState createState() => _InfoCardPopupState();
}

class _InfoCardPopupState extends State<InfoCardPopup> {
  Map<String, dynamic>? _result;
  bool _loading = false;
  String _selectedPeriod = '';

  Future<void> _fetchViolationCounts(BuildContext context, String period) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String token = dataProvider.token ?? '';
    final sapId = dataProvider.profileData?['sapId'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    if (period == '1_day') {
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      endDate = DateTime(now.year, now.month, now.day).subtract(const Duration(seconds: 1));
    } else if (period == '7_days') {
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      endDate = now;
    } else if (period == '30_days') {
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
      endDate = now;
    }

    final String formattedStartDate = DateFormat('yyyyMMddHHmmss').format(startDate);
    final String formattedEndDate = DateFormat('yyyyMMddHHmmss').format(endDate);
    final cacheKey = 'violations_popup_${widget.mixId}_$period';

    // Check cache first
    try {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        setState(() {
          _loading = false;
          _result = jsonDecode(cachedData);
          _selectedPeriod = period;
        });
        return;
      }
    } catch (e) {
      print('Error loading cached popup violations: $e');
    }

    setState(() {
      _loading = true;
      _selectedPeriod = period;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/driver/$sapId/violations?startDate=$formattedStartDate&endDate=$formattedEndDate',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)['result'];
        await prefs.setString(cacheKey, jsonEncode(result));
        setState(() {
          _loading = false;
          _result = result;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _result = {'error': 'Error fetching data'};
      });
    }
  }

  Widget _buildContent() {
    if (_result == null || _result!.isEmpty) {
      return const Text('No data available', style: TextStyle(color: Colors.white));
    }

    final data = _result!;
    if (widget.showAllViolations) {
      return Column(
        children: [
          _buildDataRow(Icons.error, "Total Violations", data['totalViolations'].toString()),
          _buildDataRow(Icons.warning, "Daily Rest", data['dailyRestViolations'].toString()),
          _buildDataRow(Icons.warning, "Weekly Rest", data['weeklyRestViolations'].toString()),
          _buildDataRow(Icons.directions_car, "Continuous Driving", data['continuousDrivingViolations'].toString()),
          _buildDataRow(Icons.speed, "Over Speeding", data['overSpeedingViolations'].toString()),
          _buildDataRow(Icons.do_not_disturb, "Harsh Braking", data['harshBrakingViolations'].toString()),
          _buildDataRow(Icons.sports_motorsports, "Harsh Acceleration", data['harshAccelerationViolations'].toString()),
          const SizedBox(height: 16),
          const Text('Score Card', style: TextStyle(color: Colors.green, fontSize: 16)),
          _buildDataRow(Icons.directions, "Total Distance (km)", data['scoreCard']?['totalDistance'].toString() ?? '0'),
          _buildDataRow(Icons.timer, "Total Duration", data['scoreCard']?['totalDuration'].toString() ?? '0'),
          _buildDataRow(Icons.score, "Total Score", data['scoreCard']?['totalScore'].toString() ?? '0'),
        ],
      );
    } else {
      switch (widget.violationKey) {
        case 'overSpeedingViolations':
          return Column(
            children: [
              _buildDataRow(Icons.speed, "Over Speeding", data['overSpeedingViolations'].toString()),
              _buildDataRow(Icons.score, "Over Speeding Score", data['overSpeedingViolationsScore'].toString()),
            ],
          );
        case 'dailyRestViolations':
          return Column(
            children: [
              _buildDataRow(Icons.warning, "Daily Rest", data['dailyRestViolations'].toString()),
              _buildDataRow(Icons.score, "Daily Rest Score", data['dailyRestViolationsScore'].toString()),
            ],
          );
        case 'weeklyRestViolations':
          return Column(
            children: [
              _buildDataRow(Icons.warning, "Weekly Rest", data['weeklyRestViolations'].toString()),
              _buildDataRow(Icons.score, "Weekly Rest Score", data['weeklyRestViolationsScore'].toString()),
            ],
          );
        case 'continuousDrivingViolations':
          return Column(
            children: [
              _buildDataRow(Icons.directions_car, "Continuous Driving", data['continuousDrivingViolations'].toString()),
              _buildDataRow(Icons.score, "Continuous Driving Score", data['continuousDrivingViolationsScore'].toString()),
            ],
          );
        case 'harshBrakingViolations':
          return Column(
            children: [
              _buildDataRow(Icons.do_not_disturb, "Harsh Braking", data['harshBrakingViolations'].toString()),
              _buildDataRow(Icons.score, "Harsh Braking Score", data['harshBrakingViolationsScore'].toString()),
            ],
          );
        case 'harshAccelerationViolations':
          return Column(
            children: [
              _buildDataRow(Icons.sports_motorsports, "Harsh Acceleration", data['harshAccelerationViolations'].toString()),
              _buildDataRow(Icons.score, "Harsh Acceleration Score", data['harshAccelerationViolationsScore'].toString()),
            ],
          );
        case 'totalDistance':
          return Column(
            children: [
              _buildDataRow(Icons.directions, "Total Distance", data['totalDistance'].toString()),
            ],
          );
        default:
          return const Text('Unknown violation key', style: TextStyle(color: Colors.white));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: _loading
          ? const CircularProgressIndicator()
          : _result != null
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: widget.showAllViolations ? MediaQuery.of(context).size.height * 0.6 : MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(child: _buildContent()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _fetchViolationCounts(context, '1_day');
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
                      child: const Text('1 Day'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _fetchViolationCounts(context, '7_days');
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
                      child: const Text('7 Days'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _fetchViolationCounts(context, '30_days');
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
                      child: const Text('30 Days'),
                    ),
                  ],
                ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const ProfileDetail({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 16, color: iconColor)),
        ],
      ),
    );
  }
}

Widget _buildDetailCard(
  String title,
  String value,
  bool isDarkMode,
  AnimationController blinkController, [
  Color? textColor,
]) {
  bool isExpired = value.contains('expired');

  return Card(
    color: isDarkMode ? Colors.black : Colors.grey[300],
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.only(top: 5, left: 20.0, right: 0, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor ?? (isDarkMode ? Colors.white : Colors.black),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isExpired
                ? AnimatedBuilder(
                    animation: blinkController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: blinkController.value,
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor ?? (isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                      );
                    },
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor ?? (isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}