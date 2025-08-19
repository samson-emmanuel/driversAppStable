import 'package:driversapp/class_page.dart';
import 'package:driversapp/home_page2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_provider.dart'; // Import your DataProvider
import 'timer_logic.dart'; // Import the timer logic
import 'dart:typed_data';
import 'dart:convert';

class WelcomeUser extends StatelessWidget {
  const WelcomeUser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<void>(
        future: _initializeApp(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            final profileData = Provider.of<DataProvider>(context).profileData;
            final driverName = profileData?['driverName'] ?? 'User';
            final safetyCategory =
                profileData?['safetyMetrics']?['safetyCategory'] ?? 'UNKNOWN';
            final safetyStatus =
                profileData?['safetyMetrics']?['safetyStatus'] ?? 'UNKNOWN';
            final reasonForBlocking =
                profileData?['safetyMetrics']?['reasonForBlocking'] ?? '';
            return WelcomePage(
              username: driverName,
              safetyCategory: safetyCategory,
              safetyStatus: safetyStatus,
              reasonForBlocking: reasonForBlocking,
            );
          }
        },
      ),
    );
  }

  Future<void> _initializeApp(BuildContext context) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguage = prefs.getString('selectedLanguage');

    if (savedLanguage != null) {
      languageProvider.loadLanguage(savedLanguage); // Load the saved language
    }

    await _fetchProfileData(context);
  }

  Future<void> _fetchProfileData(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    try {
      // Use the mixId and token from DataProvider
      String mixId =
          dataProvider.profileData?['mixDriverId'] ?? 'your_mix_id_here';
      await dataProvider.fetchProfile(mixId);
    } catch (e) {
      // Handle error
    }
  }
}

class WelcomePage extends StatefulWidget {
  final String username;
  final String safetyCategory;
  final String safetyStatus;
  final String reasonForBlocking;

  const WelcomePage({
    super.key,
    required this.username,
    required this.safetyCategory,
    required this.safetyStatus,
    required this.reasonForBlocking,
  });

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String selectedLanguage = 'en';
  final FlutterTts _flutterTts = FlutterTts();
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _speakGreeting();
  }

  Future<void> _speakGreeting() async {
    final greeting = getGreeting(context);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    String languageCode = _mapLanguageCode(languageProvider.currentLanguage);
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.4);

    String message = '';
    if (widget.safetyStatus == 'UNBLOCKED' || widget.safetyStatus == 'NONE') {
      message =
          'You are free to drive, click on the proceed button to go to your dashboard';
    } else if (widget.safetyStatus == 'DDT_EXPIRED' ||
        widget.safetyStatus == 'LICENCE_EXPIRED') {
      message = '${widget.reasonForBlocking}. Kindly update your licence';
    } else {
      message =
          'You have been blocked for ${widget.reasonForBlocking} violation, click proceed button to take a lesson';
    }

    await _flutterTts.speak('$greeting, ${widget.username}! $message');
  }

  String _mapLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr-FR';
      default:
        return 'en-US';
    }
  }

  String getGreeting(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return languageProvider.translate("Good Morning");
    } else if (hour < 17) {
      return languageProvider.translate("Good Afternoon");
    } else {
      return languageProvider.translate("Good Evening");
    }
  }

  IconData getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny;
    } else if (hour < 17) {
      return Icons.wb_sunny_outlined;
    } else {
      return Icons.nights_stay;
    }
  }

  Color getGreetingIconColor() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Colors.green;
    } else if (hour < 17) {
      return Colors.yellow;
    } else {
      return Colors.blue;
    }
  }

  Color getSafetyCategoryColor() {
    switch (widget.safetyCategory) {
      case 'GREEN':
        return Colors.green;
      case 'AMBER':
        return Colors.amber;
      case 'RED':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final profileData = Provider.of<DataProvider>(context).profileData;
    Uint8List? profileImage;

    // Decode profile image if available
    if (profileData != null && profileData['base64Image'] != null) {
  try {
    // Get the Base64 string
    String base64String = profileData['base64Image'];

    // Remove any data URI prefix (e.g., "data:image/jpeg;base64,")
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }

    // Remove any whitespace or newlines
    base64String = base64String.trim();

    // Validate Base64 string format
    final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
    if (!base64Regex.hasMatch(base64String)) {
      throw FormatException('Invalid Base64 string format');
    }

    // Decode the Base64 string
    profileImage = base64Decode(base64String);
  } catch (e) {
    // Handle the error gracefully
    print('Error decoding Base64 image: $e');
    profileImage = null; // Set to null or provide a default image
  }
}

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 59, 59, 59),
              Color.fromARGB(255, 3, 27, 3)
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    getGreetingIcon(),
                    size: 80,
                    color: getGreetingIconColor(),
                  ),
                  const SizedBox(height: 14),
                  // Profile Image Display
                  if (profileImage != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: MemoryImage(profileImage),
                    )
                  else
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          AssetImage('assets/images/driverImage2.png'),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    '${getGreeting(context)}, ${widget.username}!',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    languageProvider
                        .translate('Driving is ${widget.safetyCategory}!'),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: getSafetyCategoryColor(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.safetyStatus == 'UNBLOCKED' ||
                            widget.safetyStatus == 'NONE'
                        ? 'You are free to drive'
                        : 'You are blocked for ${widget.reasonForBlocking} violation.',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: widget.safetyStatus == 'UNBLOCKED' ||
                              widget.safetyStatus == 'NONE'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLanguageButton(context, 'English', 'en'),
                          const SizedBox(width: 8),
                          _buildLanguageButton(context, 'Yoruba', 'yo'),
                          const SizedBox(width: 8),
                          _buildLanguageButton(context, 'Igbo', 'ig'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLanguageButton(context, 'Hausa', 'ha'),
                          const SizedBox(width: 8),
                          _buildLanguageButton(context, 'Pidgin', 'pi'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });

                            if (widget.reasonForBlocking == 'NONE') {
                              await startTimerLogic(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage2(),
                                ),
                              );
                            } else {
                              await startTimerLogic(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ClassPage(
                                    driverNumber: 'driverNumber',
                                  ),
                                ),
                              );
                            }

                            setState(() {
                              _isLoading = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          child: const Text('Proceed'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context, String language, String code) {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          selectedLanguage = code;
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedLanguage', code);

        Provider.of<LanguageProvider>(context, listen: false)
            .loadLanguage(code);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedLanguage == code ? Colors.black : Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        language,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
