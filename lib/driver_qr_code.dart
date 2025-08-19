import 'package:driversapp/data_provider.dart';
import 'package:driversapp/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileData = Provider.of<DataProvider>(context).profileData;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Check if profile data is null
    if (profileData == null || !profileData.containsKey('sapId')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'QR Code Display',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor:
              themeProvider.isDarkMode ? Colors.green[800] : Colors.green,
        ),
        body: Container(
          color: Colors.white,
          child: Center(
            child: Text(
              'Profile data or SAP ID is not available',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'QR Code Display',
            style: TextStyle(color: Colors.white70),
          ),
          centerTitle: true,
          backgroundColor:
              themeProvider.isDarkMode ? Colors.green[800] : Colors.green),
      body: Container(
        color: themeProvider.isDarkMode ? Colors.black : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Scan the QR Code',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Display the QR code
              QrImageView(
                data: profileData['sapId'].toString(),
                version: QrVersions.auto,
                size: 300.0,
                gapless: false,
                foregroundColor:
                    themeProvider.isDarkMode ? Colors.white : Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
