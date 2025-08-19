import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'sap.dart';

class WelcomeScreen2 extends StatefulWidget {
  const WelcomeScreen2({super.key});

  @override
  State<WelcomeScreen2> createState() => _WelcomeScreen2State();
}

class _WelcomeScreen2State extends State<WelcomeScreen2> {
  @override
  void initState() {
    super.initState();
    _checkAndEnableLocation();
    Timer(const Duration(seconds: 5), () {
      _checkTermsAccepted();
    });
  }

  Future<void> _checkAndEnableLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? locationChecked = prefs.getBool('locationChecked');

    if (locationChecked == null || !locationChecked) {
      Location location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        await location.requestService();
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        await location.requestPermission();
      }

      // Mark that the location check has been done
      await prefs.setBool('locationChecked', true);
    }
  }

  Future<void> _checkTermsAccepted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? accepted = prefs.getBool('termsAccepted');

    if (accepted == null || !accepted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SapPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 61, 13),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/lafarge_logo2.png', width: 140),
            const SizedBox(height: 2),
            Text(
              'v1.12',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: AnimatedTextKit(
                totalRepeatCount: 40,
                animatedTexts: [
                  ScaleAnimatedText(
                    'Drive Safely',
                    duration: const Duration(milliseconds: 4000),
                    textStyle: const TextStyle(
                      color: Color.fromARGB(255, 242, 244, 255),
                      fontSize: 22.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _isLoading = false;

  final String termsAndConditions = """
  Collection and Processing of Personal Data: This Driver's App collects and processes personal data, including your name, location, telephone number, vehicle information, and other related data. The data is collected to support driver safety, reward recognition, operational efficiency, and other related activities. By clicking on the Panic Button, you consent to your current location being shared with both Lafarge Africa Plc and your employer to ensure prompt response to emergency situations. All personal data collected and processed through this application is protected in accordance with Lafarge Africa Plc's privacy policy and the Nigerian Data Protection Regulation (NDPR). You reserve the right to withdraw your consent and request the cessation of further data processing at any time.
  """;

  Future<void> _acceptTerms(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', true);

    // Check and enable location
    await _checkAndEnableLocation();

    // Navigate to the next page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SapPage()),
    );
  }

  Future<void> _checkAndEnableLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? locationChecked = prefs.getBool('locationChecked');

    if (locationChecked == null || !locationChecked) {
      Location location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        await location.requestService();
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        await location.requestPermission();
      }

      // Mark that the location check has been done
      await prefs.setBool('locationChecked', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: const Color.fromARGB(255, 0, 105, 47),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Terms and Conditions',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 105, 47),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.9),
                    blurRadius: 10.0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                termsAndConditions,
                style: const TextStyle(fontSize: 19.0, height: 1.8),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _acceptTerms(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 15.0,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
