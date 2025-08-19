// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme_provider.dart';
import 'data_provider.dart';
import 'timer_service.dart';
import 'welcome_screen2.dart';
import 'auth_service.dart';
import 'notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (Persistent Storage)
  try {
    await Hive.initFlutter();
    await Hive.openBox('authBox');
  } catch (e) {
    print("⚠️ Hive initialization error: $e");
  }

  // Start background service
  await initializeBackgroundService();

  // Initialize OneSignal BEFORE runApp()
  await initializeOneSignal();

  final dataProvider = DataProvider();
  await dataProvider.loadTokenAndMixId();

  runApp(MyApp(dataProvider: dataProvider));
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundStart,
      autoStart: true, // Automatically starts service
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onBackgroundStart,
      onBackground: onBackgroundStart,
    ),
  );

  service.startService();
}

// Background service task
// Future<bool> onBackgroundStart(ServiceInstance service) async {
//   if (service is AndroidServiceInstance) {
//     service.setAsForegroundService(); // Keep service running
//   }

//   while (true) {
//     print("🔄 Running background task...");

//     // Fetch OneSignal Player ID periodically
//     String? playerId = await OneSignal.User.pushSubscription.id;
//     print("📲 OneSignal Player ID in background: $playerId");

//     // Example: Revalidate session
//     AuthService authService = AuthService();
//     bool isSessionValid = await authService.isSessionValid();
//     print("🔑 Session Valid: $isSessionValid");

//     await Future.delayed(const Duration(minutes: 15)); // Run every 15 minutes
//   }
// }

Future<bool> onBackgroundStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    // 🔒 Keep service alive with a visible foreground notification
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Driver App Running",
      content: "Background sync is active",
    );
  }

  final authService = AuthService();

  // ⏰ Run every 15 minutes
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    print("🔄 Background Task Triggered");

    try {
      // ✅ Lightweight background task: Check session validity
      bool isSessionValid = await authService.isSessionValid();
      print("🔐 Session Valid in background: $isSessionValid");

      if (!isSessionValid) {
        print("⚠️ Session expired. Notify user or prepare logout...");
        // You can trigger a local notification here if needed
      }
      await performOfflineSync();
    } catch (e) {
      print("⚠️ Background task error: $e");
    }
  });

  return true; // Keep the service running
}

Future<void> performOfflineSync() async {
  // 📡 Replace this with your real sync logic (e.g. send stored trip data)
  print("🗂 Syncing offline data..."); 
  await Future.delayed(const Duration(seconds: 2));
  print("✅ Offline sync complete.");
}
  
Future<void> initializeOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("15ce60bd-4396-446f-aba4-d180f28499b7");

  await OneSignal.Notifications.requestPermission(true);
  OneSignal.User.pushSubscription.optIn();

  // Handle notifications when the app is in the foreground
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print(
      "📩 Notification Received in Foreground: ${event.notification.jsonRepresentation()}",
    );
    event.notification.display();
  });

  // Log subscription state
  OneSignal.User.pushSubscription.addObserver((state) async {
    String? playerId = await OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      print("✅ OneSignal Player ID: $playerId");
    } else {
      print("⚠️ Player ID is null");
    }
  });

  // Check OneSignal Player ID initially
  waitForOneSignalPlayerId();
}

Future<void> waitForOneSignalPlayerId() async {
  int attempts = 0;
  while (attempts < 5) {
    // Retry up to 5 times
    String? playerId = await OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      print("✅ OneSignal Player ID: $playerId");
      break;
    } else {
      print("⏳ Retrying to get OneSignal Player ID... (${attempts + 1})");
      await Future.delayed(Duration(seconds: (attempts + 1) * 2));
    }
    attempts++;
  }
}

class MyApp extends StatefulWidget {
  final DataProvider dataProvider;

  const MyApp({super.key, required this.dataProvider});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isSessionValid = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDataOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionAndLoadData();
    }
  }

  Future<void> _loadDataOnStart() async {
    await _checkSessionAndLoadData();
  }

  Future<void> _checkSessionAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _isSessionValid = await _authService.isSessionValid();
      if (_isSessionValid) {
        await widget.dataProvider.loadInitialData();
      } else {
        print('Session is not valid, showing WelcomeScreen');
      }
    } catch (e) {
      print('⚠️ Error checking session or loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => widget.dataProvider),
        ChangeNotifierProvider(create: (_) => TimerService()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme:
                themeProvider.isDarkMode
                    ? themeProvider.darkTheme
                    : themeProvider.lightTheme,
            home:
                _isLoading
                    ? _buildLoadingScreen()
                    : _isSessionValid
                    ? const WelcomeScreen2()
                    : const WelcomeScreen2(),
            routes: {
              '/home': (context) => const WelcomeScreen2(),
              '/welcome': (context) => const WelcomeScreen2(),
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// import 'package:driversapp/SplashScreen.dart';
// import 'package:driversapp/notification_provider.dart';
// import 'package:driversapp/sap.dart';
// import 'package:flutter/material.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'theme_provider.dart';
// import 'data_provider.dart';
// import 'timer_service.dart';
// import 'welcome_screen2.dart';
// // import 'auth_service.dart';
// // import 'login_screen.dart';
// // import 'splash_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize OneSignal
//   OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
//   OneSignal.initialize("15ce60bd-4396-446f-aba4-d180f28499b7");
//   await OneSignal.Notifications.requestPermission(true);
//   OneSignal.User.pushSubscription.optIn();

//   await waitForOneSignalPlayerId();
//   OneSignal.User.pushSubscription.addObserver((state) {
//     print("Push Subscription State: ${state.toString()}");
//   });

//   OneSignal.Notifications.addForegroundWillDisplayListener((event) {
//     print(
//       "📩 Foreground Notification: ${event.notification.jsonRepresentation()}",
//     );
//     event.notification.display();
//   });

//   await Hive.initFlutter();
//   await Hive.openBox('authBox');

//   final dataProvider = DataProvider();
//   await dataProvider.loadTokenAndMixId();

//   runApp(MyApp(dataProvider: dataProvider));
// }

// Future<void> waitForOneSignalPlayerId() async {
//   int attempts = 0;
//   while (attempts < 5) {
//     String? playerId = await OneSignal.User.pushSubscription.id;
//     if (playerId != null) {
//       print("✅ OneSignal Player ID: $playerId");
//       return;
//     } else {
//       print("⏳ Retrying Player ID... (${attempts + 1})");
//       await Future.delayed(Duration(seconds: (attempts + 1) * 2));
//     }
//     attempts++;
//   }
// }

// class MyApp extends StatelessWidget {
//   final DataProvider dataProvider;
//   const MyApp(dataProvider, {super.key, required this.dataProvider});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => LanguageProvider()),
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//         ChangeNotifierProvider(create: (_) => dataProvider),
//         ChangeNotifierProvider(create: (_) => TimerService()),
//         ChangeNotifierProvider(create: (_) => NotificationProvider()),
//       ],
//       child: Consumer<ThemeProvider>(
//         builder: (context, themeProvider, _) {
//           return MaterialApp(
//             debugShowCheckedModeBanner: false,
//             theme:
//                 themeProvider.isDarkMode
//                     ? themeProvider.darkTheme
//                     : themeProvider.lightTheme,
//             home: const SplashScreen(), // Show splash first
//             routes: {
//               '/home': (context) => const WelcomeScreen2(),
//               '/login': (context) => const SapPage(),
//               '/welcome': (context) => const WelcomeScreen2(),
//             },
//           );
//         },
//       ),
//     );
//   }
// }
