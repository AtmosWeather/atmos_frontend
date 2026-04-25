import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:atmos_frontend/core/config/api_config.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/admin_feedback_details_page.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/feedback'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _messages = data['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _archiveMessage(String id) async {
    try {
      await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/admin/feedback/$id'));
      _fetchFeedback(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to archive message')));
      }
    }
  }


  Future<void> _showMessageDetails(Map<String, dynamic> msg) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminFeedbackDetailsPage(
          messageData: msg,
          onRead: () {
            _fetchFeedback(); // Refresh list to update badge state
          },
        ),
      ),
    );
    
    if (result == true) {
      _fetchFeedback(); // Refresh if deleted
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEEEEE),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF29B6F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Atmos',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF29B6F6)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
                  child: Text(
                    'Feedback & Messages',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('No messages received yet', style: TextStyle(color: Colors.black54)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUnread = msg['status'] == 'unread';

                    return Dismissible(
                      key: Key(msg['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        color: Colors.grey,
                        child: const Icon(Icons.archive, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _archiveMessage(msg['id'].toString());
                      },
                      child: Card(
                        color: isUnread ? const Color(0xFFE1F5FE) : const Color(0xFFF5F5F5),
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () async {
                            await _showMessageDetails(msg);
                          },
                          leading: (msg['photoUrl'] != null && (msg['photoUrl'] as String).isNotEmpty)
                              ? CircleAvatar(
                                  backgroundColor: isUnread ? const Color(0xFF29B6F6) : Colors.grey.shade400,
                                  backgroundImage: (msg['photoUrl'] as String).startsWith('data:image') 
                                      ? MemoryImage(base64Decode((msg['photoUrl'] as String).split(',').last)) as ImageProvider
                                      : NetworkImage(msg['photoUrl']),
                                )
                              : CircleAvatar(
                                  backgroundColor: isUnread ? const Color(0xFF29B6F6) : Colors.grey.shade400,
                                  child: const Icon(Icons.mail, color: Colors.white, size: 20),
                                ),
                          title: Text(
                            msg['name'] ?? 'Unknown',
                            style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                          ),
                          subtitle: Text(
                            msg['message'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isUnread
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
