// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:driversapp/data_provider.dart';
import 'package:driversapp/device_service.dart';
import 'package:driversapp/otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

class SapPage extends StatefulWidget {
  const SapPage({super.key});

  @override
  _SapPageState createState() => _SapPageState();
}

class _SapPageState extends State<SapPage> with RouteAware {
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();
  final TextEditingController _controller5 = TextEditingController();
  final TextEditingController _controller6 = TextEditingController();
  final TextEditingController _controller7 = TextEditingController();
  final TextEditingController _controller8 = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();
  final FocusNode _focusNode5 = FocusNode();
  final FocusNode _focusNode6 = FocusNode();
  final FocusNode _focusNode7 = FocusNode();
  final FocusNode _focusNode8 = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // bool _isPopupVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ModalRoute.of(context)!.addScopedWillPopCallback(_willPopCallback);
  }

  Future<bool> _willPopCallback() async {
    // Clear the text fields when navigating away
    _controller1.clear();
    _controller2.clear();
    _controller3.clear();
    _controller4.clear();
    _controller5.clear();
    _controller6.clear();
    _controller7.clear();
    _controller8.clear();
    return true;
  }

  @override
  void dispose() {
    ModalRoute.of(context)!.removeScopedWillPopCallback(_willPopCallback);
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    _focusNode5.dispose();
    _focusNode6.dispose();
    _focusNode7.dispose();
    _focusNode8.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    _controller5.dispose();
    _controller6.dispose();
    _controller7.dispose();
    _controller8.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String driverNumber =
          _controller1.text +
          _controller2.text +
          _controller3.text +
          _controller4.text +
          _controller5.text +
          _controller6.text +
          _controller7.text +
          _controller8.text;
      String? deviceId = await DeviceService.getDeviceIdentifier();

      try {
        final response = await http.post(
          Uri.parse(
            'https://staging-812204315267.us-central1.run.app/auth/driver/login',
            // 'https://staging-812204315267.us-central1.run.app/auth/driver/login',
          ),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept-Encoding': 'gzip, deflate, br',
            'app-version': '1.12',
            'app-name': 'drivers app',
          },
          body: jsonEncode(<String, String>{
            'sapId': driverNumber,
            'deviceId': deviceId ?? "",
          }),
        );

        debugPrint("Login Response: ${response.body}");
        debugPrint("Status Code: ${response.statusCode}");

        setState(() {
          _isLoading = false;
        });

        int? userId;
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          userId = responseData['appUserId'];

          if (userId != null) {
            debugPrint("✅ Extracted User ID: $userId");
            // await _generateAndSendPushToken(userId);
          } else {
            debugPrint(
              "⚠️ Warning: appUserId is null, proceeding without sending push token.",
            );
          }
        } else {
          final responseData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'An unknown error occurred',
              ),
            ),
          );
          debugPrint("❌ API Error: ${response.body}");
        }

        // ✅ Always navigate to OtpPage, even if userId is null
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChangeNotifierProvider.value(
                    value: Provider.of<DataProvider>(context, listen: false),
                    child: OtpPage(driverNumber: driverNumber),
                  ),
            ),
          );
        }
      } catch (e) {
        debugPrint("❌ Network Error: $e");
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network Error: $e')));

        // ✅ Ensure navigation still happens even if there's an error
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChangeNotifierProvider.value(
                    value: Provider.of<DataProvider>(context, listen: false),
                    child: OtpPage(driverNumber: driverNumber),
                  ),
            ),
          );
        }
      }
    }
  }

  // Future<void> _generateAndSendPushToken(int userId) async {
  //   try {
  //     // Get OneSignal Player ID (push token)
  //     String? pushToken = await OneSignal.User.pushSubscription.id;

  //     if (pushToken == null) {
  //       print("❌ Failed to retrieve OneSignal push token.");
  //       return;
  //     }

  //     final pushTokenData = {
  //       "userId": userId,
  //       "pushToken": pushToken,
  //       "type": "androidPush",
  //     };

  //     final response = await http.post(
  //       Uri.parse(
  //         'https://staging-812204315267.us-central1.run.app/notification/push-token',
  //       ),
  //       headers: {
  //         "Content-Type": "application/json; charset=UTF-8",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Driver Number',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal),
        ),
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.black, // Set background color to black
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Enter Driver Number:',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Set text color to white
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
                    _buildDigitField(_controller1, _focusNode1, _focusNode2),
                    _buildDigitField(_controller2, _focusNode2, _focusNode3),
                    _buildDigitField(_controller3, _focusNode3, _focusNode4),
                    _buildDigitField(_controller4, _focusNode4, _focusNode5),
                    _buildDigitField(_controller5, _focusNode5, _focusNode6),
                    _buildDigitField(_controller6, _focusNode6, _focusNode7),
                    _buildDigitField(_controller7, _focusNode7, _focusNode8),
                    _buildDigitField(_controller8, _focusNode8, null),
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
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Set button color
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text(
                          'Request Code',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitField(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 30,
      child: TextFormField(
        textAlign: TextAlign.center,
        focusNode: currentFocus,
        controller: controller,
        decoration: const InputDecoration(labelText: ''),
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white), // Set text color to white
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
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              currentFocus.unfocus();
            }
          }
        },
      ),
    );
  }
}
