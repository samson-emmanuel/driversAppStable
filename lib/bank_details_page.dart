import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'package:http/http.dart' as http;
import 'theme_provider.dart';
import 'dart:convert';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class BankDetailsPage extends StatefulWidget {
  const BankDetailsPage({super.key});

  @override
  _BankDetailsPageState createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends State<BankDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String? _selectedBank;
  String? _selectedBankName;
  bool _isLoading = false;
  bool _isOkPressed = false;

  // Variables to store verified response details
  String? verifiedAccountName;
  String? verifiedBankCode;
  String? verifiedBankName;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => Provider.of<DataProvider>(context, listen: false).fetchBanks());
    BackButtonInterceptor.add(myInterceptor);
     _fetchAndShowNotification(context);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    _accountNumberController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bank Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 18, 101, 21),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          // height: 2000,
          color: themeProvider.isDarkMode ? Colors.black : Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 50),
            child: Container(
              width: double.infinity,
              height: 900,
              decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color.fromARGB(255, 96, 139, 112)
                      : Colors.grey[350],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _accountNumberController,
                            label: "Account Number",
                            icon: Icons.account_balance,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please enter account number";
                              }
                              if (value.length != 10) {
                                return "Account Number must be 10 digits";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Select Your Bank",
                                labelStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                                prefixIcon: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 10),
                              ),
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down_circle,
                                color: Color.fromARGB(255, 18, 71, 20),
                                size: 24,
                              ),
                              value: _selectedBank,
                              items: dataProvider.banks
                                  .map((bank) => DropdownMenuItem(
                                        value: bank["code"],
                                        child: Text(
                                          bank["name"] ?? '',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBank = value;
                                  _selectedBankName = dataProvider.banks
                                      .firstWhere((bank) =>
                                          bank["code"] == value)["name"];
                                });
                              },
                              validator: (value) =>
                                  value == null ? "Please select a bank" : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneNumberController,
                            label: "Phone Number",
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please enter phone number";
                              }
                              if (value.length != 11) {
                                return "Phone Number must be 11 digits";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              backgroundColor:
                                  const Color.fromARGB(255, 25, 118, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _validateAndSubmit,
                            child: const Text(
                              "Verify",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      _verifyAccount();
    }
  }

  Future<void> _verifyAccount() async {
    setState(() {
      _isLoading = true;
    });

    final accountNumber = _accountNumberController.text;
    final bankCode = _selectedBank;

    if (bankCode == null) {
      _showDialog("Error", "Please select a bank");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final result = await dataProvider.verifyAccount(accountNumber, bankCode);

      // Store verified details
      setState(() {
        verifiedAccountName = result['account_name'];
        verifiedBankCode = bankCode;
        verifiedBankName = _selectedBankName;
      });

      _showDialog("Confirm Details",
          "Account Name: ${result['account_name']}\nAccount Number: ${result['account_number']}");
    } catch (e) {
      // _showDialog("Error", e.toString());
      _showDialog("Error", 'Account not found');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text(_isOkPressed ? "Close" : "Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (!_isOkPressed)
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  setState(() {
                    _isOkPressed = true;
                  });
                  Navigator.of(context).pop(); // Close the dialog
                  Future.delayed(Duration(milliseconds: 200), () {
                    _postAccountDetails();
                  });
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _postAccountDetails() async {
    setState(() {
      _isLoading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final token = dataProvider.token;

    final accountNumber = _accountNumberController.text;
    final phoneNumber = _phoneNumberController.text;

    try {
      final response = await http.post(
        Uri.parse(
            "https://staging-812204315267.us-central1.run.app/profile/update/driver"),
            // "http://driverappservice.lapapps.ng:5124/profile/update/driver"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode({
          'accountName': verifiedAccountName ?? "Unknown",
          'accountNumber': accountNumber,
          'bankName': _selectedBankName ?? "Unknown",
          'bankCode': verifiedBankCode ?? "Unknown",
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        _showDialog("Success", "Bank details updated successfully.");
        _clearForm();
      } else {
        _showDialog("Error", "Failed to update bank details.");
      }
    } catch (e) {
      _showDialog("Error", "Failed to connect to the server.");
    }

    setState(() {
      _isLoading = false;
    });
  }

    Future<void> _fetchAndShowNotification(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String token = dataProvider.token ?? '';

    const String url =
        "https://staging-812204315267.us-central1.run.app/notification/all";

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

      debugPrint(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data["isSuccessful"] == true && data["result"] is List) {
          List<dynamic> notifications = data["result"];

          final Map<String, dynamic> specificNotification = notifications
              .cast<Map<String, dynamic>>()
              .firstWhere(
                (notif) =>
                    (notif["title"] is String &&
                        notif["title"].toString().toLowerCase().trim() ==
                            "zero tolerance for cement theft".toLowerCase()),
                orElse: () => <String, dynamic>{},
              );

          // Check if the result is not empty
          if (specificNotification.isNotEmpty &&
              specificNotification["title"] is String &&
              specificNotification["message"] is String) {
            _showNotificationPopup(
              context,
              specificNotification["title"],
              specificNotification["message"],
            );
          }
        } else {
          debugPrint("Unexpected response structure.");
        }
      } else {
        debugPrint(
          "Failed to fetch notifications. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  // Function to display the popup notification
  Future<void> _showNotificationPopup(
    BuildContext context,
    String title,
    String message,
  ) async {
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
                Navigator.of(context).pop(); // Close popup
                // Mark as read
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }


  void _clearForm() {
    // Clear text fields
    _accountNumberController.clear();
    _phoneNumberController.clear();

    // Reset dropdown selection
    setState(() {
      _selectedBank = null;
    });
  }
}
