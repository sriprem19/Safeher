import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'services/location_sms_service.dart';
import 'panic_button_screen.dart'; // <-- Panic button screen import
import 'user_session.dart';

class ManageContactsScreen extends StatefulWidget {
  const ManageContactsScreen({Key? key}) : super(key: key);

  @override
  State<ManageContactsScreen> createState() => _ManageContactsScreenState();
}

class _ManageContactsScreenState extends State<ManageContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, String>> _contacts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!UserSession.isReady) {
      // If user session somehow missing, show message.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session not ready. Please re-login.')),
        );
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!UserSession.isReady) return;

    if (!_formKey.currentState!.validate()) return;

    // Validate each contact phone number
    for (var contact in _contacts) {
      final phone = contact['phone'] ?? '';
      if (!LocationSmsService.instance.isValidMobile(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid phone number: $phone. Must be 10 digits starting with 6-9.')),
        );
        return;
      }
    }

    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 contact')),
      );
      return;
    }
    if (_contacts.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 contacts allowed')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.saveEmergencyContacts(
        userDocId: UserSession.phoneNumber!, // still tied to current user
        contacts: _contacts,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts saved')),
        );

        // 👉 Navigate to PanicButtonScreen after successful save
        Future.delayed(const Duration(milliseconds: 600), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => PanicButtonScreen()),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addContact() {
    if (_contacts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 contacts')),
      );
      return;
    }
    setState(() {
      _contacts.add({'name': '', 'phone': ''});
    });
  }

  void _removeContact(int index) async {
    setState(() {
      _contacts.removeAt(index);
    });
    
    // Auto-sync deletion to Firestore
    if (UserSession.isReady) {
      try {
        await FirestoreService.instance.saveEmergencyContacts(
          userDocId: UserSession.phoneNumber!,
          contacts: _contacts,
        );
      } catch (e) {
        // Silent fail for auto-sync
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = UserSession.phoneNumber;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: userId == null
          ? const Center(child: Text('No user session.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.userDocStream(userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Initialize local list from Firestore when first loaded
                if (snap.hasData && _contacts.isEmpty) {
                  final data = snap.data!.data();
                  final list = (data?['emergencyContacts'] as List<dynamic>?) ?? [];
                  _contacts.addAll(list.map<Map<String, String>>((e) => {
                        'name': (e['name'] ?? '').toString(),
                        'phone': (e['phone'] ?? '').toString(),
                      }));
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: _contacts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        initialValue: _contacts[i]['name'],
                                        decoration: const InputDecoration(labelText: 'Name'),
                                        onChanged: (v) => _contacts[i]['name'] = v.trim(),
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Name required'
                                            : null,
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        initialValue: _contacts[i]['phone'],
                                        decoration: const InputDecoration(labelText: 'Phone'),
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onChanged: (v) => _contacts[i]['phone'] = v.trim(),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Phone required';
                                          }
                                          if (!LocationSmsService.instance.isValidMobile(v.trim())) {
                                            return 'Must be 10 digits starting with 6-9';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => _removeContact(i),
                                          icon: const Icon(Icons.delete, color: Color(0xFFFF8A80)),
                                          label: const Text(
                                            'Remove',
                                            style: TextStyle(color: Color(0xFFFF8A80)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _addContact,
                                icon: const Icon(Icons.add, color: Color(0xFFFF8A80)),
                                label: const Text('Add Contact',
                                    style: TextStyle(color: Color(0xFFFF8A80))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFF8A80)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A80),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Save & Continue'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

