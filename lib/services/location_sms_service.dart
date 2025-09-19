import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationSmsService {

  static const MethodChannel _smsChannel = MethodChannel('com.example.safeher/sms');

  /// Validate Indian mobile number (10 digits starting with 6-9)
  static bool isValidMobile(String mobile) {
    if (mobile.length != 10) return false;
    final firstDigit = mobile[0];
    return ['6', '7', '8', '9'].contains(firstDigit);
  }

  /// Get current location with high accuracy
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permissions are denied.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied.");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  /// Build SOS alert message
  Future<String> buildAlertMessage(String userName) async {
    final position = await getCurrentLocation();
    final buffer = StringBuffer();

    buffer.writeln("$userName needs IMMEDIATE HELP!");
    buffer.writeln("Location:");

    if (position != null) {
      // Reverse geocode to get a readable place name
      String placeName = await _getPlaceName(position);
      buffer.writeln(placeName.isNotEmpty ? placeName : "Unknown area");

      buffer.writeln("Latitude: ${position.latitude}");
      buffer.writeln("Longitude: ${position.longitude}");
      buffer.writeln(
          "Google Maps: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}");
    } else {
      buffer.writeln("Location unavailable");
    }

    buffer.writeln("Please reach out as soon as possible.");

    return buffer.toString();
  }

  /// Get a human-readable place name from coordinates
  Future<String> _getPlaceName(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Build a concise location string
        final parts = <String>[
          if ((p.name ?? '').trim().isNotEmpty) p.name!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
          if ((p.administrativeArea ?? '').trim().isNotEmpty)
            p.administrativeArea!.trim(),
          if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
        ];
        return parts.join(', ');
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
    return '';
  }


  /// Send SMS alert to all contacts
  Future<List<Map<String, String?>>> sendAlertToContacts(
    List<Map<String, String>> contacts,
    String userName,
  ) async {
    final List<Map<String, String?>> results = [];
    final alertMessage = await buildAlertMessage(userName);

    // Filter out empty phone numbers and format them
    final List<String> validPhones = [];
    for (var contact in contacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isNotEmpty) {
        // Add +91 prefix if not present and doesn't start with +
        final formattedPhone = phone.startsWith('+')
            ? phone
            : (phone.startsWith('0') ? '+91${phone.substring(1)}' : '+91$phone');
        validPhones.add(formattedPhone);
      }
    }

    if (validPhones.isEmpty) {
      for (var contact in contacts) {
        results.add({
          'name': contact['name'],
          'phone': contact['phone'],
          'status': 'Failed to send SMS',
          'error': 'No valid phone numbers found',
        });
      }
      return results;
    }

    // Prefer direct SMS on Android; do NOT open composer on Android
    if (Platform.isAndroid) {
      try {
        // Request runtime SMS permission
        final perm = await Permission.sms.request();
        if (!perm.isGranted) {
          throw Exception('SMS permission not granted');
        }

        // Send individually to improve reliability and to capture per-contact status
        for (final contact in contacts) {
          final raw = (contact['phone'] ?? '').trim();
          if (raw.isEmpty) {
            results.add({
              'name': contact['name'],
              'phone': raw,
              'status': 'Failed to send SMS',
              'error': 'Phone number is empty',
            });
            continue;
          }
          final formattedPhone = raw.startsWith('+')
              ? raw
              : (raw.startsWith('0') ? '+91${raw.substring(1)}' : '+91$raw');

          try {
            debugPrint('SafeHer: Attempting to send SMS to $formattedPhone');
            debugPrint('SafeHer: Message length: ${alertMessage.length}');
            
            final ok = await _smsChannel.invokeMethod<bool>('sendSms', {
              'phone': formattedPhone,
              'message': alertMessage,
            });
            
            if (ok == true) {
              debugPrint('SafeHer: SMS sent successfully to ${contact['name']} ($raw)');
              results.add({
                'name': contact['name'],
                'phone': raw,
                'status': 'SMS sent successfully',
                'error': null,
              });
            } else {
              throw Exception('Native sendSms returned false');
            }
          } catch (e) {
            debugPrint('SafeHer: SMS failed for ${contact['name']} ($raw): $e');
            results.add({
              'name': contact['name'],
              'phone': raw,
              'status': 'Failed to send SMS',
              'error': e.toString(),
            });
          }
        }
      } catch (e) {
        debugPrint('Direct SMS failed on Android: $e');
        // Do not open composer on Android as per requirement; report failures
        if (results.isEmpty) {
          for (var contact in contacts) {
            results.add({
              'name': contact['name'],
              'phone': contact['phone'],
              'status': 'Failed to send SMS',
              'error': 'Direct SMS error: ' + e.toString(),
            });
          }
        }
      }
    } else {
      await _openComposerFallback(contacts, validPhones, alertMessage, results);
    }

    return results;
  }

  Future<void> _openComposerFallback(
    List<Map<String, String>> contacts,
    List<String> validPhones,
    String alertMessage,
    List<Map<String, String?>> results,
  ) async {
    try {
      final recipientsString = validPhones.join(',');
      final encodedMessage = Uri.encodeComponent(alertMessage);
      final smsUri = Uri.parse('sms:$recipientsString?body=$encodedMessage');
      final launched = await launchUrl(smsUri);
      if (launched) {
        for (var contact in contacts) {
          final phone = contact['phone'] ?? '';
          if (phone.isNotEmpty) {
            results.add({
              'name': contact['name'],
              'phone': phone,
              'status': 'SMS app opened with all contacts',
              'error': null,
            });
          } else {
            results.add({
              'name': contact['name'],
              'phone': phone,
              'status': 'Failed to send SMS',
              'error': 'Phone number is empty',
            });
          }
        }
      } else {
        throw Exception('Could not launch SMS app');
      }
    } catch (e) {
      debugPrint('Error opening SMS app: $e');
      for (var contact in contacts) {
        results.add({
          'name': contact['name'],
          'phone': contact['phone'],
          'status': 'Failed to open SMS app',
          'error': e.toString(),
        });
      }
    }
  }
}
