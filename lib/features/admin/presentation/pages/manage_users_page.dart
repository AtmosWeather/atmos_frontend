import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:atmos_frontend/core/config/api_config.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/users'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = data['data'] ?? [];
        });
      } else {
        _showError('Failed to load users');
      }
    } catch (e) {
      _showError('Connection error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editUser(String uid, String currentName) async {
    final nameController = TextEditingController(text: currentName);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password (Optional)',
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setStateDialog(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: obscurePassword,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                obscureText: obscurePassword,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty && passwordController.text.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: Colors.red));
                  return;
                }
                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(context, true);
              }, 
              child: const Text('Save', style: TextStyle(color: Color(0xFF29B6F6)))
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newName = nameController.text.trim();
      final newPassword = passwordController.text.trim();
      if (newName == currentName && newPassword.isEmpty) return;

      setState(() => _isLoading = true);
      try {
        final Map<String, dynamic> bodyData = {'displayName': newName};
        if (newPassword.isNotEmpty) {
          bodyData['password'] = newPassword;
        }

        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$uid'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyData),
        );
        if (response.statusCode == 200) {
          _fetchUsers();
        } else {
          _showError('Failed to update user');
          setState(() => _isLoading = false);
        }
      } catch (e) {
        _showError('Connection error: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _archiveUser(String uid, String email) async {
    if (email == 'kentjohnllanita8978@gmail.com') {
      _showError('Cannot archive the master admin account.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive User'),
        content: const Text('Are you sure you want to archive this user? It will be hidden but preserved in the database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archive', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$uid'));
        if (response.statusCode == 200) {
          _fetchUsers();
        } else {
          _showError('Failed to archive user');
          setState(() => _isLoading = false);
        }
      } catch (e) {
        _showError('Connection error: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Manage Users',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF29B6F6)))
              : _users.isEmpty
                  ? const Center(child: Text('No users found', style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final email = user['email'] ?? 'Unknown Email';
                    final displayName = user['displayName'] ?? 'No Name';
                    final uid = user['uid'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFFFAFAFA),
                      elevation: 1,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF29B6F6),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Name: $displayName'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF29B6F6)),
                              onPressed: () => _editUser(uid, displayName),
                            ),
                            IconButton(
                              icon: const Icon(Icons.archive, color: Colors.grey),
                              onPressed: () => _archiveUser(uid, email),
                            ),
                          ],
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
