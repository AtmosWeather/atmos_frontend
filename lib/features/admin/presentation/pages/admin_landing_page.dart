import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:atmos_frontend/core/config/api_config.dart';

import 'package:atmos_frontend/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/manage_users_page.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/weather_updates_admin.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/admin_activities_page.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/admin_feedback_page.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/admin_settings_page.dart';

class AdminLandingPage extends StatefulWidget {
  const AdminLandingPage({super.key});

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _timer;

  final List<Widget> _pages = const [
    AdminDashboard(),
    WeatherUpdatesAdminPage(),
    AdminActivitiesPage(),
    ManageUsersPage(),
    AdminFeedbackPage(),
    AdminSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/feedback'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final messages = data['data'] as List;
        int count = messages.where((msg) => msg['status'] == 'unread').length;
        if (mounted && count != _unreadCount) {
          setState(() {
            _unreadCount = count;
          });
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          border: Border(
            top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 4) {
              _fetchUnreadCount();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFEEEEEE),
          selectedItemColor: const Color(0xFF29B6F6),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'News',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Activities',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: _unreadCount > 0
                  ? Badge(
                      label: Text('$_unreadCount'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.mail),
                    )
                  : const Icon(Icons.mail),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

