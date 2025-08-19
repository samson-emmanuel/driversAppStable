import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class LicenseDateProvider {
  // Function to parse date from string
  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat('EEEE d MMMM, yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Function to calculate days left
  static int calculateDaysLeft(DateTime? expiryDate) {
    if (expiryDate == null) return -1;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  // Function to get color based on days left
  static Color getDaysLeftColor(int daysLeft, bool isDarkMode) {
    if (daysLeft < 0) return Colors.red;
    if (daysLeft <= 15) return Colors.red;
    if (daysLeft <= 30) return Colors.amber;
    return isDarkMode ? Colors.green : Colors.black;
  }
}
