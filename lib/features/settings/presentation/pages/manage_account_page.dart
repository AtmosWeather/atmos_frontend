import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:atmos_frontend/core/auth/auth_state.dart';
import 'package:atmos_frontend/core/config/api_config.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;
  String? _base64Image;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final authState = AuthState();
    _nameController = TextEditingController(text: authState.displayName ?? '');
    _base64Image = authState.base64ProfileImage;
  }

  /// Validates the current password by calling the backend signin endpoint.
  Future<bool> _verifyCurrentPassword() async {
    final email = AuthState().userEmail;
    if (email == null || email.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': _currentPasswordController.text,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final bool passwordChangeRequested = _currentPasswordController.text.isNotEmpty || 
                                         _passwordController.text.isNotEmpty || 
                                         _confirmPasswordController.text.isNotEmpty;

    if (passwordChangeRequested) {
      if (_currentPasswordController.text.isEmpty) {
        _showError('Please enter your current password.');
        return;
      }
      if (_passwordController.text.isEmpty || _passwordController.text.length < 8) {
        _showError('New password must be at least 8 characters long.');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Confirm password does not match new password.');
        return;
      }

      setState(() => _isSaving = true);

      final isValid = await _verifyCurrentPassword();
      if (!isValid) {
        if (mounted) {
          setState(() => _isSaving = false);
          _showError('Current password is incorrect. Please try again.');
        }
        return;
      }
    } else {
      setState(() => _isSaving = true);
    }

    try {
      String? photoUrl = _base64Image;

      // Ensure it is properly formatted as a data URI for the backend
      if (_base64Image != null && !_base64Image!.startsWith('http')) {
        if (!_base64Image!.startsWith('data:image')) {
          photoUrl = 'data:image/jpeg;base64,$_base64Image';
        }
      }

      final uid = AuthState().uid;
      if (uid != null) {
        final Map<String, dynamic> bodyData = {'displayName': _nameController.text.trim()};
        if (_passwordController.text.isNotEmpty) {
          bodyData['password'] = _passwordController.text;
        }
        if (photoUrl != null) {
          bodyData['photoUrl'] = photoUrl;
        }

        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$uid'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyData),
        );
        
        if (response.statusCode != 200) {
           throw Exception('Failed to save to backend.');
        }
      }

      await AuthState().updateProfile(
        name: _nameController.text.trim(),
        base64Image: photoUrl,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account updated successfully!', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update account.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, _) {
        final liveImage = _base64Image ?? AuthState().base64ProfileImage;
        final isDark = AuthState().theme == 'Dark Mode';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white70 : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Manage Account',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Photo
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                              shape: BoxShape.circle,
                            ),
                            child: liveImage != null && liveImage.isNotEmpty
                                ? ClipOval(
                                    child: liveImage.startsWith('http')
                                      ? Image.network(
                                          liveImage,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.memory(
                                          base64Decode(liveImage.split(',').last),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                  )
                                : Icon(Icons.person, size: 60, color: isDark ? Colors.white54 : const Color(0xFFBDBDBD)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF29B6F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Full Name Section ──
                  _buildSectionCard(
                    title: 'Full Name',
                    isDark: isDark,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF29B6F6))),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Name cannot be empty' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Change Password Section ──
                  _buildSectionCard(
                    title: 'Change Password',
                    isDark: isDark,
                    children: [
                      // Current Password
                      Text('Current Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Enter current password',
                          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF29B6F6))),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility, color: isDark ? Colors.white54 : Colors.grey),
                            onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                          ),
                        ),
                        validator: (val) {
                          final isRequested = _passwordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty || _currentPasswordController.text.isNotEmpty;
                          if (isRequested && (val == null || val.isEmpty)) {
                            return 'Enter your current password to proceed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF29B6F6))),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: isDark ? Colors.white54 : Colors.grey),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          final isRequested = _currentPasswordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty || _passwordController.text.isNotEmpty;
                          if (isRequested) {
                            if (val == null || val.isEmpty) return 'Enter a new password';
                            if (val.length < 8) return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF29B6F6))),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: isDark ? Colors.white54 : Colors.grey),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (val) {
                          final isRequested = _currentPasswordController.text.isNotEmpty || _passwordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty;
                          if (isRequested) {
                            if (val == null || val.isEmpty) return 'Confirm your new password';
                            if (val != _passwordController.text) return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29B6F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
