import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  static Future<String?> getDeviceIdentifier() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Returns Android ID (alternative to IMEI)
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor; // Unique ID for iOS devices
    }
    return null;
  }
}
