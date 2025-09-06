import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'user_session.dart';

class PanicLogsScreen extends StatelessWidget {
  const PanicLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panic Logs'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: UserSession.phoneNumber == null
          ? const Center(
              child: Text('Please login to view panic logs.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.getPanicLogsStream(UserSession.phoneNumber!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final logs = snapshot.data?.docs ?? [];
                
                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No panic logs yet.\nLong press the panic button to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data();
                    final timestamp = log['timestamp'] as Timestamp?;
                    final message = log['message'] as String? ?? '';
                    final locationLink = log['locationLink'] as String?;
                    final contactResults = (log['contactResults'] as List<dynamic>?) ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timestamp
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  timestamp != null
                                      ? _formatTimestamp(timestamp.toDate())
                                      : 'Unknown time',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Location link if available
                            if (locationLink != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Location: $locationLink',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Contact results
                            const Text(
                              'SMS Status:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...contactResults.map<Widget>((result) {
                              final name = result['name'] as String? ?? '';
                              final phone = result['phone'] as String? ?? '';
                              final status = result['status'] as String? ?? '';
                              final isSuccess = status == 'SMS sent successfully';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSuccess ? Icons.check_circle : Icons.error,
                                      color: isSuccess ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$name ($phone): $status',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSuccess ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
