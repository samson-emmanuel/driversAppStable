// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'package:intl/intl.dart';
import 'widgets/bottom_navigation.dart';
import 'theme_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class ViolationPage extends StatefulWidget {
  const ViolationPage({super.key});

  @override
  _ViolationPageState createState() => _ViolationPageState();
}

class _ViolationPageState extends State<ViolationPage> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchViolations();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    // Remove the back button interceptor to prevent memory leaks
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  // The interceptor function
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    // Returning true stops the default back button behavior (i.e., prevents navigation)
    return true;
  }

  Future<void> _fetchViolations() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mixId = dataProvider.profileData?['mixDriverId'] ?? '';

    try {
      await dataProvider.fetchViolations(mixId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching violations: Check your network';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final violationData = Provider.of<DataProvider>(context).violationData;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Violations'),
        backgroundColor:
            themeProvider.isDarkMode ? Colors.green[800] : Colors.green,
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                )
              : violationData == null || violationData['violations'].isEmpty
                  ? Center(
                      child: Text(
                        'No violations today.',
                        style: TextStyle(
                          fontSize: 18,
                          color: themeProvider.isDarkMode
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: _buildIndividualViolationCards(
                          violationData['violations']),
                    ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }

  List<Widget> _buildIndividualViolationCards(Map<String, dynamic> violations) {
    List<Widget> violationCards = [];
    violations.forEach((day, violationList) {
      violationList.forEach((violation) {
        violationCards.add(_buildViolationCard(
          violation['violationName'],
          violation['violationDescription'],
          violation['initialStartDateTime'],
        ));
      });
    });
    return violationCards;
  }

  Widget _buildViolationCard(
      String violationName, String violationDescription, String violationTime) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.grey[300],
      elevation: 4,
      child: ListTile(
        leading: const Icon(
          Icons.warning,
          color: Colors.red,
          size: 30,
        ),
        title: Text(
          violationName,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Location: $violationDescription\nTime: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(violationTime))}',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
