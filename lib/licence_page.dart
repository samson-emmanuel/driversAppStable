import 'package:driversapp/licence_date_provider.dart';
import 'package:driversapp/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class LicencePage extends StatefulWidget {
  const LicencePage({super.key});

  @override
  State<LicencePage> createState() => _LicencePageState();
}

class _LicencePageState extends State<LicencePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    _checkAndShowNotifications();

    // Initialize the animation controller for blinking effect
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 500), // Adjust speed as needed
      vsync: this,
    )..repeat(reverse: true); // Repeats the animation back and forth
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    _blinkController.dispose(); // Dispose of the animation controller
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    return true;
  }

  void _checkAndShowNotifications() {
    final profileData =
        Provider.of<DataProvider>(context, listen: false).profileData;
    final licenseExpiryDateStr = profileData?['licenseExpiryDate'] ?? 'N/A';
    final ddtExpiryDateStr = profileData?['ddtExpiryDate'] ?? 'N/A';

    DateTime? licenseExpiryDate =
        LicenseDateProvider.parseDate(licenseExpiryDateStr);
    DateTime? ddtExpiryDate = LicenseDateProvider.parseDate(ddtExpiryDateStr);

    int licenseDaysLeft =
        LicenseDateProvider.calculateDaysLeft(licenseExpiryDate);
    int ddtDaysLeft = LicenseDateProvider.calculateDaysLeft(ddtExpiryDate);

    List<int> notifyDays = [30, 20, 10, 5, 2, 1];
    if (notifyDays.contains(licenseDaysLeft)) {
      _showNotification('License', licenseDaysLeft);
    }
    if (notifyDays.contains(ddtDaysLeft)) {
      _showNotification('DDT', ddtDaysLeft);
    }
  }

  void _showNotification(String itemName, int daysLeft) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reminder'),
          content: Text('$daysLeft day(s) left until $itemName expires.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileData = Provider.of<DataProvider>(context).profileData;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final licenseNumber = profileData?['licenseNumber'] ?? 'N/A';
    final licenseExpiryDateStr = profileData?['licenseExpiryDate'] ?? 'N/A';
    final ddtExpiryDateStr = profileData?['ddtExpiryDate'] ?? 'N/A';

    DateTime? licenseExpiryDate =
        LicenseDateProvider.parseDate(licenseExpiryDateStr);
    DateTime? ddtExpiryDate = LicenseDateProvider.parseDate(ddtExpiryDateStr);

    int licenseDaysLeft =
        LicenseDateProvider.calculateDaysLeft(licenseExpiryDate);
    int ddtDaysLeft = LicenseDateProvider.calculateDaysLeft(ddtExpiryDate);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          languageProvider.translate('Licence Page'),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Container(
        height: double.infinity,
        color: themeProvider.isDarkMode ? Colors.black : Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('Licence Details'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.green : Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  languageProvider.translate('License Number'),
                  licenseNumber,
                  isDarkMode,
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  languageProvider.translate('License Expiry Date'),
                  licenseExpiryDateStr,
                  isDarkMode,
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  languageProvider.translate('License Status'),
                  licenseDaysLeft < 0
                      ? languageProvider.translate('License has expired')
                      : '$licenseDaysLeft ${languageProvider.translate('days left')}',
                  isDarkMode,
                  LicenseDateProvider.getDaysLeftColor(
                      licenseDaysLeft, isDarkMode),
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  languageProvider.translate('DDT Expiry Date'),
                  ddtExpiryDateStr,
                  isDarkMode,
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  languageProvider.translate('DDT Status'),
                  ddtDaysLeft < 0
                      ? languageProvider.translate('DDT has expired')
                      : '$ddtDaysLeft ${languageProvider.translate('days left')}',
                  isDarkMode,
                  LicenseDateProvider.getDaysLeftColor(ddtDaysLeft, isDarkMode),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      languageProvider.translate('Back'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, bool isDarkMode,
      [Color? textColor]) {
    bool isExpired =
        value.contains('expired'); // Check if the text contains 'expired'
    return Card(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      textColor ?? (isDarkMode ? Colors.white : Colors.black),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
            Expanded(
              child: isExpired
                  ? AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _blinkController
                              .value, // Control opacity to create blink
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor ??
                                  (isDarkMode ? Colors.white : Colors.black),
                            ),
                          ),
                        );
                      },
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor ??
                            (isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
