import 'package:flutter/material.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/manage_users_page.dart';
import 'package:atmos_frontend/features/admin/presentation/pages/weather_updates_admin.dart';

class AdminLandingPage extends StatefulWidget {
  const AdminLandingPage({super.key});

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  int _currentIndex = 0;



  final List<Widget> _pages = const [
    AdminDashboard(),
    WeatherUpdatesAdminPage(),
    ManageUsersPage(),
  ];

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
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFEEEEEE),
          selectedItemColor: const Color(0xFF29B6F6),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}
