import 'dart:convert';
import 'package:driversapp/data_provider.dart';
import 'package:driversapp/device_service.dart';
import 'package:driversapp/theme_provider.dart';
import 'package:driversapp/welcom_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

class AltLogin extends StatefulWidget {
  final String driverNumber;

  const AltLogin({super.key, required this.driverNumber});

  @override
  _AltLoginState createState() => _AltLoginState();
}

class _AltLoginState extends State<AltLogin> {
  final _formKey = GlobalKey<FormState>();
  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();
  final _controller3 = TextEditingController();
  final _controller4 = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    super.dispose();
  }

  // Future<void> _submitForm() async {
  //   if (!_formKey.currentState!.validate() || _selectedDate == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please complete all fields.')),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   String enteredText =
  //       _controller1.text +
  //       _controller2.text +
  //       _controller3.text +
  //       _controller4.text;
  //   String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
  //   String? deviceId = await DeviceService.getDeviceIdentifier();

  //   try {
  //     final response = await http.post(
  //       Uri.parse(
  //         'https://staging-812204315267.us-central1.run.app/auth/driver/login/alt',
  //       ),
  //       headers: <String, String>{
  //         "Content-Type": "application/json; charset=UTF-8",
  //         'app-version': '1.12',
  //         'app-name': 'drivers app',
  //       },
  //       body: jsonEncode({
  //         "sapId": widget.driverNumber,
  //         "dateOfLicenseExpiry": formattedDate,
  //         "lastFourDigitsOfPhoneNumber": enteredText,
  //         "deviceId": deviceId ?? "",
  //       }),
  //     );
  //     debugPrint('This is the deveice Id: $deviceId');

  //     setState(() {
  //       _isLoading = false;
  //     });
  //     debugPrint('This is the status code: ${response.statusCode}');

  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body);

  //       if (responseData['isSuccessful']) {
  //         int? appUserId =
  //             responseData['result']['user']['profile']['appUserId'];
  //         String? oneSignalId =
  //             responseData['result']['user']['profile']['oneSignalId'];
  //         String? token = responseData['result']['token'];
  //         debugPrint("✅ Extracted User ID: $appUserId");
  //         debugPrint("✅ Extracted User ID after OTP: $token");
  //         debugPrint("✅ Extracted oneSignalId: $oneSignalId");

  //         if (appUserId != null) {
  //           await _generateAndSendPushToken(appUserId, oneSignalId!);
  //         } else {
  //           debugPrint("⚠️ Warning: appUserId is null, skipping push token.");
  //         }

  //         // ✅ Process response using DataProvider
  //         final dataProvider = Provider.of<DataProvider>(
  //           context,
  //           listen: false,
  //         );
  //         dataProvider.handleOtpResponse(responseData);

  //         // ✅ Navigate to WelcomeUser screen
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => const WelcomeUser()),
  //         );
  //       } else {
  //         final message = responseData['message'] ?? 'Login failed, try again.';
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text(message)));
  //       }
  //     } else {
  //       try {
  //         final responseData = jsonDecode(response.body);
  //         final message = responseData['message'] ?? 'Check your details.';
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text(message)));
  //       } catch (_) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('Check your details.')));
  //       }
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Login failed, Network Issue')),
  //     );
  //   }
  // }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String enteredText =
        _controller1.text +
        _controller2.text +
        _controller3.text +
        _controller4.text;
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    String? deviceId = await DeviceService.getDeviceIdentifier();

    try {
      final response = await http.post(
        Uri.parse(
          'https://staging-812204315267.us-central1.run.app/auth/driver/login/alt',
        ),
        headers: <String, String>{
          "Content-Type": "application/json; charset=UTF-8",
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode({
          "sapId": widget.driverNumber,
          "dateOfLicenseExpiry": formattedDate,
          "lastFourDigitsOfPhoneNumber": enteredText,
          "deviceId": deviceId ?? "",
        }),
      );

      debugPrint('📡 Sent login request. Device ID: $deviceId');
      setState(() {
        _isLoading = false;
      });

      debugPrint('📨 Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['isSuccessful']) {
          final result = responseData['result'];
          final user = result['user'];
          final profile = user['profile'];

          int? appUserId = profile['appUserId'];
          String? oneSignalId = profile['oneSignalId'];
          String? deviceId = profile['deviceId'];
          String? token = result['token'];

          debugPrint("✅ Extracted User ID: $appUserId");
          debugPrint("✅ Token: $token");
          debugPrint("✅ OneSignal ID: $oneSignalId");
          debugPrint("✅ Device ID: $deviceId");

          // Call token update only if either value is null
          if (appUserId != null && (oneSignalId == null || deviceId == null)) {
            await _generateAndSendPushToken(appUserId, token);
          } else {
            debugPrint("🔵 No need to send push token: already registered.");
          }

          final dataProvider = Provider.of<DataProvider>(
            context,
            listen: false,
          );
          dataProvider.handleOtpResponse(responseData);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeUser()),
          );
        } else {
          final message = responseData['message'] ?? 'Login failed, try again.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        try {
          final responseData = jsonDecode(response.body);
          final message = responseData['message'] ?? 'Check your details.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        } catch (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Check your details.')));
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed, Network Issue')),
      );
      debugPrint("❌ Error during login: $e");
    }
  }

  // Future<void> _generateAndSendPushToken(
  //   int appUserId,
  //   String oneSignalId,
  // ) async {
  //   try {
  //     // ✅ Get OneSignal push token
  //     String? fcmToken = await OneSignal.User.pushSubscription.token;
  //     // debugPrint("📌 FCM Token: $fcmToken");
  //     // debugPrint("📌 appUserId: $appUserId");
  //     debugPrint("📌 appUserId: $oneSignalId");
  //     if (fcmToken == null) {
  //       print("❌ Failed to retrieve OneSignal push token.");
  //       return;
  //     }

  //     final pushTokenData = {
  //       "userId": appUserId, // ✅ Ensure correct field name
  //       "pushToken": oneSignalId, // ✅ OneSignal push token
  //       "type": "androidPush",
  //     };

  //     final response = await http.post(
  //       Uri.parse(
  //         'https://staging-812204315267.us-central1.run.app/notification/push-token',
  //       ),
  //       headers: {
  //         "Content-Type": "application/json; charset=UTF-8",
  //         'Authorization': 'Bearer $oneSignalId', // ✅ Ensure token is correct
  //         "app-version": "1.12",
  //         "app-name": "drivers app",
  //       },
  //       body: jsonEncode(pushTokenData),
  //     );
  //     debugPrint(
  //       'Generate and sent push Token status code: ${response.statusCode}',
  //     );
  //     if (response.statusCode == 200) {
  //       print("✅ Push token sent successfully.");
  //     } else {
  //       print("❌ Failed to send push token: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("❌ Error sending push token: $e");
  //   }
  

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

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _entryField(TextEditingController controller, FocusNode focusNode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 40,
      child: TextFormField(
        textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Alternative Login',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal),
        ),
        backgroundColor: Colors.green,
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Enter the last 4 digits of your phone number and\nSelect your license expiring date:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
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
                    _entryField(_controller1, FocusNode()),
                    _entryField(_controller2, FocusNode()),
                    _entryField(_controller3, FocusNode()),
                    _entryField(_controller4, FocusNode()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Pick Driver License Expiring Date',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDate == null
                  ? 'No date selected'
                  : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 24,
              ),
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text(
                          'Submit',
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
