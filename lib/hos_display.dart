// ignore_for_file: unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'theme_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    return true;
  }

  Duration _parseDuration(String duration) {
    final match = RegExp(r'PT(\d+H)?(\d+M)?(\d+S)?').firstMatch(duration);
    if (match == null) return const Duration();

    final hours = int.parse(match.group(1)?.replaceAll('H', '') ?? '0');
    final minutes = int.parse(match.group(2)?.replaceAll('M', '') ?? '0');
    final seconds = int.parse(match.group(3)?.replaceAll('S', '') ?? '0');
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  String _formatDuration(Duration duration) {
    return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}';
  }

  Duration _parseExtendedDuration(String duration) {
    final match =
        RegExp(r'P(\d+D)?T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?').firstMatch(duration);
    if (match == null) return const Duration();

    int days = int.parse(match.group(1)?.replaceAll('D', '') ?? '0');
    int hours = int.parse(match.group(2)?.replaceAll('H', '') ?? '0');
    final int minutes = int.parse(match.group(3)?.replaceAll('M', '') ?? '0');

    final secondsMatch = match.group(4);
    final double seconds = secondsMatch != null
        ? double.parse(secondsMatch.replaceAll('S', ''))
        : 0.0;

    if (hours >= 24) {
      days += hours ~/ 24;
      hours = hours % 24;
    }

    final int totalSeconds = seconds.floor();
    final int milliseconds = ((seconds - totalSeconds) * 1000).round();

    return Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: totalSeconds,
      milliseconds: milliseconds,
    );
  }

  String _formatExtendedDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    // final seconds = duration.inSeconds.remainder(60);

    return '${days}D ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Color _getColor(Duration duration) {
    if (duration.inHours >= 2) {
      return Colors.green;
    } else if (duration.inHours >= 1) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final hosData = dataProvider.hosData ?? {};
    final screenWidth = MediaQuery.of(context).size.width;

    final dailyTimeBeforeRest =
        _parseDuration(hosData['dailyTimeBeforeRest'] ?? 'PT0S');
    final weeklyTimeBeforeRest =
        _parseExtendedDuration(hosData['weeklyTimeBeforeRest'] ?? 'PT0S');
    final dailyAvailableDrivingRolling =
        _parseDuration(hosData['dailyAvailableDrivingRolling'] ?? 'PT0S');
    final dayDrivingUsed = _parseDuration(hosData['dayDrivingUsed'] ?? 'PT0S');
    final nightDrivingUsed =
        _parseDuration(hosData['nightDrivingUsed'] ?? 'PT0S');
    final expectedRestDuration =
        _parseDuration(hosData['expectedRestDuration'] ?? 'PT0S');
    final lastUpdated = hosData['lastUpdated'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate("HOS Timer"),
          style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: themeProvider.isDarkMode
            ? const Color.fromARGB(255, 36, 98, 38)
            : const Color.fromARGB(255, 36, 98, 38),
      ),
      body: Container(
        color: themeProvider.isDarkMode ? Colors.black : Colors.white,
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: GridView.count(
          crossAxisCount: screenWidth < 600 ? 2 : 3,
          crossAxisSpacing: screenWidth * 0.02,
          mainAxisSpacing: screenWidth * 0.012,
          children: [
            _buildCircularProgressBar(context, dailyTimeBeforeRest,
                languageProvider.translate("Daily Time Before Rest\n(H M)")),
            _buildCircularProgressBar(context, weeklyTimeBeforeRest,
                languageProvider.translate("Weekly Time Before Rest\n(H M)")),
            _buildCircularProgressBar(context, dailyAvailableDrivingRolling,
                languageProvider.translate("Daily Available Driving\n(H M)")),
            _buildCircularProgressBar(context, dayDrivingUsed,
                languageProvider.translate("Day Driving Used\n(H M)")),
            _buildCircularProgressBar(context, nightDrivingUsed,
                languageProvider.translate("Night Driving Used\n(H M)")),
            _buildCircularProgressBar(context, expectedRestDuration,
                languageProvider.translate("Expected Rest Duration\n(H M)")),
            Text(
              'Last Updated: $lastUpdated',
              style: TextStyle(
                fontSize: 10,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgressBar(
      BuildContext context, Duration duration, String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final progressBarSize = screenWidth * 0.3; // Increased size

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: progressBarSize,
          height: progressBarSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: duration.inSeconds /
                    (4 * 3600), // Assuming max 4 hours for example
                strokeWidth: screenWidth * 0.2,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(_getColor(duration)),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                    fontSize: screenWidth * 0.04, color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.green),
        ),
      ],
    );
  }
}
