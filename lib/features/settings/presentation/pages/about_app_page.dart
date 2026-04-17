import 'package:flutter/material.dart';
import 'package:atmos_frontend/core/auth/auth_state.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, _) {
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
              'About this App',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 45, height: 45, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const Icon(Icons.cloud_circle, size: 80, color: Color(0xFF29B6F6)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Atmos',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(
                  child: Text(
                    'Version 1.0',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Services',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildServiceItem(
                  Icons.sunny,
                  'Weather Forecasts',
                  'Get accurate hyper-local current conditions and forecasts to plan your day.',
                  isDark: isDark,
                ),
                _buildServiceItem(
                  Icons.calendar_today,
                  'Personal Planner',
                  'Keep track of your tasks and boards seamlessly integrated with your daily weather.',
                  isDark: isDark,
                ),
                _buildServiceItem(
                  Icons.smart_toy,
                  'AI Assistant',
                  'Your intelligent companion for weather predictions and atmospheric advice.',
                  isDark: isDark,
                ),
                _buildServiceItem(
                  Icons.article,
                  'Alerts & News',
                  'Stay up to date with urgent weather alerts and administrative announcements.',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String description, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF29B6F6), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
