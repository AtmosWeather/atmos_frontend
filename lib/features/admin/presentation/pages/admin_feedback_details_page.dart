import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:atmos_frontend/core/config/api_config.dart';

class AdminFeedbackDetailsPage extends StatefulWidget {
  final Map<String, dynamic> messageData;
  final VoidCallback onRead;

  const AdminFeedbackDetailsPage({
    super.key,
    required this.messageData,
    required this.onRead,
  });

  @override
  State<AdminFeedbackDetailsPage> createState() => _AdminFeedbackDetailsPageState();
}

class _AdminFeedbackDetailsPageState extends State<AdminFeedbackDetailsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.messageData['status'] == 'unread') {
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    try {
      final id = widget.messageData['id'];
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/feedback/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'read'})
      );
      widget.onRead(); // Notify parent to update unread badge state
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _archiveMessage() async {
    try {
      final id = widget.messageData['id'];
      await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/admin/feedback/$id'));
      widget.onRead(); // Notify parent to refresh list
      if (mounted) {
        Navigator.pop(context, true); // Pop with truthy value to indicate archival
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to archive message')));
      }
    }
  }
  
  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown time';
    try {
      final d = DateTime.parse(isoString).toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
             '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEEEEE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Message Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive, color: Colors.grey),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Archive Message'),
                  content: const Text('Are you sure you want to archive this message? It will be hidden but preserved in the database.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _archiveMessage();
                      },
                      child: const Text('Archive', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.messageData['photoUrl'] != null && (widget.messageData['photoUrl'] as String).isNotEmpty)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(widget.messageData['photoUrl']),
                        )
                      else  
                        CircleAvatar(
                          backgroundColor: const Color(0xFF29B6F6),
                          radius: 24,
                          child: Text(
                            (widget.messageData['name'] as String).isNotEmpty
                                ? (widget.messageData['name'] as String)[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.messageData['name'] ?? 'Unknown Sender',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.messageData['email'] ?? 'No Email Provided',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(widget.messageData['timestamp']),
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'MESSAGE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.messageData['message'] ?? 'No content',
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
