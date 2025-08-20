import 'package:flutter/material.dart';
import 'login_screen.dart';

class SafeHerWelcomeScreen extends StatelessWidget {
  const SafeHerWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main content centered in the available space
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image Section
                      Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.4,
                        constraints: const BoxConstraints(
                          maxHeight: 350,
                          minHeight: 250,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage(
                              "https://lh3.googleusercontent.com/aida-public/AB6AXuDadeICSc2Z9t9Ms6m8YZJ_wS92KzdHGnU3yruj0xltWpfTZxxKDHJf-Ny3WeLfuxjWEVvvsTFq1MXuzPxmJb9RbWbsjx4P5G4UnvqBnO-Au-Y4iOQs1GuuSPfBDMynbDlqdcFeUBWmDDJrm8OKduhb1tFybb_hZDjbx3Tho-RgflTTBgMbHQmNqEP9YpHFA9KLskIjw4eQr0W8nRntLSjaJT5fdSc1MpCPcTpVMHUNLaODGyJlt_wvyRIpORB-cwxrgORGplcem48"
                            ),
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Title
                      const Text(
                        'Welcome to SafeHer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111317),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      const Text(
                        'Your personal safety companion, always by your side.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111317),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Buttons Section
                      Column(
                        children: [
                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );  
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3F68E4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.015,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle login
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF0F1F4),
                                foregroundColor: const Color(0xFF111317),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.015,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}