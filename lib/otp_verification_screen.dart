import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// Screens / app files
import 'manage_contacts_screen.dart';
import 'services/firestore_service.dart';
import 'services/supabase_auth_service.dart';
import 'user_session.dart';

import 'package:geolocator/geolocator.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String userName;
  final String verificationId; // <-- Add this

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.userName,
    required this.verificationId, // <-- Add this
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendTimer = 30;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a complete 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // TEMP: Bypass OTP verification for testing (accept any 6-digit code)
      await Future.delayed(const Duration(milliseconds: 300));

      // 1) Set session so other screens can access
      UserSession.phoneNumber = widget.phoneNumber;
      UserSession.userName = widget.userName;

      // 2) Navigate immediately so UI doesn't wait on permissions/network
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${widget.userName}!'),
            backgroundColor: Colors.green,
          ),
        );
        // Stop loading state before navigating
        setState(() {
          _isVerifying = false;
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ManageContactsScreen()),
          (route) => false, // Clear navigation stack
        );
      }

      // 3) Do post-login setup in background (no UI block)
      Future.microtask(() async {
        try {
          await Geolocator.requestPermission();
          await FirestoreService.instance.upsertUserProfile(
            userDocId: widget.phoneNumber,
            userName: widget.userName,
            phoneNumber: widget.phoneNumber,
          );
        } catch (e) {
          // Best-effort; don't surface blocking errors here
          debugPrint('Post-login setup error: $e');
        }
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    try {
      final success = await SupabaseAuthService.sendOTP(widget.phoneNumber);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset timer
        setState(() {
          _resendTimer = 30;
          _canResend = false;
        });
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with back arrow and title
                    Container(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back,
                                size: 24,
                                color: Color(0xFF111317),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 48),
                              alignment: Alignment.center,
                              child: const Text(
                                'SafeHer',
                                style: TextStyle(
                                  color: Color(0xFF111317),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.015,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Full Image Section
                    Container(
                      width: double.infinity,
                      height: screenHeight * 0.45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://lh3.googleusercontent.com/aida-public/AB6AXuCW8MTQB7k9QBIWSvmd9Feh3flOjDfEJuu7RYA8bO_9-pYf74QTBJMEDvX5iJbVHF9fegL9vIhcirniETGQSI-6H99b8LvPuzQtqdBEO5rmteA8-6tTtyQPilyw_q3QXL7tCtVAweGqF0Y8mynJj9D0_z4BU99Ad3mrOL6BFzOv7vRwlheUV_LjpO07dxMnfVBKziWHBY6NY_9mSyhgrM_3ohveugmvjdAD6AJr-gI0KbWpHdxZZ2LKJEewOBtSnJd7gvrDxcq2l-8",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Title
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Text(
                        'Enter Verification Code',
                        style: TextStyle(
                          color: Color(0xFF111317),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Subtitle with phone number
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text(
                        'A 6-digit code was sent to ${widget.phoneNumber}',
                        style: const TextStyle(
                          color: Color(0xFF111317),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // OTP Input Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 48,
                              height: 56,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  color: Color(0xFF111317),
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFDCDEE5),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF3F68E4),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFDCDEE5),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  }
                                },
                                onTap: () {
                                  _controllers[index].selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset:
                                            _controllers[index].text.length),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section with Buttons
            Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Verify & Proceed Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3F68E4),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isVerifying
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Verify & Proceed',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.015,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Resend Code Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: _canResend ? _resendOtp : null,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: _canResend
                                ? const Color(0xFF111317)
                                : const Color(0xFF646D87),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _canResend
                                ? 'Resend Code'
                                : 'Resend Code (${_resendTimer}s)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.015,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Tagline
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.1,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F1F4),
                  ),
                  child: const Center(
                    child: Text(
                      'SafeHer - Your Safety Companion',
                      style: TextStyle(
                        color: Color(0xFF646D87),
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

