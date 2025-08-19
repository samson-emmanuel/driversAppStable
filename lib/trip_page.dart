import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_provider.dart';
import 'theme_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'widgets/bottom_navigation.dart';

class TripPage extends StatefulWidget {
  const TripPage({super.key});

  @override
  _TripPageState createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _last100Days = true;

  @override
  void initState() {
    super.initState();
    _loadCachedTrips();
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

  Future<void> _loadCachedTrips() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mixId = dataProvider.profileData?['mixDriverId'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _last100Days ? 'last10Trips_$mixId' : 'monthlyTrips_$mixId';

    try {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final List<dynamic> cachedTrips = jsonDecode(cachedData);
        setState(() {
          _trips = cachedTrips.map((trip) => Trip.fromJson(trip)).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Error loading cached trips: $e');
    }

    // If no cached data, fetch from API
    await _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mixId = dataProvider.profileData?['mixDriverId'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _last100Days ? 'last10Trips_$mixId' : 'monthlyTrips_$mixId';

    try {
      final response = _last100Days
          ? await dataProvider.fetch10Trips(mixId, last1000Days: true)
          : await dataProvider.fetchTrips(mixId, last100Days: false);

      final trips = (response['result']['shipmentData'] as List<dynamic>)
          .map((trip) => Trip.fromJson(trip))
          .toList();

      // Cache the trip data
      await prefs.setString(cacheKey, jsonEncode(response['result']['shipmentData']));

      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching trips: $e';
      });
    }
  }

  void _showTripDetails(BuildContext context, Trip trip) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = screenWidth * 0.04;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: themeProvider.isDarkMode
                    ? [Colors.grey[900]!, Colors.grey[850]!]
                    : [Colors.green[50]!, Colors.white],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    duration: Duration(milliseconds: 300),
                    child: Text(
                      'Trip Details',
                      style: GoogleFonts.poppins(
                        fontSize: baseFontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: Duration(milliseconds: 350),
                    child: _buildDetailRow('Customer Name', trip.customerName, baseFontSize, themeProvider),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 400),
                    child: _buildDetailRow('Ship To Address', trip.shipToAddress, baseFontSize, themeProvider),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 450),
                    child: _buildDetailRow('Logon', trip.logon, baseFontSize, themeProvider),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 500),
                    child: _buildDetailRow('Quantity', trip.quantity.toString(), baseFontSize, themeProvider),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 550),
                    child: _buildDetailRow('Dispatch Date', _formatDate(trip.dispatchDate), baseFontSize, themeProvider),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 600),
                    child: _buildDetailRow('Lead Time SLA', trip.leadTimeSla, baseFontSize, themeProvider),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 650),
                    child: _buildDetailRow('Last Updated', _formatDate(trip.lastUpdated), baseFontSize, themeProvider),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 700),
                    child: _buildDetailRow('Driver Name', trip.driverName, baseFontSize, themeProvider),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: Duration(milliseconds: 750),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: baseFontSize,
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
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, double baseFontSize, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '$title: ',
              style: GoogleFonts.poppins(
                fontSize: baseFontSize,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: baseFontSize,
                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = screenWidth * 0.04;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
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
            child: RefreshIndicator(
              onRefresh: _fetchTrips,
              color: Colors.green[700],
              backgroundColor: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[700]!, Colors.green[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300]!,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Trips',
                          style: GoogleFonts.poppins(
                            fontSize: baseFontSize + 4,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FadeInUp(
                            duration: Duration(milliseconds: 300),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _last100Days = true;
                                  _isLoading = true;
                                  _fetchTrips();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _last100Days ? Colors.green[700] : (themeProvider.isDarkMode ? Colors.grey[850] : Colors.grey[300]),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                                shadowColor: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300],
                              ),
                              child: Text(
                                'Last 10 Trips',
                                style: GoogleFonts.poppins(
                                  fontSize: baseFontSize,
                                  color: _last100Days ? Colors.white : (themeProvider.isDarkMode ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          FadeInUp(
                            duration: Duration(milliseconds: 400),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _last100Days = false;
                                  _isLoading = true;
                                  _fetchTrips();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_last100Days ? Colors.green[700] : (themeProvider.isDarkMode ? Colors.grey[850] : Colors.grey[300]),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                                shadowColor: themeProvider.isDarkMode ? Colors.black54 : Colors.grey[300],
                              ),
                              child: Text(
                                'This Month',
                                style: GoogleFonts.poppins(
                                  fontSize: baseFontSize,
                                  color: !_last100Days ? Colors.white : (themeProvider.isDarkMode ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: FadeIn(
                                duration: Duration(milliseconds: 300),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                                ),
                              ),
                            ),
                          )
                        : _errorMessage != null
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: FadeInUp(
                                    duration: Duration(milliseconds: 300),
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(
                                        fontSize: baseFontSize + 2,
                                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : _trips.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: FadeInUp(
                                        duration: Duration(milliseconds: 300),
                                        child: Text(
                                          'No Trip Details Yet',
                                          style: GoogleFonts.poppins(
                                            fontSize: baseFontSize + 2,
                                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: _trips.length,
                                    itemBuilder: (context, index) {
                                      final trip = _trips[index];
                                      return FadeInUp(
                                        duration: Duration(milliseconds: 300 + (index * 100)),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
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
                                            contentPadding: EdgeInsets.all(16),
                                            leading: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.local_shipping,
                                                color: Colors.green[700],
                                                size: 24,
                                              ),
                                            ),
                                            title: Text(
                                              'Customer: ${trip.customerName}',
                                              style: GoogleFonts.poppins(
                                                fontSize: baseFontSize + 2,
                                                fontWeight: FontWeight.bold,
                                                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Ship To: ${trip.shipToAddress}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: baseFontSize,
                                                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Dispatch: ${_formatDate(trip.dispatchDate)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: baseFontSize,
                                                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Driver: ${trip.driverName}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: baseFontSize,
                                                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            trailing: Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Colors.green[700],
                                            ),
                                            onTap: () => _showTripDetails(context, trip),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavigation(currentIndex: 1),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('EEEE, MMMM d, yyyy h:mm a')
          .format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }
}

class Trip {
  final String customerName;
  final String shipToAddress;
  final String logon;
  final double quantity;
  final String dispatchDate;
  final String leadTimeSla;
  final String lastUpdated;
  final String driverName;

  Trip({
    required this.customerName,
    required this.shipToAddress,
    required this.logon,
    required this.quantity,
    required this.dispatchDate,
    required this.leadTimeSla,
    required this.lastUpdated,
    required this.driverName,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      customerName: json['customerName'],
      shipToAddress: json['shipToAddress'] ?? 'N/A',
      logon: json['logon'],
      quantity: json['quantity'].toDouble(),
      dispatchDate: json['dispatchDate'],
      leadTimeSla: json['leadTimeSla'] ?? 'N/A',
      lastUpdated: json['lastUpdated'] ?? 'N/A',
      driverName: json['driverName'] ?? 'N/A',
    );
  }
}