import 'package:flutter/material.dart';

class Contact {
  final String name;
  final String phoneNumber;
  final String avatarUrl;

    Contact({
    required this.name,
    required this.phoneNumber,
    required this.avatarUrl,
  });
}

class ManageContactsScreen extends StatelessWidget {
  ManageContactsScreen({super.key});

  final List<Contact> contacts = [
    Contact(
      name: "Sophia Carter",
      phoneNumber: "+1 (555) 123-4567",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuARI56s9nyonNcH7ajomf524bEzFsmdvIzX5PZAjaiL_wGl2bCxrjjO6WGq5dnL6mMI1vnhCd-ilglgROJrU3mqrU6q5AeLV_Q3EN1ywGKBGkQCeA2XunqAryYYnoirwC7ofyIv0SVnaWRrs72xLWxyUEk_SUZzYxGbxtVx1MdWyBFJp6kJ62iLonbF3UWfegimBM3UnC4rjQmREls9ne7jDxS_DV5rz6aVyKfaCEZrax_LI7_ZVj7nmOjctZmK_-MBhPKAkYX0ipQ",
    ),
    Contact(
      name: "Ethan Bennett",
      phoneNumber: "+1 (555) 987-6543",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAVUhnPej0eV1Hw9XsepoE8zjycU2puibTuQrvtY-vTeCeJQKxmKSWSWXOmdrbYud6cd-8GSeOIG_1ucenqtC9CtL_2nQqy3AT2XFzF5LmQCSq84TO9QsT8JsdAJqOO5lIOPFdLi42IANSCVlVC43VboNigCqyDg4B7arsTe03RuX9dRsDMNrv-8nqfal2dPetT2VoBssqqcfaEvtKXkfy5GeAQVJrwfUVnrhXPmL9SgK4ZHyrt2mX119K_N-lxKUtj2OiR-fUYhXM",
    ),
    Contact(
      name: "Olivia Hayes",
      phoneNumber: "+1 (555) 246-8013",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuBW0pUajOYDY2SYe5IquWJRh4hteWjIr4VJhHUTl4XSsrmcAiIk8VDUTDtbxmJIxjfnODo0hD_R39HezwHlPWF9rJYrJgxPlEfk4rYWQLi2_HuhyF0Rqq1mbsdUIR8suwyOR9ym2TUwNNFqfNZUQD3hQcT_G2kUelY3azxmbc-tCR3cbCtlo35YgiV6HU8dN5CcNwgXq6rqxbcQXkMAl4N5VFG4UWmJpDE0H472UZAGAl7zsl9B4FR9poymzFueRxM3ACKsvwXVa84",
    ),
    Contact(
      name: "Noah Thompson",
      phoneNumber: "+1 (555) 369-1215",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAycpwOYb8e5H-i2LlzT0V3eqTwidmZ4MjcbTyqjkODBKjZKp9jiIQSoYmj6-db64Qv6NWnmJXcHeWDu9d5tYSAaU11ePArkbDAr5CC6t0tNZ6ncJa2Wc6VVtv8ldwzbKzzF_msyFuMQj--GyaJuEk9j9TV-clgxWjbnx4KPuwznCZayHH_NMx9OCYowu0UnvE-mb_8UzmN8xpZdmU7B5WHoPxrj4NQVFOAkYjfMezgyqzvGHzQzYawsrodWgsZMM2YSv5Puft-G_I",
    ),
    Contact(
      name: "Ava Mitchell",
      phoneNumber: "+1 (555) 789-0123",
      avatarUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAyRBQxMgCFNzaZAyTM4f6R2utxJSfhPQ8Tf2Bhofn3yUVpMoQHpPRxG3tJTIDAHNCfC7XAczgXaNA7v8i1EODFnYYe9ClyL8aY__oQ9ylmweCOkNKi2XPF3f44ILrkPq2nIYkNAfoU7qiu1hQ5QthiCKh7umyEGia1Jcv81stQf2UgEE1o4jVb4h-ZpPOUk8NAA8Nw7dU0W9GpzOEqv-OnJfdDxbAhz5pcRP74emSY6A2rSyeFVSxxKzrbQqefuDgr84UhdQ7XvuQ",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF111317),
                        size: 24,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Manage Contacts',
                      style: TextStyle(
                        color: Color(0xFF111317),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Manrope',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Contact List
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return ContactListItem(
                    contact: contact,
                    onEdit: () => _onEditContact(context, contact),
                  );
                },
              ),
            ),

            // Bottom section with Done button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _onDonePressed(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F68E4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onEditContact(BuildContext context, Contact contact) {
    // Handle edit contact action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${contact.name}')),
    );
  }

  void _onDonePressed(BuildContext context) {
    // Handle done button press
    Navigator.of(context).pop();
  }
}

class ContactListItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;

  const ContactListItem({
    super.key,
    required this.contact,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(contact.avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Contact info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Color(0xFF111317),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Manrope',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phoneNumber,
                  style: const TextStyle(
                    color: Color(0xFF646D87),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Manrope',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: Color(0xFF111317),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Remove the MyApp class - this should be in your main.dart file instead