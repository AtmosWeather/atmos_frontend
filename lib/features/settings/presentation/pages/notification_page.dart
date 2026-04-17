import 'package:flutter/material.dart';
import 'package:atmos_frontend/core/auth/auth_state.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, child) {
        final state = AuthState();
        final isOn = state.notification == 'On';
        final isDark = state.theme == 'Dark Mode';
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white70 : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Notification', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Determine whether the app will send push alerts directly to your device.', style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => state.updateSettingNotification(isOn ? 'Off' : 'On'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Allow Notifications', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Displays tasks and news.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isOn,
                        activeTrackColor: const Color(0xFF29B6F6),
                        onChanged: (val) => state.updateSettingNotification(val ? 'On' : 'Off'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
