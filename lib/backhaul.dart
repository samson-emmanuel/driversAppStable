// ignore_for_file: use_build_context_synchronously, sized_box_for_whitespace, deprecated_member_use, unused_shown_name

import 'package:driversapp/widgets/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'dart:math' show asin, cos, max, min, sqrt;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data_provider.dart'; // Import your DataProvider
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:location/location.dart'; // For accessing the user's location

class BackHauling extends StatefulWidget {
  const BackHauling({super.key});

  @override
  _BackHaulingState createState() => _BackHaulingState();
}

class _BackHaulingState extends State<BackHauling> {
  bool showDetails = false;
  bool isLoading = false; // To handle button loading state
  bool isDataLoaded = false; // To track if data has been loaded
  GoogleMapController? mapController;
  Location location = Location();
  LatLng? currentLocation; // Variable to store the current location

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String? assignmentStatus; // To store the fetched assignmentStatus
  String? assignmentId; // To store the fetched assignmentId

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    return false;
  }

  @override
  void initState() {
    super.initState();

    // Fetch assignments data and initialize status and id when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAssignmentData();
      // Fetch the user's current location
      _getUserLocation();
    });

    BackButtonInterceptor.add(myInterceptor);
    initializeMapRenderer();
  }

  Future<void> _fetchAssignmentData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.fetchAssignments();
    setState(() {
      if (dataProvider.assignmentsData != null &&
          dataProvider.assignmentsData!.isNotEmpty) {
        assignmentStatus = dataProvider.assignmentsData![0]['assignmentStatus'];
        assignmentId = dataProvider.assignmentsData![0]['id'].toString();
      } else {
        assignmentStatus = null;
        assignmentId = null;
      }
      isDataLoaded = true;
    });
    // print('Shipment Status: $assignmentStatus');
    // _setMarkers();
    // _getRoute();
  }

  Future<void> _getUserLocation() async {
    // Check if location service is enabled and permissions are granted
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get the current location of the user
    final LocationData _locationData = await location.getLocation();
    print(_locationData.latitude);
    print(_locationData.longitude);
    setState(() {
      currentLocation = LatLng(
        _locationData.latitude!,
        _locationData.longitude!,
      );
    });
    _setMarkers();
    _getRoute();
  }

  Future<void> _refreshData() async {
    setState(() {
      isDataLoaded = false; // Reset data loading state
    });
    await _fetchAssignmentData();
  }

  // Fetch and update data using Provider
  void _setMarkers() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final backHaulOrder = dataProvider.assignmentsData?[0]['backHaulOrder'];

    if (backHaulOrder == null) return;

    final LatLng loadingPoint = LatLng(
      backHaulOrder['pickupLat'] ?? 0.0,
      backHaulOrder['pickupLng'] ?? 0.0,
    );

    final LatLng unloadingPoint = LatLng(
      backHaulOrder['dropOffLat'] ?? 0.0,
      backHaulOrder['dropOffLng'] ?? 0.0,
    );

    _markers = {
      Marker(
        markerId: const MarkerId('loading'),
        position: loadingPoint,
        infoWindow: InfoWindow(
          title: 'Loading Point',
          snippet: backHaulOrder['pickupLocation'] ?? '',
        ),
      ),
      Marker(
        markerId: const MarkerId('unloading'),
        position: unloadingPoint,
        infoWindow: InfoWindow(
          title: 'Unloading Point',
          snippet: backHaulOrder['dropOffLocation'] ?? '',
        ),
      ),
    };

    // Add marker for the user's current location, if available
    if (currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLocation!,
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  Future<void> _getRoute() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final backHaulOrder = dataProvider.assignmentsData?[0]['backHaulOrder'];

    if (backHaulOrder == null) return;

    final LatLng loadingPoint = LatLng(
      backHaulOrder['pickupLat'] ?? 0.0,
      backHaulOrder['pickupLng'] ?? 0.0,
    );

    final LatLng unloadingPoint = LatLng(
      backHaulOrder['dropOffLat'] ?? 0.0,
      backHaulOrder['dropOffLng'] ?? 0.0,
    );

    const String apiKey =
        // 'AIzaSyAipKhzBOBtcfRmBs7ahqWg2X8O0YLC4qY';
        'AIzaSyCeq9xe-BqupyZzHWltXzGEmacVt9dAYj0';

    // Get the polyline for the route from loading point to unloading point
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${loadingPoint.latitude},${loadingPoint.longitude}&destination=${unloadingPoint.latitude},${unloadingPoint.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String encodedPolyline =
            data['routes'][0]['overview_polyline']['points'];
        final List<LatLng> routePoints = _decodePolyline(encodedPolyline);

        setState(() {
          // Polyline from loading point to unloading point in blue
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route1'),
              visible: true,
              points: routePoints,
              color: Colors.blue, // Color for the loading to unloading route
              width: 5,
            ),
          );
        });
      } else {
        print('Failed to load directions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }

    // Now add the polyline from the current location to the loading point
    if (currentLocation != null) {
      final String currentToLoadingUrl =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation!.latitude},${currentLocation!.longitude}&destination=${loadingPoint.latitude},${loadingPoint.longitude}&key=$apiKey';

      try {
        final response = await http.get(Uri.parse(currentToLoadingUrl));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final String encodedPolyline =
              data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> currentToLoadingPoints = _decodePolyline(
            encodedPolyline,
          );

          setState(() {
            // Polyline from current location to loading point in red
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route2'),
                visible: true,
                points: currentToLoadingPoints,
                color: Colors.red, // Color for the current to loading route
                width: 5,
              ),
            );
          });
          print('Polyline from current location to loading added.');
        } else {
          print(
            'Failed to load current to loading directions: ${response.statusCode}',
          );
        }
      } catch (e) {
        print('Error fetching route from current to loading: $e');
      }
    } else {
      print('Current location is null.');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _updateAssignmentStatus(
    String status,
    String assignmentId,
    String role,
  ) async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    // Retrieve token from DataProvider
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String? token = dataProvider.token; // Get the token from DataProvider

    if (token == null || token.isEmpty) {
      _showPopup('Error', 'Token is missing. Please login again.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    const url =
        'https://staging-812204315267.us-central1.run.app/assignment/update';
    // const url = 'http://driverappservice.lapapps.ng:5124/assignment/update';
    final body = jsonEncode({
      "status": status,
      "assignmentId": assignmentId,
      "role": role,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        _showPopup('Thank You', 'The status has been updated to $status');
        _fetchAssignmentData();
      } else {
        _showPopup('Error', 'Failed to update status. Try again.');
      }
    } catch (e) {
      _showPopup('Error', 'Failed to update status. Check your network.');
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _zoomToFitMarkers(LatLng loadingPoint, LatLng unloadingPoint) {
    if (_markers.isEmpty) return;

    LatLngBounds bounds = _createLatLngBounds(loadingPoint, unloadingPoint);
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _createLatLngBounds(LatLng point1, LatLng point2) {
    return LatLngBounds(
      southwest: LatLng(
        min(point1.latitude, point2.latitude),
        min(point1.longitude, point2.longitude),
      ),
      northeast: LatLng(
        max(point1.latitude, point2.latitude),
        max(point1.longitude, point2.longitude),
      ),
    );
  }

  void _showMapPopup(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final backHaulOrder = dataProvider.assignmentsData?[0]['backHaulOrder'];

    if (backHaulOrder == null) {
      print('No backhaul data available');
      return;
    }

    final LatLng loadingPoint = LatLng(
      backHaulOrder['pickupLat'] ?? 0.0,
      backHaulOrder['pickupLng'] ?? 0.0,
    );

    final LatLng unloadingPoint = LatLng(
      backHaulOrder['dropOffLat'] ?? 0.0,
      backHaulOrder['dropOffLng'] ?? 0.0,
    );

    await initializeMapRenderer();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height:
                MediaQuery.of(context).size.height * 0.8, // Adjust as needed
            width: MediaQuery.of(context).size.width * 0.9, // Adjust as needed
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                _zoomToFitMarkers(loadingPoint, unloadingPoint);
              },
              initialCameraPosition: CameraPosition(
                target: loadingPoint,
                zoom: 12.0,
              ),
              markers: _markers,
              polylines: _polylines,
              scrollGesturesEnabled: true, // Enable map panning
              zoomGesturesEnabled: true, // Enable zooming
              rotateGesturesEnabled: true, // Enable rotation
              tiltGesturesEnabled: true, // Enable tilting
              myLocationEnabled: true, // Show user's location
              myLocationButtonEnabled: true, // Button for current location
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Backhaul Transport',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor:
            themeProvider.isDarkMode ? Colors.green[800] : Colors.green,
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body:
          isDataLoaded
              ? (dataProvider.assignmentsData == null ||
                      dataProvider.assignmentsData!.isEmpty)
                  ? Center(
                    child: Text(
                      'No backhaul assignments \n available at the moment.',
                      style: TextStyle(
                        fontSize: 18,
                        color:
                            themeProvider.isDarkMode
                                ? Colors.grey[300]
                                : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showDetails = !showDetails;
                              });
                            },
                            child: Card(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.green[900]
                                      : Colors.green[100],
                              margin: const EdgeInsets.all(16.0),
                              child: ListTile(
                                leading: Icon(
                                  Icons.local_shipping,
                                  color:
                                      themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                ),
                                title: Text(
                                  '${dataProvider.assignmentsData?[0]['backHaulOrder']['customerName']}',
                                  style: TextStyle(
                                    color:
                                        themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  'From: ${dataProvider.assignmentsData?[0]['backHaulOrder']['pickupLocation']} → To: ${dataProvider.assignmentsData?[0]['backHaulOrder']['dropOffLocation']}\n${DateFormat('dd MMM, hh:mm a').format(DateTime.parse(dataProvider.assignmentsData?[0]['backHaulOrder']['orderDate']))}',
                                  style: TextStyle(
                                    color:
                                        themeProvider.isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: showDetails,
                            child: Container(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.green[800]?.withOpacity(0.1)
                                      : Colors.green[50],
                              padding: const EdgeInsets.all(16.0),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You have been assigned a backhaul transport',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Material Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Type: ${dataProvider.assignmentsData?[0]['backHaulOrder']['materialType']}',
                                    style: TextStyle(
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Quantity: ${dataProvider.assignmentsData?[0]['backHaulOrder']['quantityAssigned']} Tonnes',
                                    style: TextStyle(
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Original Quantity: ${dataProvider.assignmentsData?[0]['backHaulOrder']['originalQuantity']} Tonnes',
                                    style: TextStyle(
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Locations',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _showMapPopup(context);
                                    },
                                    child: Text(
                                      'Loading: ${dataProvider.assignmentsData?[0]['backHaulOrder']['pickupLocation']}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _showMapPopup(context);
                                    },
                                    child: Text(
                                      'Unloading: ${dataProvider.assignmentsData?[0]['backHaulOrder']['dropOffLocation']}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Customer Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Customer Phone Number: ${dataProvider.assignmentsData?[0]['backHaulOrder']['customerNumber']}',
                                    style: TextStyle(
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Name of Customer: ${dataProvider.assignmentsData?[0]['backHaulOrder']['customerName']}',
                                    style: TextStyle(
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Buttons for assignment status
                                  if (assignmentStatus ==
                                      'AWAITING_CONFIRMATION')
                                    isLoading
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                themeProvider.isDarkMode
                                                    ? Colors.green[800]
                                                    : Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed:
                                              () => _updateAssignmentStatus(
                                                'ACKNOWLEDGED',
                                                assignmentId!,
                                                'DRIVER',
                                              ),
                                          child: const Text('Acknowledge'),
                                        ),
                                  if (assignmentStatus == 'ACKNOWLEDGED')
                                    isLoading
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                themeProvider.isDarkMode
                                                    ? Colors.orange[800]
                                                    : Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed:
                                              () => _updateAssignmentStatus(
                                                'AWAITING_PICKUP',
                                                assignmentId!,
                                                'DRIVER',
                                              ),
                                          child: const Text('Awaiting Pickup'),
                                        ),
                                  if (assignmentStatus == 'AWAITING_PICKUP')
                                    isLoading
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                themeProvider.isDarkMode
                                                    ? Color.fromARGB(
                                                      255,
                                                      27,
                                                      50,
                                                      108,
                                                    )
                                                    : Color.fromARGB(
                                                      255,
                                                      27,
                                                      50,
                                                      108,
                                                    ),
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed:
                                              () => _updateAssignmentStatus(
                                                'IN_TRANSIT',
                                                assignmentId!,
                                                'DRIVER',
                                              ),
                                          child: const Text('In Transit'),
                                        ),
                                  if (assignmentStatus == 'IN_TRANSIT')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            themeProvider.isDarkMode
                                                ? Color.fromARGB(255, 93, 9, 55)
                                                : Color.fromARGB(
                                                  255,
                                                  93,
                                                  9,
                                                  55,
                                                ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed:
                                          () => _updateAssignmentStatus(
                                            'OFFLOADING',
                                            assignmentId!,
                                            'DRIVER',
                                          ),
                                      child: const Text('Off Loading'),
                                    ),
                                  if (assignmentStatus == 'OFFLOADING')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            themeProvider.isDarkMode
                                                ? Color.fromARGB(
                                                  255,
                                                  42,
                                                  115,
                                                  18,
                                                )
                                                : Color.fromARGB(
                                                  255,
                                                  42,
                                                  115,
                                                  18,
                                                ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed:
                                          assignmentStatus == 'COMPLETED'
                                              ? null // This disables the button
                                              : () => _updateAssignmentStatus(
                                                'COMPLETED',
                                                assignmentId!,
                                                'DRIVER',
                                              ),
                                      child: const Text('Completed'),
                                    ),
                                  if (assignmentStatus == 'COMPLETED')
                                    const Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 13, 64, 15),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
              : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }

  Future<void> initializeMapRenderer() async {
    try {
      final GoogleMapsFlutterPlatform mapsImplementation =
          GoogleMapsFlutterPlatform.instance;
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        await mapsImplementation.initializeWithRenderer(
          AndroidMapRenderer.latest,
        );
      }
    } catch (e) {
      print('Error initializing map renderer: $e');
    }
  }
}
