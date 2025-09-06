import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:geocoding/geocoding.dart';

class LocationSmsService {
  LocationSmsService._();
  static final instance = LocationSmsService._();
  
  final Telephony telephony = Telephony.instance;

  /// Validates if the mobile number is a valid 10-digit Indian number
  bool isValidMobile(String input) {
    final trimmed = input.trim();
    final reg = RegExp(r'^[6-9][0-9]{9}$');
    return reg.hasMatch(trimmed);
  }

  /// Requests location permission if not already granted
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Gets current location with area name and returns detailed location info
  Future<Map<String, String?>> getCurrentLocationDetails() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'link': null, 'area': 'Location services disabled'};
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'link': null, 'area': 'Location permission denied'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'link': null, 'area': 'Location permission permanently denied'};
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Get area name using reverse geocoding
      String areaName = 'Unknown location';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          areaName = [place.locality, place.subAdministrativeArea, place.administrativeArea]
              .where((e) => e != null && e.isNotEmpty)
              .join(', ');
          if (areaName.isEmpty) areaName = 'Unknown location';
        }
      } catch (e) {
        print('Reverse geocoding failed: $e');
        areaName = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }

      // Return both Google Maps link and area name
      final link = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      return {'link': link, 'area': areaName};
    } catch (e) {
      print('Error getting location: $e');
      return {'link': null, 'area': 'Location unavailable'};
    }
  }

  /// Legacy method for backward compatibility
  Future<String?> getCurrentLocationLink() async {
    final details = await getCurrentLocationDetails();
    return details['link'];
  }

  /// Sends emergency alert with location to all contacts
  Future<List<Map<String, dynamic>>> sendEmergencyAlert({
    required List<Map<String, String>> contacts,
    required String userName,
  }) async {
    // Get location details first
    final locationDetails = await getCurrentLocationDetails();
    final locationLink = locationDetails['link'] ?? 'Location unavailable';
    final areaName = locationDetails['area'] ?? 'Unknown area';
    
    // Create catchy emergency message
    final alertMessage = createEmergencyMessage(
      userName: userName,
      areaName: areaName,
      locationLink: locationLink,
    );
    
    return await sendAlertToContacts(
      contacts: contacts,
      alertMessage: alertMessage,
    );
  }

  /// Sends SMS to emergency contacts and returns per-contact results
  Future<List<Map<String, dynamic>>> sendAlertToContacts({
    required List<Map<String, String>> contacts,
    required String alertMessage,
  }) async {
    List<Map<String, dynamic>> results = [];

    print('Starting SMS send process for ${contacts.length} contacts');
    
    // Check if telephony is available
    try {
      final isAvailable = await telephony.isSmsCapable;
      print('SMS capability: $isAvailable');
      if (!isAvailable) {
        for (var contact in contacts) {
          results.add({
            'name': contact['name'] ?? '',
            'phone': contact['phone'] ?? '',
            'status': 'Failed to send SMS',
            'error': 'Device does not support SMS',
          });
        }
        return results;
      }
    } catch (e) {
      print('Error checking SMS capability: $e');
    }

    // Check if app is default SMS app (required on some Android versions)
    try {
      final isDefaultSmsApp = await telephony.isDefaultSmsApp;
      print('Is default SMS app: $isDefaultSmsApp');
      
      if (!isDefaultSmsApp) {
        print('App is not default SMS app - requesting to become default');
        await telephony.requestToBeDefaultSmsApp();
      }
    } catch (e) {
      print('Error checking/setting default SMS app: $e');
    }

    // Request SMS permission first
    print('Requesting SMS permissions...');
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    print('SMS permissions granted: $permissionsGranted');
    
    if (permissionsGranted != true) {
      // If permission denied, mark all as failed
      for (var contact in contacts) {
        results.add({
          'name': contact['name'] ?? '',
          'phone': contact['phone'] ?? '',
          'status': 'Failed to send SMS',
          'error': 'SMS permission denied',
        });
      }
      return results;
    }

    // Send SMS to each contact
    for (var contact in contacts) {
      final phone = contact['phone'] ?? '';
      final name = contact['name'] ?? '';
      
      print('Attempting to send SMS to $name ($phone)');
      print('Message length: ${alertMessage.length} characters');
      
      try {
        // Add country code if not present
        String formattedPhone = phone;
        if (!phone.startsWith('+')) {
          formattedPhone = '+91$phone'; // Add India country code
        }
        print('Formatted phone: $formattedPhone');
        
        // Try primary SMS method
        bool success = false;
        try {
          await telephony.sendSms(
            to: formattedPhone,
            message: alertMessage,
          );
          success = true;
          print('Primary SMS method succeeded for $formattedPhone');
        } catch (primaryError) {
          print('Primary SMS method failed: $primaryError');
          // Try without country code
          try {
            await telephony.sendSms(
              to: phone,
              message: alertMessage,
            );
            success = true;
            print('SMS without country code succeeded for $phone');
          } catch (secondaryError) {
            print('Secondary SMS method also failed: $secondaryError');
            success = await sendSmsAlternative(phone, alertMessage);
          }
        }
        
        if (!success) {
          throw Exception('All SMS methods failed');
        }
        
        print('SMS API call completed for $phone');
        
        // Wait a moment to allow SMS to process
        await Future.delayed(Duration(milliseconds: 500));
        
        results.add({
          'name': name,
          'phone': phone,
          'status': 'SMS sent successfully',
          'error': null,
        });
      } catch (e) {
        print('SMS send error for $phone: $e');
        results.add({
          'name': name,
          'phone': phone,
          'status': 'Failed to send SMS',
          'error': e.toString(),
        });
      }
    }

    print('SMS send process completed. Results: ${results.length}');
    return results;
  }

  /// Creates a catchy emergency alert message with location details
  String createEmergencyMessage({
    required String userName,
    required String areaName,
    required String locationLink,
  }) {
    // Create a shorter message to avoid SMS length limits
    return 'EMERGENCY ALERT!\n'
           '${userName} needs IMMEDIATE HELP!\n\n'
           'Location: ${areaName}\n'
           'Live GPS: ${locationLink}\n\n'
           'PLEASE CALL ${userName} NOW!\n'
           'SafeHer Emergency Alert';
  }

  /// Alternative method using platform channels for SMS
  Future<bool> sendSmsAlternative(String phone, String message) async {
    try {
      print('Trying alternative SMS method for $phone');
      
      // Try using the telephony sendSms method with different approach
      final result = await telephony.sendSms(
        to: phone,
        message: message,
        isMultipart: message.length > 160,
      );
      
      print('Alternative SMS result: $result');
      return true;
    } catch (e) {
      print('Alternative SMS failed: $e');
      return false;
    }
  }
}
