import 'package:flutter/material.dart';
import 'otp_verification_screen.dart'; // Make sure this file exists

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final name = _nameController.text.trim();
    final mobile = _phoneController.text.trim();

    if (name.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          userName: name,
          phoneNumber: mobile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Image
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuCjOOYYs7u3YnpnxyMpfpwl7pQp4JUr9f-NPPWp3CLAu3Yj8_79ZnUoaCpUxRZUYyXkP3e5A-w3Q1AuWF4KEMiUWHMb_4qPy4q66QOYzcw_xF3xTpanhwBvWaHsb0etrIW5T_DdddRO_UqWmUhLDpLuU5N5s67YF9v-Zd0Dpmmtm84mPTUFeYgF5nQvAIhBL7M_u_qyj5Yp61fweSzEXyJK9xvpG3nElYOL9DaSqctCc05Yi1pJBhfR4tLI9UWDnMcUoRMdlPfkuVI",
                    height: 218,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 218,
                        color: const Color(0xFFF0F1F4),
                        child: const Icon(Icons.error, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),

              // Welcome Back Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  // Changed from GoogleFonts.manrope
                  style: const TextStyle(
                    fontFamily: 'Manrope', // Assumes 'Manrope' is the family name in pubspec.yaml
                    color: Color(0xFF111317),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Subtitle
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Enter your details to log in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF111317),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // Name Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    hintStyle: const TextStyle(fontFamily: 'Manrope', color: Color(0xFF646D87)),
                    filled: true,
                    fillColor: const Color(0xFFF0F1F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF111317),
                    fontSize: 16,
                  ),
                ),
              ),

              // Mobile Number Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Mobile Number',
                    hintStyle: const TextStyle(fontFamily: 'Manrope', color: Color(0xFF646D87)),
                    filled: true,
                    fillColor: const Color(0xFFF0F1F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF111317),
                    fontSize: 16,
                  ),
                ),
              ),

              // Send OTP Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F68E4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
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