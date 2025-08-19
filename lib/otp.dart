// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'package:driversapp/alt_login.dart';
import 'package:driversapp/device_service.dart';
import 'package:driversapp/welcom_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'theme_provider.dart';

class OtpPage extends StatefulWidget {
  final String driverNumber;

  const OtpPage({super.key, required this.driverNumber});

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();
  final FocusNode _focusNode5 = FocusNode();
  final FocusNode _focusNode6 = FocusNode();

  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();
  final TextEditingController _controller5 = TextEditingController();
  final TextEditingController _controller6 = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    _focusNode5.dispose();
    _focusNode6.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    _controller5.dispose();
    _controller6.dispose();
    super.dispose();
  }

  // Future<void> _submitOtpForm() async {
  //   String enteredOtp =
  //       _controller1.text +
  //       _controller2.text +
  //       _controller3.text +
  //       _controller4.text +
  //       _controller5.text +
  //       _controller6.text;

  //   if (enteredOtp.isEmpty || enteredOtp.length != 6) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     final otpResponse = await http.post(
  //       Uri.parse(
  //         'https://staging-812204315267.us-central1.run.app/auth/verify/$enteredOtp',
  //       ),
  //       headers: <String, String>{
  //         "Content-Type": "application/json; charset=UTF-8",
  //         'app-version': '1.12',
  //         'app-name': 'drivers app',
  //       },
  //     );

  //     print('OTP Response: ${otpResponse.body}');

  //     setState(() {
  //       _isLoading = false;
  //     });

  //     if (otpResponse.statusCode == 200) {
  //       final otpData = jsonDecode(otpResponse.body);

  //       if (otpData['isSuccessful']) {
  //         // ✅ Extract appUserId
  //         int? appUserId = otpData['result']['user']['profile']['appUserId'];
  //         String? token = otpData['result']['token'];
  //         debugPrint("✅ Extracted User ID after OTP: $appUserId");
  //         debugPrint("✅ Extracted User ID after OTP: $token");

  //         if (appUserId != null) {
  //           await _generateAndSendPushToken(appUserId, token!);
  //         } else {
  //           debugPrint("⚠️ Warning: appUserId is null, skipping push token.");
  //         }

  //         // ✅ Handle DataProvider and navigate
  //         final dataProvider = Provider.of<DataProvider>(
  //           context,
  //           listen: false,
  //         );
  //         dataProvider.handleOtpResponse(otpData);

  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const WelcomeUser()),
  //         );
  //       } else {
  //         // ❌ Handle OTP verification failure
  //         final message =
  //             otpData['message'] ?? 'OTP verification failed, try again.';
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text(message)));
  //       }
  //     } else {
  //       try {
  //         final responseData = jsonDecode(otpResponse.body);
  //         final message = responseData['message'] ?? 'Incorrect OTP.';
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text(message)));
  //       } catch (_) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('Incorrect OTP.')));
  //       }
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Failed to verify OTP: $e')));
  //   }
  // }

  Future<void> _submitOtpForm() async {
    String enteredOtp =
        _controller1.text +
        _controller2.text +
        _controller3.text +
        _controller4.text +
        _controller5.text +
        _controller6.text;

    if (enteredOtp.isEmpty || enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final otpResponse = await http.post(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/auth/verify/$enteredOtp',
        ),
        headers: <String, String>{
          "Content-Type": "application/json; charset=UTF-8",
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      print('OTP Response: ${otpResponse.body}');

      setState(() {
        _isLoading = false;
      });

      if (otpResponse.statusCode == 200) {
        final otpData = jsonDecode(otpResponse.body);

        if (otpData['isSuccessful']) {
          final result = otpData['result'];
          final user = result['user'];
          final profile = user['profile'];

          int? appUserId = profile['appUserId'];
          String? oneSignalId = profile['oneSignalId'];
          String? deviceId = profile['deviceId'];
          String? token = result['token'];

          debugPrint("✅ Extracted appUserId: $appUserId");
          debugPrint("✅ Token: $token");
          debugPrint("✅ oneSignalId: $oneSignalId");
          debugPrint("✅ deviceId: $deviceId");

          if (appUserId != null && token != null) {
            if (oneSignalId == null || deviceId == null) {
              await _generateAndSendPushToken(appUserId, token);
            } else {
              debugPrint(
                "🔵 Push token and device ID already present. Skipping generation.",
              );
            }
          } else {
            debugPrint(
              "⚠️ appUserId or token missing. Skipping push token registration.",
            );
          }

          final dataProvider = Provider.of<DataProvider>(
            context,
            listen: false,
          );
          dataProvider.handleOtpResponse(otpData);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeUser()),
          );
        } else {
          final message =
              otpData['message'] ?? 'OTP verification failed, try again.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        try {
          final responseData = jsonDecode(otpResponse.body);
          final message = responseData['message'] ?? 'Incorrect OTP.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        } catch (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Incorrect OTP.')));
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to verify OTP: $e')));
    }
  }

  // Future<void> _generateAndSendPushToken(int appUserId, String token) async {
  //   try {
  //     // ✅ Get OneSignal push token
  //     String? fcmToken = await OneSignal.User.pushSubscription.token;
  //     debugPrint("📌 FCM Token: $fcmToken");
  //     debugPrint("📌 appUserId: $appUserId");

  //     if (fcmToken == null) {
  //       print("❌ Failed to retrieve OneSignal push token.");
  //       return;
  //     }

  //     final pushTokenData = {
  //       "userId": appUserId, // ✅ Ensure correct field name
  //       "pushToken": fcmToken, // ✅ OneSignal push token
  //       "type": "androidPush",
  //     };

  //     final response = await http.post(
  //       Uri.parse(
  //         'https://staging-812204315267.us-central1.run.app/notification/push-token',
  //       ),
  //       headers: {
  //         "Content-Type": "application/json; charset=UTF-8",
  //         'Authorization': 'Bearer $token', // ✅ Ensure token is correct
  //         "app-version": "1.12",
  //         "app-name": "drivers app",
  //       },
  //       body: jsonEncode(pushTokenData),
  //     );

  //     if (response.statusCode == 200) {
  //       print("✅ Push token sent successfully.");
  //     } else {
  //       print("❌ Failed to send push token: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("❌ Error sending push token: $e");
  //   }
  // }

  Future<void> _generateAndSendPushToken(int appUserId, token) async {
    try {
      String? fcmToken = await OneSignal.User.pushSubscription.token;
      String? deviceId = await DeviceService.getDeviceIdentifier();

      if (fcmToken == null || deviceId == null) {
        print("❌ Cannot generate push token or device ID.");
        return;
      }

      final pushTokenData = {
        "userId": appUserId,
        "pushToken": fcmToken,
        "type": "androidPush",
        "deviceId": deviceId,
      };

      final response = await http.post(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/notification/push-token',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          "Content-Type": "application/json; charset=UTF-8",
          "app-version": "1.12",
          "app-name": "drivers app",
        },
        body: jsonEncode(pushTokenData),
      );

      debugPrint('📤 Push token submission status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print("✅ Push token sent successfully.");
      } else {
        print("❌ Failed to send push token: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending push token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'OTP',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.green,
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'INPUT CODE:',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    otpInputField(_focusNode1, _controller1, themeProvider),
                    otpInputField(_focusNode2, _controller2, themeProvider),
                    otpInputField(_focusNode3, _controller3, themeProvider),
                    otpInputField(_focusNode4, _controller4, themeProvider),
                    otpInputField(_focusNode5, _controller5, themeProvider),
                    otpInputField(_focusNode6, _controller6, themeProvider),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 24,
              ),
              child: ElevatedButton(
                onPressed: _submitOtpForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Set button color to green
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text(
                          'Proceed',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No OTP? ',
                  style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AltLogin(driverNumber: widget.driverNumber),
                      ),
                    );
                  },
                  child: const Text(
                    'Click here to login',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget otpInputField(
    FocusNode focusNode,
    TextEditingController controller,
    ThemeProvider themeProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 40,
      child: TextFormField(
        textAlign: TextAlign.center,
        focusNode: focusNode,
        controller: controller,
        decoration: InputDecoration(
          labelText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '';
          }
          return null;
        },
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}
