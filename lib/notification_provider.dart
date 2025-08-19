
import 'package:driversapp/data_provider.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool _hasNewNotification = false;
  List<Map<String, dynamic>> _notifications = [];

  bool get hasNewNotification => _hasNewNotification;
  List<Map<String, dynamic>> get notifications => _notifications;

  void setHasNewNotification(bool value) {
    _hasNewNotification = value;
    notifyListeners();
  }

  void addNotification(Map<String, dynamic> notification) {
    _notifications.add(notification);
    _hasNewNotification = true;
    notifyListeners();
  }

  Future<void> fetchNotifications(DataProvider dataProvider) async {
    try {
      await dataProvider.fetchNotifications();
      _notifications = List<Map<String, dynamic>>.from(dataProvider.notificationsData ?? []);
      _hasNewNotification = _notifications.isNotEmpty;
      notifyListeners();
    } catch (e) {
      print('Error fetching notifications:');
    }
  }

  // Clears all notifications and resets the new notification flag
  void clearNotifications() {
    _notifications.clear();
    _hasNewNotification = false;
    notifyListeners();
  }
}