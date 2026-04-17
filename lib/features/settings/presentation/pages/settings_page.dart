import 'dart:convert';
import 'package:atmos_frontend/core/auth/auth_state.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, child) {
        final authState = AuthState();
        final isDark = authState.theme == 'Dark Mode';
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const Icon(Icons.cloud_circle, color: Color(0xFF29B6F6), size: 28),
                  ],
                ),
                const SizedBox(width: 8),
                Text('Atmos', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF444444) : const Color(0xFFE0E0E0)),
                      ),
                      child: Icon(Icons.arrow_back, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Profile Section
                Center(
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          shape: BoxShape.circle,
                        ),
                        child: authState.base64ProfileImage != null && authState.base64ProfileImage!.isNotEmpty
                            ? ClipOval(
                                child: authState.base64ProfileImage!.startsWith('http')
                                    ? Image.network(
                                        authState.base64ProfileImage!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.memory(
                                        base64Decode(authState.base64ProfileImage!.split(',').last),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 48,
                                color: Color(0xFFBDBDBD),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Log In / User Email / Logout button
                      if (authState.isSignedIn)
                        Column(
                          children: [
                            if (authState.displayName != null && authState.displayName!.isNotEmpty)
                              Text(
                                authState.displayName!,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            if (authState.displayName != null && authState.displayName!.isNotEmpty)
                              const SizedBox(height: 2),
                            Text(
                              authState.userEmail ?? 'User',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/manage_account'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF29B6F6),
                                backgroundColor: const Color(0xFFE1F5FE),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Manage Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: 120,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signin');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF29B6F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Preferences Section
                _buildSectionHeader('Preferences'),
                _buildSettingsTile(
                  icon: Icons.thermostat_outlined,
                  title: 'Units',
                  subtitle: authState.units,
                  onTap: () => Navigator.pushNamed(context, '/units'),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification',
                  subtitle: authState.isSignedIn ? authState.notification : 'Log in to manage',
                  onTap: () {
                    if (!authState.isSignedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to manage notifications')));
                    } else {
                      Navigator.pushNamed(context, '/notification');
                    }
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.settings_outlined,
                  title: 'Theme',
                  subtitle: authState.theme,
                  onTap: () => Navigator.pushNamed(context, '/theme'),
                ),

                const SizedBox(height: 8),

                // Legal Section
                _buildSectionHeader('Legal'),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Policy & Terms',
                  onTap: () {
                    if (!authState.isSignedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to manage policy and terms')));
                    } else {
                      Navigator.pushNamed(context, '/terms');
                    }
                  },
                ),

                const SizedBox(height: 8),

                // Support Section
                _buildSectionHeader('Support'),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help',
                  onTap: () => Navigator.pushNamed(context, '/help'),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                  onTap: () {
                    if (!authState.isSignedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to submit feedback')));
                    } else {
                      Navigator.pushNamed(context, '/feedback');
                    }
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About this app',
                  onTap: () => Navigator.pushNamed(context, '/about_app'),
                ),

                const SizedBox(height: 24),

                // Log Out at bottom
                if (authState.isSignedIn)
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to log out?'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  authState.signOut();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                child: const Text('Log Out'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Version footer
                const Center(
                  child: Text(
                    'Version 1.0 · Powered by Atmos',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 4),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final isDark = AuthState().theme == 'Dark Mode';
    final effectiveIconColor = iconColor ?? (isDark ? Colors.white54 : Colors.black54);
    final effectiveTextColor = textColor ?? (isDark ? Colors.white : Colors.black87);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 24, color: effectiveIconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: effectiveTextColor)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = AuthState().theme == 'Dark Mode';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
    );
  }
}
