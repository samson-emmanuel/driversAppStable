// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import 'theme_provider.dart';
import 'data_provider.dart'; // Import your DataProvider

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    try {
      await notificationProvider.fetchNotifications(dataProvider);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching notifications: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final notifications =
        Provider.of<NotificationProvider>(context).notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Container(
        color: isDarkMode ? Colors.black : Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  )
                : notifications.isEmpty
                    ? Center(
                        child: Text(
                          'No notifications available.',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode ? Colors.grey : Colors.black54,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              color:
                                  isDarkMode ? Colors.grey[850] : Colors.white,
                              elevation: 4,
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  notification['message'],
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  notification['elapsedTime'],
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
