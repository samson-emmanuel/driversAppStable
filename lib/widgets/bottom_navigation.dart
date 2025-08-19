// ignore_for_file: unused_local_variable

import 'package:driversapp/backhaul.dart';
import 'package:driversapp/current_trip.dart';
import 'package:driversapp/data_provider.dart';
import 'package:driversapp/event_page.dart';
import 'package:driversapp/home_page2.dart';
import 'package:driversapp/settings.dart';
import 'package:driversapp/theme_provider.dart';
import 'package:driversapp/trip_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage2()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TripPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ViolationPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BackHauling()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CurrentTrip()),
        );
        break;
      case 5:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    const backgroundColor = Colors.black;
    const selectedItemColor = Colors.green;
    const unselectedItemColor = Color.fromARGB(255, 0, 0, 0);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
            color: currentIndex == 0 ? selectedItemColor : unselectedItemColor,
          ),
          label: languageProvider.translate('Home'),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.directions_car,
            color: currentIndex == 1 ? selectedItemColor : unselectedItemColor,
          ),
          label: languageProvider.translate('Trip'),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.event,
            color: currentIndex == 2 ? selectedItemColor : unselectedItemColor,
          ),
          label: languageProvider.translate('Event'),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings_backup_restore_outlined,
            color: currentIndex == 3 ? selectedItemColor : unselectedItemColor,
          ),
          label: languageProvider.translate('BackHaul'),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.share_arrival_time_rounded,
            color: currentIndex == 4 ? selectedItemColor : unselectedItemColor,
          ),
          label: languageProvider.translate('Current Trip'),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: currentIndex == 5 ? selectedItemColor : unselectedItemColor,
          ),
          label: languageProvider.translate('Settings'),
        ),
      ],
    );
  }
}
