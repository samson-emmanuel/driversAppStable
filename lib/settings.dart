import 'package:driversapp/driver_qr_code.dart';
import 'package:driversapp/welcome_screen2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'data_provider.dart';
import 'theme_provider.dart';
import '../widgets/bottom_navigation.dart';
import 'package:http/http.dart' as http;
import 'licence_page.dart';
import 'profile_page2.dart';
import 'auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

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

  void _logout(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final token = dataProvider.token;
    final authService = AuthService();

    if (token != null && token.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://staging-812204315267.us-central1.run.app/profile/logout',
        );
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'app-version': '1.12',
            'app-name': 'drivers app',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 400) {
          await _clearData(context, dataProvider, authService);
        } else if (response.statusCode == 401) {
          await _clearData(context, dataProvider, authService);
        } else {
          print('Logout failed: ${response.statusCode} - ${response.reasonPhrase}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout failed: Please try again.')),
          );
        }
      } catch (e) {
        print('Logout failed with exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout failed: Network error.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      await _clearData(context, dataProvider, authService);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData(
    BuildContext context,
    DataProvider dataProvider,
    AuthService authService,
  ) async {
    await authService.clearStorage();
    dataProvider.setToken('');
    dataProvider.setMixId('');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen2()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileData = Provider.of<DataProvider>(context).profileData;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final double baseFontSize = screenWidth * 0.04;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeProvider.isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: profileData == null
              ? Center(
                  child: Text(
                    languageProvider.translate('No profile data available.'),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                )
              : _isLoading
                  ? Center(
                      child: FadeIn(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                        ),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 150,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.green[700],
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              languageProvider.translate('Settings'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: baseFontSize + 2,
                              ),
                            ),
                            centerTitle: true,
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green[700]!, Colors.green[400]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeInUp(
                                  duration: Duration(milliseconds: 500),
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                                    shadowColor: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300],
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profileData['driverName'] ?? 'N/A',
                                            style: GoogleFonts.poppins(
                                              fontSize: baseFontSize + 4,
                                              fontWeight: FontWeight.bold,
                                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  languageProvider.translate('Phone Number'),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: baseFontSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.black54,
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  profileData['mobileNumber'] ?? 'N/A',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: baseFontSize,
                                                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                                    
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  languageProvider.translate('Transporter Name'),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: baseFontSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.black54,
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  profileData['transporterName'] ?? 'N/A',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: baseFontSize,
                                                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                                                                                     ),
                                                  textAlign: TextAlign.right,
                                                  overflow: TextOverflow.visible,
 
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  languageProvider.translate('Settings'),
                                  style: GoogleFonts.poppins(
                                    fontSize: baseFontSize + 4,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FadeInUp(
                                  duration: Duration(milliseconds: 600),
                                  child: _buildSettingTile(
                                    context,
                                    icon: Icons.dark_mode,
                                    title: languageProvider.translate('Dark Mode'),
                                    trailing: Switch(
                                      value: themeProvider.isDarkMode,
                                      onChanged: (value) {
                                        themeProvider.toggleTheme();
                                      },
                                      activeColor: Colors.green[700],
                                    ),
                                  ),
                                ),
                                FadeInUp(
                                  duration: Duration(milliseconds: 700),
                                  child: _buildSettingTile(
                                    context,
                                    icon: Icons.language_sharp,
                                    title: languageProvider.translate('Language'),
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        builder: (BuildContext context) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FadeInUp(
                                                duration: Duration(milliseconds: 300),
                                                child: ListTile(
                                                  leading: Icon(Icons.language, color: Colors.green[700]),
                                                  title: Text(
                                                    'English',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: baseFontSize,
                                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    languageProvider.loadLanguage('en');
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                                              FadeInUp(
                                                duration: Duration(milliseconds: 350),
                                                child: ListTile(
                                                  leading: Icon(Icons.language, color: Colors.green[700]),
                                                  title: Text(
                                                    'Hausa',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: baseFontSize,
                                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    languageProvider.loadLanguage('ha');
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                                              FadeInUp(
                                                duration: Duration(milliseconds: 400),
                                                child: ListTile(
                                                  leading: Icon(Icons.language, color: Colors.green[700]),
                                                  title: Text(
                                                    'Pidgin',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: baseFontSize,
                                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    languageProvider.loadLanguage('pi');
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                                              FadeInUp(
                                                duration: Duration(milliseconds: 450),
                                                child: ListTile(
                                                  leading: Icon(Icons.language, color: Colors.green[700]),
                                                  title: Text(
                                                    'Igbo',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: baseFontSize,
                                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    languageProvider.loadLanguage('ig');
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                                              FadeInUp(
                                                duration: Duration(milliseconds: 500),
                                                child: ListTile(
                                                  leading: Icon(Icons.language, color: Colors.green[700]),
                                                  title: Text(
                                                    'Yoruba',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: baseFontSize,
                                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    languageProvider.loadLanguage('yo');
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                FadeInUp(
                                  duration: Duration(milliseconds: 800),
                                  child: _buildSettingTile(
                                    context,
                                    icon: Icons.badge,
                                    title: languageProvider.translate('Licence'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LicencePage()),
                                      );
                                    },
                                  ),
                                ),
                                FadeInUp(
                                  duration: Duration(milliseconds: 900),
                                  child: _buildSettingTile(
                                    context,
                                    icon: Icons.person,
                                    title: languageProvider.translate('Profile'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ProfilePage2()),
                                      );
                                    },
                                  ),
                                ),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  child: _buildSettingTile(
                                    context,
                                    icon: Icons.qr_code_2_sharp,
                                    title: languageProvider.translate('Your QR Code'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const QRCodeScreen()),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1100),
                                  child: Center(
                                    child: ElevatedButton(
                                      onPressed: () => _logout(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 5,
                                      ),
                                      child: Text(
                                        languageProvider.translate('Log Out'),
                                        style: GoogleFonts.poppins(
                                          fontSize: baseFontSize + 2,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 5),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final double baseFontSize = screenWidth * 0.04;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300]!,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.grey[900]! : Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green[700], size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: baseFontSize,
            fontWeight: FontWeight.w600,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, color: Colors.green[700], size: 20),
        onTap: onTap,
      ),
    );
  }
}