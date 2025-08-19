// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:driversapp/bank_details_page.dart';
// import 'package:driversapp/driver_rating_page.dart';
// import 'package:driversapp/home_page2.dart';
// import 'package:driversapp/incentive_received.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:back_button_interceptor/back_button_interceptor.dart';
// import 'data_provider.dart';
// import 'theme_provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:animate_do/animate_do.dart';

// class ProfilePage2 extends StatefulWidget {
//   const ProfilePage2({super.key});

//   @override
//   State<ProfilePage2> createState() => _ProfilePage2State();
// }

// class _ProfilePage2State extends State<ProfilePage2> {
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     BackButtonInterceptor.add(myInterceptor);
//   }

//   @override
//   void dispose() {
//     BackButtonInterceptor.remove(myInterceptor);
//     super.dispose();
//   }

//   bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
//     return true;
//   }

//   void refreshData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await Provider.of<DataProvider>(context, listen: false).fetchProfileData();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile data refreshed successfully!")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to refresh profile data: ${e.toString()}")),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Color getStarColor(double rating) {
//     if (rating >= 4.5) return Colors.green;
//     if (rating >= 3.0) return Colors.amber;
//     return Colors.red;
//   }

//   Color getAverageRatingScoreColor(double ratingScore) {
//     if (ratingScore >= 8) return Colors.green;
//     if (ratingScore >= 6) return Colors.amber;
//     return Colors.red;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final profileData = Provider.of<DataProvider>(context).profileData;
//     final languageProvider = Provider.of<LanguageProvider>(context);
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final cardBackgroundColor = themeProvider.isDarkMode ? Colors.grey[900] : Colors.white;
//     final fontColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final double imageSize = screenWidth * 0.35;

//     Uint8List? profileImage;
//     if (profileData != null && profileData['base64Image'] != null && profileData['base64Image'].isNotEmpty) {
//       try {
//         String base64String = profileData['base64Image'];
//         if (base64String.contains(',')) {
//           base64String = base64String.split(',').last;
//         }
//         base64String = base64String.trim();
//         profileImage = base64Decode(base64String);
//       } catch (_) {
//         profileImage = null;
//       }
//     }

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: themeProvider.isDarkMode
//                 ? [Colors.grey[900]!, Colors.grey[800]!]
//                 : [Colors.green[50]!, Colors.white],
//           ),
//         ),
//         child: SafeArea(
//           child: profileData == null
//               ? Center(
//                   child: Text(
//                     languageProvider.translate('No profile data available.'),
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       color: fontColor,
//                     ),
//                   ),
//                 )
//               : _isLoading
//                   ? Center(
//                       child: FadeIn(
//                         child: CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
//                         ),
//                       ),
//                     )
//                   : CustomScrollView(
//                       slivers: [
//                         SliverAppBar(
//                           expandedHeight: 200,
//                           floating: false,
//                           pinned: true,
//                           backgroundColor: Colors.green[700],
//                           flexibleSpace: FlexibleSpaceBar(
//                             title: Text(
//                               languageProvider.translate('Profile'),
//                               style: GoogleFonts.poppins(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             centerTitle: true,
//                             background: Stack(
//                               fit: StackFit.expand,
//                               children: [
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       colors: [Colors.green[700]!, Colors.green[400]!],
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                     ),
//                                   ),
//                                 ),
//                                 Center(
//                                   child: FadeInDown(
//                                     duration: Duration(milliseconds: 500),
//                                     child: Container(
//                                       width: imageSize,
//                                       height: imageSize,
//                                       decoration: BoxDecoration(
//                                         shape: BoxShape.circle,
//                                         border: Border.all(
//                                           color: Colors.green[300]!,
//                                           width: 4.0,
//                                         ),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300]!,
//                                             offset: Offset(2, 2),
//                                             blurRadius: 8,
//                                           ),
//                                           BoxShadow(
//                                             color: themeProvider.isDarkMode ? Colors.grey[900]! : Colors.white,
//                                             offset: Offset(-2, -2),
//                                             blurRadius: 8,
//                                           ),
//                                         ],
//                                         image: profileImage != null
//                                             ? DecorationImage(
//                                                 fit: BoxFit.cover,
//                                                 image: MemoryImage(profileImage),
//                                               )
//                                             : DecorationImage(
//                                                 fit: BoxFit.cover,
//                                                 image: AssetImage('assets/images/driverImage2.png'),
//                                               ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           actions: [
//                             IconButton(
//                               icon: Icon(Icons.refresh, color: Colors.white),
//                               onPressed: _isLoading ? null : refreshData,
//                             ),
//                           ],
//                         ),
//                         SliverToBoxAdapter(
//                           child: Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: FadeInUp(
//                               duration: Duration(milliseconds: 500),
//                               child: Card(
//                                 elevation: 8,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 color: cardBackgroundColor,
//                                 shadowColor: themeProvider.isDarkMode
//                                     ? Colors.black54
//                                     : Colors.grey[300],
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(20.0),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         languageProvider.translate('Driver Profile'),
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 22,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.green[700],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 16),
//                                       ProfileDetail(
//                                         icon: Icons.account_circle,
//                                         title: languageProvider.translate('SAP ID'),
//                                         value: profileData['sapId'].toString(),
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.person,
//                                         title: languageProvider.translate('Driver Name'),
//                                         value: profileData['driverName'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.badge,
//                                         title: languageProvider.translate('License Number'),
//                                         value: profileData['licenseNumber'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.calendar_today,
//                                         title: languageProvider.translate('License Expiry Date'),
//                                         value: profileData['licenseExpiryDate'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.local_shipping,
//                                         title: languageProvider.translate('Transporter Name'),
//                                         value: profileData['transporterName'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.phone,
//                                         title: languageProvider.translate('Mobile Number'),
//                                         value: profileData['mobileNumber'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.date_range,
//                                         title: languageProvider.translate('DDT Expiry Date'),
//                                         value: profileData['ddtExpiryDate'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       const SizedBox(height: 20),
//                                       Text(
//                                         languageProvider.translate('Safety Metrics'),
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 20,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.green[700],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       ProfileDetail(
//                                         icon: Icons.shield,
//                                         title: languageProvider.translate('Safety Status'),
//                                         value: profileData['safetyMetrics']?['safetyStatus'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.category,
//                                         title: languageProvider.translate('Safety Category'),
//                                         value: profileData['safetyMetrics']?['safetyCategory'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       const SizedBox(height: 20),
//                                       Text(
//                                         'Account Details',
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 20,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.green[700],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       ProfileDetail(
//                                         icon: Icons.person,
//                                         title: 'Account Name',
//                                         value: profileData['accountDetails']?['accountName'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.numbers,
//                                         title: 'Account Number',
//                                         value: profileData['accountDetails']?['accountNumber'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.account_balance,
//                                         title: 'Bank Name',
//                                         value: profileData['accountDetails']?['bankName'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       const SizedBox(height: 16),
//                                       FadeInUp(
//                                         duration: Duration(milliseconds: 600),
//                                         child: ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.green[700],
//                                             padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(30),
//                                             ),
//                                             elevation: 5,
//                                           ),
//                                           onPressed: () {
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder: (context) => const IncentivesReceived(),
//                                               ),
//                                             );
//                                           },
//                                           child: Text(
//                                             'Check Reward',
//                                             style: GoogleFonts.poppins(
//                                               color: Colors.white,
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Text(
//                                             'Edit account details?',
//                                             style: GoogleFonts.poppins(
//                                               fontWeight: FontWeight.w600,
//                                               color: fontColor,
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                           TextButton(
//                                             onPressed: () {
//                                               Navigator.push(
//                                                 context,
//                                                 MaterialPageRoute(
//                                                   builder: (context) => const BankDetailsPage(),
//                                                 ),
//                                               );
//                                             },
//                                             child: Text(
//                                               'Click here',
//                                               style: GoogleFonts.poppins(
//                                                 fontWeight: FontWeight.w600,
//                                                 color: Colors.green[700],
//                                                 fontSize: 14,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 20),
//                                       Text(
//                                         languageProvider.translate('Incentive Details'),
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 20,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.green[700],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       ProfileDetail(
//                                         icon: Icons.wallet_giftcard,
//                                         title: 'Credit Points',
//                                         value: profileData['incentiveWalletResponseDto']?['creditPointsEarned']?.toString() ?? '0',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       ProfileDetail(
//                                         icon: Icons.credit_score,
//                                         title: 'Last Credited',
//                                         value: profileData['incentiveWalletResponseDto']?['lastCredited'] ?? 'N/A',
//                                         iconColor: Colors.green[700]!,
//                                       ),
//                                       const SizedBox(height: 20),
//                                       Text(
//                                         languageProvider.translate('Rating'),
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 20,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.green[700],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       Row(
//                                         children: [
//                                           Row(
//                                             children: List.generate(5, (index) {
//                                               final color = getStarColor(
//                                                 double.tryParse(
//                                                       profileData['averageRatingInStars']?.toString() ?? '0.0') ?? 0.0,
//                                               );
//                                               return FadeInRight(
//                                                 duration: Duration(milliseconds: 300 + (index * 100)),
//                                                 child: Icon(
//                                                   Icons.star,
//                                                   color: (index + 1) <=
//                                                           (double.tryParse(profileData['averageRatingInStars']?.toString() ?? '0.0') ?? 0.0)
//                                                       ? color
//                                                       : Colors.grey[400],
//                                                   size: 28,
//                                                 ),
//                                               );
//                                             }),
//                                           ),
//                                           const SizedBox(width: 10),
//                                           Text(
//                                             '(${double.tryParse(profileData['averageRatingInStars']?.toString() ?? '0.0')})',
//                                             style: GoogleFonts.poppins(
//                                               fontWeight: FontWeight.w600,
//                                               color: Colors.grey[600],
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 12),
//                                       Text(
//                                         '${languageProvider.translate('Average Rating Score')}: ${double.tryParse(profileData['averageRatingScore']?.toString() ?? '0.0')}',
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600,
//                                           color: getAverageRatingScoreColor(
//                                             double.tryParse(profileData['averageRatingScore']?.toString() ?? '0.0') ?? 0.0,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 24),
//                                       Center(
//                                         child: Row(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             FadeInUp(
//                                               duration: Duration(milliseconds: 700),
//                                               child: ElevatedButton(
//                                                 onPressed: () {
//                                                   Navigator.push(
//                                                     context,
//                                                     MaterialPageRoute(
//                                                       builder: (context) => const HomePage2(),
//                                                     ),
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                   backgroundColor: Colors.green[700],
//                                                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius: BorderRadius.circular(30),
//                                                   ),
//                                                   elevation: 5,
//                                                 ),
//                                                 child: Text(
//                                                   languageProvider.translate('Home'),
//                                                   style: GoogleFonts.poppins(
//                                                     fontSize: 16,
//                                                     color: Colors.white,
//                                                     fontWeight: FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(width: 16),
//                                             FadeInUp(
//                                               duration: Duration(milliseconds: 800),
//                                               child: ElevatedButton(
//                                                 onPressed: () {
//                                                   Navigator.push(
//                                                     context,
//                                                     MaterialPageRoute(
//                                                       builder: (context) => StarRatingPage(),
//                                                     ),
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                   backgroundColor: Colors.green[700],
//                                                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius: BorderRadius.circular(30),
//                                                   ),
//                                                   elevation: 5,
//                                                 ),
//                                                 child: Text(
//                                                   languageProvider.translate('Rating'),
//                                                   style: GoogleFonts.poppins(
//                                                     fontSize: 16,
//                                                     color: Colors.white,
//                                                     fontWeight: FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//         ),
//       ),
//     );
//   }
// }

// class ProfileDetail extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String value;
//   final Color iconColor;

//   const ProfileDetail({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.value,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final fontColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;

//     return FadeInUp(
//       duration: Duration(milliseconds: 400),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.grey[100],
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300]!,
//               offset: Offset(2, 2),
//               blurRadius: 4,
//             ),
//             BoxShadow(
//               color: themeProvider.isDarkMode ? Colors.grey[900]! : Colors.white,
//               offset: Offset(-2, -2),
//               blurRadius: 4,
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: iconColor, size: 28),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: fontColor,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     value,
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'dart:typed_data';
import 'package:driversapp/bank_details_page.dart';
import 'package:driversapp/driver_rating_page.dart';
import 'package:driversapp/home_page2.dart';
import 'package:driversapp/incentive_received.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'data_provider.dart';
import 'theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ProfilePage2 extends StatefulWidget {
  const ProfilePage2({super.key});

  @override
  State<ProfilePage2> createState() => _ProfilePage2State();
}

class _ProfilePage2State extends State<ProfilePage2> {
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
  

  void refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<DataProvider>(context, listen: false).fetchProfileData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile data refreshed successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to refresh profile data: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color getStarColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.0) return Colors.amber;
    return Colors.red;
  }

  Color getAverageRatingScoreColor(double ratingScore) {
    if (ratingScore >= 8) return Colors.green;
    if (ratingScore >= 6) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final profileData = Provider.of<DataProvider>(context).profileData;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardBackgroundColor = themeProvider.isDarkMode ? Colors.grey[900] : Colors.white;
    final fontColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
    final screenWidth = MediaQuery.of(context).size.width;
    final double imageSize = screenWidth * 0.35;

    Uint8List? profileImage;
    if (profileData != null && profileData['base64Image'] != null && profileData['base64Image'].isNotEmpty) {
      try {
        String base64String = profileData['base64Image'];
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        base64String = base64String.trim();
        profileImage = base64Decode(base64String);
      } catch (_) {
        profileImage = null;
      }
    }

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
                      color: fontColor,
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
                          expandedHeight: 200,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.green[700],
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              languageProvider.translate('Profile'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            centerTitle: true,
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.green[700]!, Colors.green[400]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: FadeInDown(
                                    duration: Duration(milliseconds: 500),
                                    child: Container(
                                      width: imageSize,
                                      height: imageSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.green[300]!,
                                          width: 4.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300]!,
                                            offset: Offset(2, 2),
                                            blurRadius: 8,
                                          ),
                                          BoxShadow(
                                            color: themeProvider.isDarkMode ? Colors.grey[900]! : Colors.white,
                                            offset: Offset(-2, -2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                        image: profileImage != null
                                            ? DecorationImage(
                                                fit: BoxFit.cover,
                                                image: MemoryImage(profileImage),
                                              )
                                            : DecorationImage(
                                                fit: BoxFit.cover,
                                                image: AssetImage('assets/images/driverImage2.png'),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(Icons.refresh, color: Colors.white),
                              onPressed: _isLoading ? null : refreshData,
                            ),
                          ],
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: FadeInUp(
                              duration: Duration(milliseconds: 500),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                color: cardBackgroundColor,
                                shadowColor: themeProvider.isDarkMode
                                    ? Colors.black54
                                    : Colors.grey[300],
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        languageProvider.translate('Driver Profile'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ProfileDetail(
                                        icon: Icons.account_circle,
                                        title: languageProvider.translate('SAP ID'),
                                        value: profileData['sapId'].toString(),
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.person,
                                        title: languageProvider.translate('Driver Name'),
                                        value: profileData['driverName'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.badge,
                                        title: languageProvider.translate('License Number'),
                                        value: profileData['licenseNumber'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.calendar_today,
                                        title: languageProvider.translate('License Expiry Date'),
                                        value: profileData['licenseExpiryDate'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.local_shipping,
                                        title: languageProvider.translate('Transporter Name'),
                                        value: profileData['transporterName'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.phone,
                                        title: languageProvider.translate('Mobile Number'),
                                        value: profileData['mobileNumber'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.date_range,
                                        title: languageProvider.translate('DDT Expiry Date'),
                                        value: profileData['ddtExpiryDate'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        languageProvider.translate('Safety Metrics'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ProfileDetail(
                                        icon: Icons.shield,
                                        title: languageProvider.translate('Safety Status'),
                                        value: profileData['safetyMetrics']?['safetyStatus'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.category,
                                        title: languageProvider.translate('Safety Category'),
                                        value: profileData['safetyMetrics']?['safetyCategory'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Account Details',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ProfileDetail(
                                        icon: Icons.person,
                                        title: 'Account Name',
                                        value: profileData['accountDetails']?['accountName'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.numbers,
                                        title: 'Account Number',
                                        value: profileData['accountDetails']?['accountNumber'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.account_balance,
                                        title: 'Bank Name',
                                        value: profileData['accountDetails']?['bankName'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      const SizedBox(height: 16),
                                      FadeInUp(
                                        duration: Duration(milliseconds: 600),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            elevation: 5,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const IncentivesReceived(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Check Reward',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Edit account details?',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: fontColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const BankDetailsPage(),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Click here',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        languageProvider.translate('Incentive Details'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ProfileDetail(
                                        icon: Icons.wallet_giftcard,
                                        title: 'Credit Points',
                                        value: profileData['incentiveWalletResponseDto']?['creditPointsEarned']?.toString() ?? '0',
                                        iconColor: Colors.grey[600]!,
                                      ),
                                      ProfileDetail(
                                        icon: Icons.credit_score,
                                        title: 'Last Credited',
                                        value: profileData['incentiveWalletResponseDto']?['lastCredited'] ?? 'N/A',
                                        iconColor: Colors.green[700]!,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        languageProvider.translate('Rating'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Row(
                                            children: List.generate(5, (index) {
                                              final color = getStarColor(
                                                double.tryParse(
                                                      profileData['averageRatingInStars']?.toString() ?? '0.0') ?? 0.0,
                                              );
                                              return FadeInRight(
                                                duration: Duration(milliseconds: 300 + (index * 100)),
                                                child: Icon(
                                                  Icons.star,
                                                  color: (index + 1) <=
                                                          (double.tryParse(profileData['averageRatingInStars']?.toString() ?? '0.0') ?? 0.0)
                                                      ? color
                                                      : themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[400],
                                                  size: 28,
                                                ),
                                              );
                                            }),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '(${double.tryParse(profileData['averageRatingInStars']?.toString() ?? '0.0')})',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${languageProvider.translate('Average Rating Score')}: ${double.tryParse(profileData['averageRatingScore']?.toString() ?? '0.0')}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: getAverageRatingScoreColor(
                                            double.tryParse(profileData['averageRatingScore']?.toString() ?? '0.0') ?? 0.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            FadeInUp(
                                              duration: Duration(milliseconds: 700),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => const HomePage2(),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green[700],
                                                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  elevation: 5,
                                                ),
                                                child: Text(
                                                  languageProvider.translate('Home'),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            FadeInUp(
                                              duration: Duration(milliseconds: 800),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => StarRatingPage(),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green[700],
                                                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  elevation: 5,
                                                ),
                                                child: Text(
                                                  languageProvider.translate('Rating'),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
}

class ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const ProfileDetail({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;

    return FadeInUp(
      duration: Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fontColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}