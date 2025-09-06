import 'package:flutter/material.dart';
import 'manage_contacts_screen.dart'; // Import manage contacts screen
import 'services/location_sms_service.dart';
import 'services/firestore_service.dart';
import 'user_session.dart';
import 'panic_logs_screen.dart';

class PanicButtonScreen extends StatefulWidget {
  @override
  _PanicButtonScreenState createState() => _PanicButtonScreenState();
}

class _PanicButtonScreenState extends State<PanicButtonScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SizedBox(
        width: double.infinity,
        height: size.height,
        child: Stack(
          children: [
            // Main content area
            Container(
              width: double.infinity,
              height: size.height,
              decoration: BoxDecoration(color: Color(0xFFFFFFFF)),
              child: Column(
                children: [
                  // Header
                  SafeArea(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Text(
                        'SafeHer',
                        style: const TextStyle(
                          color: Color(0xFF111317),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Main content - Panic Button Area
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Emergency message
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Click here to feel SAFE.',
                              style: const TextStyle(
                                color: Color(0xFF646D87),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          SizedBox(height: 40),
                          
                          // Panic Button
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tap and hold to send real emergency alert'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            onLongPress: () async {
                              if (!UserSession.isReady) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please login first.')),
                                );
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('EMERGENCY ALERT ACTIVATED! Sending SMS...'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // 1) Load contacts
                              final contacts = await FirestoreService.instance
                                  .getEmergencyContactsOnce(UserSession.phoneNumber!);

                              // 2) Send emergency alert with location and area details
                              final name = UserSession.userName ?? 'Your contact';
                              final results = await LocationSmsService.instance
                                  .sendEmergencyAlert(contacts: contacts, userName: name);

                              // 3) Get location details for logging
                              final locationDetails = await LocationSmsService.instance.getCurrentLocationDetails();
                              final link = locationDetails['link'];
                              final area = locationDetails['area'] ?? 'Unknown area';
                              final msg = '🚨 SafeHer ALERT! ${name} may be in danger.\nLocation: ${area}\n${link != null ? 'Live location: $link' : 'Location not available.'}\nPlease call/check immediately.';

                              // 5) Save panic log
                              await FirestoreService.instance.addPanicLog(
                                userDocId: UserSession.phoneNumber!,
                                message: msg,
                                locationLink: link,
                                contactResults: results,
                              );

                              if (!mounted) return;
                              final anySuccess = results.any((r) => (r['status'] ?? '') == 'SMS sent successfully');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(anySuccess
                                      ? 'Panic log saved. SMS sent to some/all contacts.'
                                      : 'Panic log saved. All sends failed.'),
                                  backgroundColor: anySuccess ? Colors.green : Colors.red,
                                ),
                              );
                            },
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    spreadRadius: 5,
                                    blurRadius: 15,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'PANIC\nBUTTON',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 30),
                          
                          // Instructions
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                Text(
                                  'Your emergency contacts will be notified immediately',
                                  style: const TextStyle(
                                    color: Color(0xFF646D87),
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap for test • Long press for emergency',
                                  style: const TextStyle(
                                    color: Color(0xFF646D87),
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            
            // Handle navigation based on selected index
            switch (index) {
              case 0:
                // Home - Already here
                break;
              case 1:
                // Contacts - Navigate to ManageContactsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageContactsScreen(),
                  ),
                );
                break;
              case 2:
                // Settings - Navigate to Panic Logs screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PanicLogsScreen(),
                  ),
                );
                break;
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}