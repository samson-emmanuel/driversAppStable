// ignore_for_file: library_private_types_in_public_api

import 'package:driversapp/data_provider.dart';
import 'package:driversapp/theme_provider.dart';
import 'package:driversapp/widgets/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:async';

class CurrentTrip extends StatefulWidget {
  const CurrentTrip({super.key});

  @override
  _CurrentTripState createState() => _CurrentTripState();
}

class _CurrentTripState extends State<CurrentTrip> {
  bool isArrivalConfirmed = false;
  bool isConfirmOffloadVisible = false;
  bool isLoading = false;
  String errorMessage = '';
  File? _selectedImage;
  bool areButtonsDisabled = false;
  // bool hasOffloaded = false;
  Timer? _offloadTimer;
  File? _waybillImage;
  File? _waybillTicketImage;

  @override
  void initState() {
    super.initState();
    _fetchTripData();
    _checkOffloadVisibility();
    _loadButtonState();
  }

  @override
  void dispose() {
    _offloadTimer?.cancel();
    super.dispose();
  }

  Future<void> _recordArrivalTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt('arrivalTime', currentTime);
    await prefs.setBool('arrivalButtonDisabled', true); // Save button state

    // Immediately update button visibility
    _checkOffloadVisibility();
  }

  Future<void> _resetArrivalButton() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('arrivalTime'); // Clear stored arrival time
    await prefs.setBool('arrivalButtonDisabled', false); // Reset button state

    setState(() {
      isArrivalConfirmed = false; // Reset the arrival button state
      isConfirmOffloadVisible = false; // Hide confirm offload button
      // hasOffloaded = false; // Reset offloading state
    });
  }

  void _showPopup(BuildContext context) {
    final trip =
        Provider.of<DataProvider>(context, listen: false).currentTripData;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Choose an option"),
          content: Text("Please select one of the actions below."),
          actions: [
            TextButton(
              onPressed: () {
                _resetArrivalButton(); // Reset buttons
                _confirmOffloaded(trip!['logon'], 0);
                _refreshPage();
                Navigator.of(context).pop(); // Close popup
              },
              child: Text("Mulitple Location"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showWaybillPopup(context);
                // _confirmOffloaded(trip!['logon'], 0);
              },
              child: Text("Offload Finished"),
            ),
          ],
        );
      },
    );
  }

  void _askPopup(BuildContext context, Function onYesPressed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to submit?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
                onYesPressed(); // Call function to submit
              },
              child: Text("Yes"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCamera() async {
    setState(() {
      isLoading = true; // Show loading before processing
    });

    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final File imageFile = File(image.path);

      // Read image as bytes and convert to Uint8List
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        // Resize the image
        img.Image smallerImage = img.copyResize(decodedImage, width: 500);

        // Encode back to JPG
        File resizedFile = File(image.path)
          ..writeAsBytesSync(img.encodeJpg(smallerImage));

        if (mounted) {
          setState(() {
            _selectedImage = resizedFile;
            _waybillImage = resizedFile; // Ensure _waybillImage is assigned
          });
        }
      }

      _showImagePreview();
    }
    setState(() {
      isLoading = false; // Hide loading after processing
    });
  }

  void _showImagePreview() {
    print("_showImagePreview() is called"); // Debugging

    final trip =
        Provider.of<DataProvider>(context, listen: false).currentTripData;

    if (_selectedImage == null) {
      print("No image selected in _showImagePreview()");
      return;
    }

    if (trip == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Trip data is unavailable")));
      return;
    }

    bool isBulkProductType =
        trip['isBulkProductType'] ?? false; // Check bulk type

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Preview Waybill Image"),
          content: Image.file(_selectedImage!),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _askPopup(context, () async {
                  _confirmOffloaded(trip['logon'], 0);
                  if (isBulkProductType) {
                    _showWaybillTicketPopup();
                  } else {
                    await _uploadImage();
                    _showCodePopup();
                  }
                });
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _showWaybillTicketPreview() {
    print("_showWaybillTicketPreview() is called");

    final trip =
        Provider.of<DataProvider>(context, listen: false).currentTripData;

    if (_waybillImage == null || _waybillTicketImage == null) {
      print(
        "Waybill or ticket image is missing in _showWaybillTicketPreview()",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Both waybill and ticket images are required.")),
      );
      return;
    }

    if (trip == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Trip data is unavailable")));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Preview Waybill & Ticket"),
          content: SingleChildScrollView(
            // Allows scrolling if needed
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 300, // Adjust based on screen size
                  child: Image.file(_waybillImage!, fit: BoxFit.contain),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 300, // Adjust based on screen size
                  child: Image.file(_waybillTicketImage!, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _submitWaybillAndTicket();
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _showWaybillTicketPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Waybill Ticket Required"),
          content: const Text("Please take a picture of the waybill ticket."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openCameraForWaybillTicket();
              },
              child: const Text("Open Camera"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCameraForWaybillTicket() async {
    setState(() {
      isLoading = true; // Show loading before processing
    });
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final File imageFile = File(image.path);
      // Read image as bytes and convert to Uint8List
      Uint8List imageBytes = await imageFile.readAsBytes();
      // Decode image
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        // Resize the image
        img.Image smallerImage = img.copyResize(decodedImage, width: 500);

        // Encode back to JPG
        File resizedFile = File(image.path)
          ..writeAsBytesSync(img.encodeJpg(smallerImage));

        if (mounted) {
          setState(() {
            _waybillTicketImage =
                resizedFile; // Ensure waybill ticket is assigned
          });
        }
      }

      _showWaybillTicketPreview();
    }

    setState(() {
      isLoading = false; // Hide loading after processing
    });
  }

  Future<void> _submitWaybillAndTicket() async {
    if (_waybillImage == null || _waybillTicketImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Both waybill and ticket images are required.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });
    try {
      // Convert images to Base64
      List<int> waybillBytes = await _waybillImage!.readAsBytes();
      String waybillBase64 =
          "data:image/png;base64,${base64Encode(waybillBytes)}";
      List<int> waybillTicketBytes = await _waybillTicketImage!.readAsBytes();
      String waybillTicketBase64 =
          "data:image/png;base64,${base64Encode(waybillTicketBytes)}";
      // Get current location
      LocationData? locationData = await _getCurrentLocation();
      if (locationData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get current location")),
        );
        return;
      }
      // Get the trip data
      final trip =
          Provider.of<DataProvider>(context, listen: false).currentTripData;
      if (trip == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Trip data is unavailable")));
        return;
      }

      // Prepare JSON payload
      Map<String, dynamic> payload = {
        "logon": trip['logon'],
        "latitude": locationData.latitude ?? 0.0,
        "longitude": locationData.longitude ?? 0.0,
        "waybillProof": waybillBase64,
        "wayBillTicketProofBase64": waybillTicketBase64,
      };

      // Get the token from the provider
      final token =
          Provider.of<DataProvider>(context, listen: false).token ?? '';

      // Send HTTP POST request
      final response = await http.post(
        Uri.parse(
          "https://staging-812204315267.us-central1.run.app/trip/confirm/delivery",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(payload),
      );

      // Handle response
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Waybill and ticket uploaded successfully!")),
        );
        _showCodePopup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading waybill and ticket: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() {
      isLoading = true;
    });

    try {
      // Convert image to Base64
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      // String base64Images = base64Encode(imageBytes);
      String base64Images = "data:image/png;base64,${base64Encode(imageBytes)}";

      // Get current location
      LocationData? locationData = await _getCurrentLocation();
      if (locationData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get current location")),
        );
        return;
      }

      // Get the trip data
      final trip =
          Provider.of<DataProvider>(context, listen: false).currentTripData;
      if (trip == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Trip data is unavailable")));
        return;
      }

      // Prepare JSON payload
      Map<String, dynamic> payload = {
        "logon": trip['logon'],
        "latitude": locationData.latitude ?? 0.0,
        "longitude": locationData.longitude ?? 0.0,
        "waybillProof": base64Images,
      };

      // Get the token from the provider
      final token =
          Provider.of<DataProvider>(context, listen: false).token ?? '';

      // Send HTTP POST request
      final response = await http.post(
        Uri.parse(
          "https://staging-812204315267.us-central1.run.app/trip/confirm/delivery",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(payload),
      );

      // Handle response
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Trip delivery confirmed successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to confirm delivery: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error confirming delivery: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show popup to enter a 6-digit code
  void _showCodePopup() {
    TextEditingController _codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter 6-Digit Code"),
          content: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(hintText: "Enter Code"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                String code = _codeController.text;
                if (code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code)) {
                  // _submitCode(code);
                  Navigator.of(context).pop();
                  _askPopup(context, () => _submitCode(code));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please enter a valid 6-digit code"),
                    ),
                  );
                }
              },
              child: Text("Submit"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
              },
              child: Text("No Code Yet"),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _fetchDeliveryProofId() async {
    final url = Uri.parse(
      'https://staging-812204315267.us-central1.run.app/trip/current',
    );
    final token = Provider.of<DataProvider>(context, listen: false).token ?? '';

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
      );

      print("Trip Fetch Response: ${response.body}");

      if (response.statusCode == 200) {
        final tripData = jsonDecode(response.body);
        return tripData["result"]?["deliveryProof"]?["id"];
      } else {
        print("Failed to fetch trip details.");
        return null;
      }
    } catch (e) {
      print("Exception while fetching trip: $e");
      return null;
    }
  }

  Future<void> _submitCode(String code) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    _showViolationPopup(context);
    print("Fetching current trip...");
    String? deliveryProofId = await _fetchDeliveryProofId();

    if (deliveryProofId == null) {
      setState(() {
        isLoading = false;
        errorMessage =
            'You need to upload your waybill before you can enter your code.';
      });
      return;
    }

    print("Fetching current location...");
    LocationData? locationData = await _getCurrentLocation();
    if (locationData == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://staging-812204315267.us-central1.run.app/trip/update/delivery',
    );
    final token = Provider.of<DataProvider>(context, listen: false).token ?? '';

    final payload = {
      "deliveryProofId": deliveryProofId,
      "latitude": locationData.latitude,
      "longitude": locationData.longitude,
      "deliveryCode": code,
    };

    print("Sending PUT request to: $url");
    print("Payload: $payload");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(payload),
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("Delivery code updated successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery code updated successfully!')),
        );
      } else {
        setState(() {
          errorMessage =
              'Failed to update delivery code. Try again.\n ${response.body}';
        });
      }
    } catch (e) {
      print("Exception caught: $e");
      setState(() {
        errorMessage = 'Network error. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkOffloadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final arrivalTime = prefs.getInt('arrivalTime');

    if (arrivalTime == null) {
      setState(() {
        isConfirmOffloadVisible = false; // Hide button if no arrival time found
      });
      return;
    }

    final delayTime = 1 * 60 * 1000; // 30 minutes in milliseconds
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeRemaining = delayTime - (currentTime - arrivalTime);

    if (timeRemaining <= 0) {
      // If time has already passed, show the button immediately
      setState(() {
        isConfirmOffloadVisible = true;
      });
      return;
    }

    // Start a periodic timer to check every second
    _offloadTimer?.cancel(); // Cancel any previous timer
    _offloadTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      final newCurrentTime = DateTime.now().millisecondsSinceEpoch;
      if ((newCurrentTime - arrivalTime) >= delayTime) {
        if (mounted) {
          setState(() {
            isConfirmOffloadVisible = true; // Show button
          });
        }
        timer.cancel(); // Stop the timer
      }
    });
  }

  Future<void> _fetchTripData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    try {
      await dataProvider.fetchCurrentTrip(dataProvider.token ?? '');
      final trip = dataProvider.currentTripData;

      if (trip != null) {
        final prefs = await SharedPreferences.getInstance();
        String? savedLogon = prefs.getString('lastTripLogon');
        String currentLogon = trip['logon'].toString();
        // String errormessage = trip['message'].toString();
        String? deliveryCode = trip['deliveryProof']?['deliveryCode'];
        bool savedButtonState = prefs.getBool('arrivalButtonDisabled') ?? false;

        // Save the new logon for future checks
        if (savedLogon != currentLogon) {
          await prefs.setString('lastTripLogon', currentLogon);

          if (savedButtonState) {
            await prefs.setBool('arrivalButtonDisabled', false);
            savedButtonState = false;
          }
        }

        setState(() {
          isArrivalConfirmed = savedButtonState;
          isConfirmOffloadVisible = savedButtonState;
          areButtonsDisabled = _shouldDisableButtons(trip);
        });
        if (savedButtonState) {
          _checkOffloadVisibility();
        }
      }
    } catch (e) {
      setState(() {
        // errorMessage = errorMessage;
        errorMessage = e.toString();
      });
    }
  }

  Future<LocationData?> _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Location services are disabled. Please enable GPS.';
        });
        return null;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted == PermissionStatus.denied) {
        setState(() {
          errorMessage = 'Location permissions are denied.';
        });
        return null;
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      setState(() {
        errorMessage = 'Location permissions are permanently denied.';
      });
      return null;
    }

    return await location.getLocation();
  }

  Future<void> _saveButtonState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arrivalButtonDisabled', true);
  }

  Future<void> _loadButtonState() async {
    final prefs = await SharedPreferences.getInstance();
    bool disabled = prefs.getBool('arrivalButtonDisabled') ?? false;

    setState(() {
      isArrivalConfirmed = disabled;
      // isConfirmOffloadVisible = disabled; // Ensure offload button resets
    });

    if (disabled) {
      _checkOffloadVisibility();
    }
  }

  // Future<void> _confirmArrival(String logon, int shipmentLogId) async {
  //   setState(() {
  //     isLoading = true;
  //     errorMessage = '';
  //   });

  //   LocationData? locationData = await _getCurrentLocation();
  //   if (locationData == null) return;

  //   final url = Uri.parse(
  //     'https://staging-812204315267.us-central1.run.app/trip/confirm/arrival',
  //   );
  //   final payload = {
  //     "logon": logon,
  //     "latitude": locationData.latitude,
  //     "longitude": locationData.longitude,
  //     "currentShipmentLogId": shipmentLogId,
  //   };

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization':
  //             'Bearer ${Provider.of<DataProvider>(context, listen: false).token ?? ''}',
  //         'app-version': '1.12',
  //         'app-name': 'drivers app',
  //       },
  //       body: jsonEncode(payload),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['isSuccessful']) {
  //         await _recordArrivalTime(); // Save the arrival time
  //         await _saveButtonState(); // Save button disabled state

  //         _checkOffloadVisibility(); // Start checking for offload button after delay

  //         setState(() {
  //           isArrivalConfirmed = true; // Disable the button
  //         });

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Arrival confirmed successfully!')),
  //         );
  //       } else {
  //         setState(() {
  //           errorMessage = 'Error: ${data["message"]}';
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         errorMessage = 'Not around Customer\'s location.';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       errorMessage = 'Network error. Please try again.';
  //     });
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> _confirmArrival(String logon, int shipmentLogId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    LocationData? locationData = await _getCurrentLocation();
    if (locationData == null) return;

    final url = Uri.parse(
      'https://staging-812204315267.us-central1.run.app/trip/confirm/arrival',
    );
    final payload = {
      "logon": logon,
      "latitude": locationData.latitude,
      "longitude": locationData.longitude,
      "currentShipmentLogId": shipmentLogId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Provider.of<DataProvider>(context, listen: false).token ?? ''}',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(payload),
      );

      debugPrint("This is the response ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isSuccessful']) {
          await _recordArrivalTime(); // Save the arrival time
          await _saveButtonState(); // Save button disabled state

          _checkOffloadVisibility(); // Start checking for offload button after delay

          setState(() {
            isArrivalConfirmed = true; // Disable the button
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arrival confirmed successfully!')),
          );
        } else {
          setState(() {
            errorMessage = '${data["message"] ?? 'Unknown error occurred'}. Please check your location and try again.';
          });
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          errorMessage = '${data["message"] ?? 'Failed to confirm arrival. Try again.'}. Please check your location and try again.';
        });
        debugPrint("Failed to confirm arrival: ${response.body}");
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
}

  // Refresh the page
  Future<void> _refreshPage() async {
    setState(() {
      isLoading = true; // Show loading indicator
      errorMessage = ''; // Clear error messages
    });

    try {
      _fetchTripData(); // Reload trip data
      await _loadButtonState(); // Reload arrival button state
      await _checkOffloadVisibility(); // Check if offload button should appear

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Successfull!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh. Check your internet.')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> _confirmOffloaded(String logon, [int? shipmentLogId]) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    print("Fetching current location...");
    LocationData? locationData = await _getCurrentLocation();
    if (locationData == null) {
      print("Failed to get location.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final trip =
        Provider.of<DataProvider>(context, listen: false).currentTripData;

    if (trip == null || trip['shipmentTripLogs'] == null) {
      print("No trip or shipment logs found.");
      setState(() {
        isLoading = false;
        errorMessage = 'No trip or shipment logs found.';
      });
      return;
    }

    List<Map<String, dynamic>> shipmentLogs = [];
    if (trip['shipmentTripLogs'] is List) {
      shipmentLogs =
          (trip['shipmentTripLogs'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
    }

    print("Shipment logs: ${jsonEncode(shipmentLogs)}");

    // Extract shipment log IDs safely (convert from String to int if necessary)
    List<int> logIds =
        shipmentLogs
            .map(
              (log) => int.tryParse(log['id'].toString()) ?? 0,
            ) // Convert to int
            .where((id) => id > 0) // Keep only valid IDs
            .toList();

    print("Extracted Shipment Log IDs: $logIds");

    // Fix: Ensure lastShipmentLogId gets the correct max value
    int lastShipmentLogId =
        (shipmentLogId != null && shipmentLogId > 0)
            ? shipmentLogId
            : (logIds.isNotEmpty ? logIds.reduce((a, b) => a > b ? a : b) : 0);

    print("Final lastShipmentLogId: $lastShipmentLogId");

    final url = Uri.parse(
      'https://staging-812204315267.us-central1.run.app/trip/confirm/offloaded',
    );
    final payload = {
      "logon": logon,
      "latitude": locationData.latitude,
      "longitude": locationData.longitude,
      "currentShipmentLogId": lastShipmentLogId,
      "endOfShipmentDropOff": true,
    };

    print("Sending request to: $url");
    print("Payload: $payload");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Provider.of<DataProvider>(context, listen: false).token ?? ''}',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(payload),
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Decoded response: $data");

        if (data['isSuccessful']) {
          print("Offloading confirmed successfully!");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offloading confirmed successfully!')),
          );
        } else {
          print("Error from server: ${data["message"]}");
          setState(() {
            errorMessage = 'Error: ${data["message"]}';
          });
        }
      } else {
        print("Failed to confirm offloading.");
        setState(() {
          errorMessage = 'Failed to confirm offloading. Try again.';
        });
      }
    } catch (e) {
      print("Exception caught: $e");
      setState(() {
        errorMessage = 'Network error. Please try again.';
      });
    } finally {
      print("Request complete. isLoading set to false.");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to show the waybill confirmation popup
  void _showWaybillPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Waybill Upload"),
          content: Text("Have you uploaded a waybill before?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCodePopup();
              },
              child: Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openCamera();
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  bool _shouldDisableButtons(Map<String, dynamic> trip) {
    bool isBulkProductType = trip['isBulkProductType'] ?? false;
    String? waybillProofBase64 = trip['deliveryProof']?['waybillProofBase64'];
    String? wayBillTicketProofBase64 =
        trip['deliveryProof']?['wayBillTicketProofBase64'];

    if (isBulkProductType) {
      // Disable both buttons if both base64 values exist
      return (waybillProofBase64 != null && waybillProofBase64.isNotEmpty) &&
          (wayBillTicketProofBase64 != null &&
              wayBillTicketProofBase64.isNotEmpty);
    } else {
      // Disable both buttons if only waybillProofBase64 exists
      return waybillProofBase64 != null && waybillProofBase64.isNotEmpty;
    }
  }

  void _showViolationPopup(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mixId = dataProvider.profileData?['mixDriverId'] ?? '';

    if (mixId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver ID not found. Unable to fetch violations."),
        ),
      );
      return;
    }

    await dataProvider.fetchViolations(mixId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Trip Reports"),
          content: ViolationReportsContent(),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final dataProvider = Provider.of<DataProvider>(context);
    final trip = dataProvider.currentTripData;

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          languageProvider.translate('Current Trip'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPage,
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          final trip = dataProvider.currentTripData;

          if (errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (trip == null) {
            return Center(
              child: Text(
                languageProvider.translate('No Current Trip at the moment.'),
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: themeProvider.isDarkMode ? Colors.black : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Ship To Address',
                    trip['shipToAddress'] ?? 'N/A',
                    themeProvider,
                  ),
                  _buildDetailRow(
                    'Logon',
                    trip['logon'] ?? 'N/A',
                    themeProvider,
                  ),
                  _buildDetailRow(
                    'Quantity',
                    '${trip['quantity'] ?? 'N/A'} Tons',
                    themeProvider,
                  ),
                  _buildDetailRow(
                    'Dispatch Date',
                    trip['dispatchDate'] ?? 'N/A',
                    themeProvider,
                  ),
                  _buildDetailRow(
                    'Lead Time SLA',
                    trip['leadTimeSla'] ?? 'N/A',
                    themeProvider,
                  ),
                  _buildDetailRow(
                    'Last Updated',
                    trip['lastUpdated'] ?? 'N/A',
                    themeProvider,
                  ),
                  _buildDetailRow(
                    'Driver Name',
                    trip['driverName'] ?? 'N/A',
                    themeProvider,
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  ElevatedButton(
                    onPressed:
                        isArrivalConfirmed
                            ? null
                            : () => _confirmArrival(trip['logon'], 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isArrivalConfirmed ? Colors.grey : Colors.green,
                    ),
                    child: Text(
                      isArrivalConfirmed
                          ? 'Arrival Confirmed'
                          : 'Confirm Arrival',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // Show "Confirm Offload" button only if conditions are met
                  if (isConfirmOffloadVisible)
                    ElevatedButton(
                      onPressed:
                          _shouldDisableButtons(trip)
                              ? null
                              : () {
                                final trip =
                                    Provider.of<DataProvider>(
                                      context,
                                      listen: false,
                                    ).currentTripData;
                                _showPopup(context);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _shouldDisableButtons(trip) ? Colors.grey : null,
                      ),
                      child: Text("Offloaded"),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildDetailRow(
    String title,
    String value,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    themeProvider.isDarkMode
                        ? Colors.grey[300]
                        : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ViolationReportsContent extends StatefulWidget {
  const ViolationReportsContent({super.key});

  @override
  _ViolationReportsContentState createState() =>
      _ViolationReportsContentState();
}

class _ViolationReportsContentState extends State<ViolationReportsContent> {
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchViolations();
  }

  Future<void> _fetchViolations() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mixId = dataProvider.profileData?['mixDriverId'] ?? '';

    if (mixId == null || mixId.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Driver ID not found. Unable to fetch violations.";
      });
      return;
    }
    debugPrint(mixId);
    try {
      await dataProvider.fetchViolations(mixId);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching violations.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final violationData = dataProvider.violationData;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(errorMessage, style: TextStyle(color: Colors.red)),
      );
    }

    if (violationData == null || violationData.isEmpty) {
      return const Center(child: Text("No violations available"));
    }

    final List<Map<String, String>> violationItems = [
      // {"title": "Total Violations", "key": "totalViolations"},
      {"title": "Daily Rest ", "key": "dailyRestViolations"},
      {"title": "Weekly Rest ", "key": "weeklyRestViolations"},
      {"title": "Continuous Driving", "key": "continuousDrivingViolations"},
      {"title": "Over Speeding ", "key": "overSpeedingViolations"},
      {"title": "Harsh Braking ", "key": "harshBrakingViolations"},
      {"title": "Harsh Acceleration ", "key": "harshAccelerationViolations"},
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            violationItems.map((violation) {
              return _buildViolationRow(
                violation["title"]!,
                violationData[violation["key"]] != null
                    ? violationData[violation["key"]].toString()
                    : "0",
              );
            }).toList(),
      ),
    );
  }

  Widget _buildViolationRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
