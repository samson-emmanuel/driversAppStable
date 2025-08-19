// // ignore_for_file: unused_local_variable

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'theme_provider.dart';
// import 'data_provider.dart';
// import 'package:intl/intl.dart';

// class IncentivesReceived extends StatefulWidget {
//   const IncentivesReceived({super.key});

//   @override
//   _IncentivesReceivedState createState() => _IncentivesReceivedState();
// }

// class _IncentivesReceivedState extends State<IncentivesReceived> {
//   int itemsToShow = 10; // Initial limit for displayed items
//   bool isDataLoaded = false;
//   Map<String, bool> buttonState = {}; // Tracks disabled state of buttons
//   Map<String, bool> buttonLoadingState = {}; // Tracks loading state of buttons

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchIncentiveData();
//       _fetchAndShowNotification(context);
//     });
//     _loadButtonStates();
//   }

//   Future<void> _fetchIncentiveData() async {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final sapId = dataProvider.sapId; // Retrieve sapId from DataProvider
//     final token = dataProvider.token; // Retrieve token from DataProvider

//     if (sapId == null || token == null) {
//       setState(() {
//         isDataLoaded = true;
//       });
//       print("Error: sapId or token is null");
//       return;
//     }

//     try {
//       await dataProvider.driverIncentiveLog(sapId, token);
//       setState(() {
//         isDataLoaded = true;
//       });
//     } catch (e) {
//       setState(() {
//         isDataLoaded = true;
//       });
//       print("Error fetching incentive data: $e");
//     }
//   }

//   Future<void> _loadButtonStates() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys();
//     setState(() {
//       buttonState = {
//         for (var key in keys)
//           if (prefs.get(key) is bool) key: prefs.getBool(key) ?? false,
//       };
//     });
//   }

//   Future<void> _saveButtonState(String referenceId, bool isDisabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(referenceId, isDisabled);
//   }

//   String formatDateTime(String? dateTimeString) {
//     try {
//       if (dateTimeString == null || dateTimeString.isEmpty) {
//         return 'Date not available';
//       }
//       DateTime parsedDate = DateTime.parse(dateTimeString);
//       return DateFormat('yyyy-MM-dd hh:mm a').format(parsedDate);
//     } catch (e) {
//       print("Date parse error: $e");
//       return 'Invalid Date';
//     }
//   }

//   Future<void> _confirmPayment(String referenceId) async {
//     final dataProvider = Provider.of<DataProvider>(context, listen: false);
//     final token = dataProvider.token;

//     if (token == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Error: Token is missing")));
//       return;
//     }

//     setState(() {
//       buttonLoadingState[referenceId] = true; // Start loading spinner
//     });

//     try {
//       final response = await dataProvider.confirmPayment(referenceId, token);

//       if (response.statusCode == 200) {
//         setState(() {
//           buttonState[referenceId] = true; // Disable button after success
//           buttonLoadingState[referenceId] = false; // Stop loading spinner
//         });
//         await _saveButtonState(referenceId, true);

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Payment confirmed successfully!")),
//         );
//       } else {
//         setState(() {
//           buttonLoadingState[referenceId] = false; // Stop loading spinner
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Failed to confirm payment: ${response.body}"),
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         buttonLoadingState[referenceId] = false; // Stop loading spinner
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error during payment confirmation: $e")),
//       );
//     }
//   }

//   // Section to constantlly displaying notification when this page is opeend
//    Future<void> _fetchAndShowNotification(BuildContext context) async {
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

//       debugPrint(response.body);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = jsonDecode(response.body);

//         if (data["isSuccessful"] == true && data["result"] is List) {
//           List<dynamic> notifications = data["result"];

//           final Map<String, dynamic> specificNotification = notifications
//               .cast<Map<String, dynamic>>()
//               .firstWhere(
//                 (notif) =>
//                     (notif["title"] is String &&
//                         notif["title"].toString().toLowerCase().trim() ==
//                             "zero tolerance for cement theft".toLowerCase()),
//                 orElse: () => <String, dynamic>{},
//               );

//           // Check if the result is not empty
//           if (specificNotification.isNotEmpty &&
//               specificNotification["title"] is String &&
//               specificNotification["message"] is String) {
//             _showNotificationPopup(
//               context,
//               specificNotification["title"],
//               specificNotification["message"],
//             );
//           }
//         } else {
//           debugPrint("Unexpected response structure.");
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
//                 // Mark as read
//               },
//               child: const Text("Close"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Function to refresh the page
//   Future<void> _refreshData() async {
//     setState(() {
//       isDataLoaded = false;
//       itemsToShow = 3; // Reset the display limit on refresh
//     });
//     await _fetchIncentiveData();
//   }

//   void _loadMore() {
//     setState(() {
//       itemsToShow += 10; // Increase the limit by 10 on each load more click
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final dataProvider = Provider.of<DataProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Incentives Received',
//           style: TextStyle(
//             color: themeProvider.isDarkMode ? Colors.white : Colors.black,
//           ),
//         ),
//         backgroundColor:
//             themeProvider.isDarkMode ? Colors.green[800] : Colors.green,
//       ),
//       backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
//       body:
//           isDataLoaded
//               ? dataProvider.driverIncentiveLogs != null &&
//                       dataProvider.driverIncentiveLogs!.isNotEmpty
//                   ? RefreshIndicator(
//                     onRefresh: _refreshData,
//                     child: SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           ...List.generate(
//                             dataProvider.driverIncentiveLogs!
//                                 .take(itemsToShow)
//                                 .length,
//                             (index) =>
//                                 buildCard(index, dataProvider, themeProvider),
//                           ),
//                           if (itemsToShow <
//                               dataProvider.driverIncentiveLogs!.length)
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: ElevatedButton(
//                                 onPressed: _loadMore,
//                                 child: const Text("Load More"),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   )
//                   : Center(
//                     child: Text(
//                       'No incentive data available.',
//                       style: TextStyle(
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black54,
//                         fontSize: 18,
//                       ),
//                     ),
//                   )
//               : const Center(child: CircularProgressIndicator()),
//     );
//   }

//   Widget buildCard(
//     int index,
//     DataProvider dataProvider,
//     ThemeProvider themeProvider,
//   ) {
//     final incentive = dataProvider.driverIncentiveLogs![index];
//     final referenceId = incentive['referenceId'];
//     final confirmedByDriver = incentive['confirmedByDriver'];
//     final isButtonDisabled = buttonState[referenceId] ?? false;
//     final isButtonLoading = buttonLoadingState[referenceId] ?? false;

//     return Card(
//       color: themeProvider.isDarkMode ? Colors.green[900] : Colors.green[100],
//       margin: const EdgeInsets.all(16.0),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       'Amount: ',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black54,
//                       ),
//                     ),
//                     Text(
//                       '₦${incentive['nairaAmount']}',
//                       style: TextStyle(
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Text(
//                       'Transaction Status: ',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black54,
//                       ),
//                     ),
//                     Text(
//                       '${incentive['transactionStatus']}',
//                       style: TextStyle(
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Text(
//                       'Paid to: ',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black54,
//                       ),
//                     ),
//                     Text(
//                       '${incentive['verifiedAccountNamePaidTo']}',
//                       style: TextStyle(
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Text(
//                       'Account Paid to: ',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black54,
//                       ),
//                     ),
//                     Text(
//                       '${incentive['maskedVerifiedAccountNumberPaidTo']}',
//                       style: TextStyle(
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),

//                 Row(
//                   children: [
//                     Text(
//                       'Transaction ID: ',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black54,
//                       ),
//                     ),
//                     Text(
//                       '${incentive['referenceId']}',
//                       style: TextStyle(
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Text(
//                       'Date Paid: ',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black54,
//                       ),
//                     ),

//                     // Text(
//                     //   formatDateTime(incentive['verifiedDateTime']),
//                     //   style: TextStyle(
//                     //     color:
//                     //         themeProvider.isDarkMode
//                     //             ? Colors.white
//                     //             : Colors.black,
//                     //   ),
//                     // ),
//                     Text(
//                       formatDateTime(incentive['verifiedDateTime']),
//                       style: TextStyle(
//                         color:
//                             themeProvider.isDarkMode
//                                 ? Colors.white
//                                 : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),

//             const SizedBox(width: 20),
//             Align(
//               alignment: Alignment.centerRight,
//               child:
//                   isButtonLoading
//                       ? const CircularProgressIndicator()
//                       : ElevatedButton(
//                         onPressed:
//                             confirmedByDriver == true || isButtonDisabled
//                                 ? null
//                                 : () => _confirmPayment(referenceId),
//                         child: const Text('Confirm'),
//                       ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for modern typography
import 'theme_provider.dart';
import 'data_provider.dart';
import 'package:intl/intl.dart';

class IncentivesReceived extends StatefulWidget {
  const IncentivesReceived({super.key});

  @override
  _IncentivesReceivedState createState() => _IncentivesReceivedState();
}

class _IncentivesReceivedState extends State<IncentivesReceived> {
  int itemsToShow = 10;
  bool isDataLoaded = false;
  Map<String, bool> buttonState = {};
  Map<String, bool> buttonLoadingState = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchIncentiveData();
      _fetchAndShowNotification(context);
    });
    _loadButtonStates();
  }

  Future<void> _fetchIncentiveData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final sapId = dataProvider.sapId;
    final token = dataProvider.token;

    if (sapId == null || token == null) {
      setState(() {
        isDataLoaded = true;
      });
      print("Error: sapId or token is null");
      return;
    }

    try {
      await dataProvider.driverIncentiveLog(sapId, token);
      setState(() {
        isDataLoaded = true;
      });
    } catch (e) {
      setState(() {
        isDataLoaded = true;
      });
      print("Error fetching incentive data: $e");
    }
  }

  Future<void> _loadButtonStates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      buttonState = {
        for (var key in keys)
          if (prefs.get(key) is bool) key: prefs.getBool(key) ?? false,
      };
    });
  }

  Future<void> _saveButtonState(String referenceId, bool isDisabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(referenceId, isDisabled);
  }

  String formatDateTime(String? dateTimeString) {
    try {
      if (dateTimeString == null || dateTimeString.isEmpty) {
        return 'Date not available';
      }
      DateTime parsedDate = DateTime.parse(dateTimeString);
      return DateFormat('yyyy-MM-dd hh:mm a').format(parsedDate);
    } catch (e) {
      print("Date parse error: $e");
      return 'Invalid Date';
    }
  }

  Future<void> _confirmPayment(String referenceId) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final token = dataProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Token is missing")),
      );
      return;
    }

    setState(() {
      buttonLoadingState[referenceId] = true;
    });

    try {
      final response = await dataProvider.confirmPayment(referenceId, token);

      if (response.statusCode == 200) {
        setState(() {
          buttonState[referenceId] = true;
          buttonLoadingState[referenceId] = false;
        });
        await _saveButtonState(referenceId, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment confirmed successfully!")),
        );
      } else {
        setState(() {
          buttonLoadingState[referenceId] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to confirm payment: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() {
        buttonLoadingState[referenceId] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during payment confirmation: $e")),
      );
    }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green[800]
                    : Colors.green[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Close",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      isDataLoaded = false;
      itemsToShow = 10;
    });
    await _fetchIncentiveData();
  }

  void _loadMore() {
    setState(() {
      itemsToShow += 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Incentives Received',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.green[900] : Colors.green[600],
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: isDataLoaded
          ? dataProvider.driverIncentiveLogs != null &&
                  dataProvider.driverIncentiveLogs!.isNotEmpty
              ? RefreshIndicator(
                  color: Colors.green,
                  backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    itemCount: dataProvider.driverIncentiveLogs!.take(itemsToShow).length + 1,
                    itemBuilder: (context, index) {
                      if (index == dataProvider.driverIncentiveLogs!.take(itemsToShow).length) {
                        if (itemsToShow < dataProvider.driverIncentiveLogs!.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: _loadMore,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green[600],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "Load More",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return buildCard(index, dataProvider, themeProvider);
                    },
                  ),
                )
              : Center(
                  child: Text(
                    'No incentive data available.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
    );
  }

  Widget buildCard(
    int index,
    DataProvider dataProvider,
    ThemeProvider themeProvider,
  ) {
    final incentive = dataProvider.driverIncentiveLogs![index];
    final referenceId = incentive['referenceId'];
    final confirmedByDriver = incentive['confirmedByDriver'];
    final isButtonDisabled = buttonState[referenceId] ?? false;
    final isButtonLoading = buttonLoadingState[referenceId] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: themeProvider.isDarkMode
                ? [Colors.green[900]!, Colors.green[700]!]
                : [Colors.green[50]!, Colors.green[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Amount',
                '#${incentive['nairaAmount']}',
                themeProvider,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Status',
                '${incentive['transactionStatus']}',
                themeProvider,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Paid to',
                '${incentive['verifiedAccountNamePaidTo']}',
                themeProvider,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Account Paid to',
                '${incentive['maskedVerifiedAccountNumberPaidTo']}',
                themeProvider,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Transaction ID',
                '${incentive['referenceId']}',
                themeProvider,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Date Paid',
                formatDateTime(incentive['verifiedDateTime']),
                themeProvider,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: isButtonLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      )
                    : ElevatedButton(
                        onPressed: confirmedByDriver == true || isButtonDisabled
                            ? null
                            : () => _confirmPayment(referenceId),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeProvider themeProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}