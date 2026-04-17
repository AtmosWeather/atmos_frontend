import 'package:flutter/material.dart';
import 'package:atmos_frontend/core/auth/auth_state.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, child) {
        final state = AuthState();
        final isDark = state.theme == 'Dark Mode';
        final selected = state.theme;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white70 : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Theme', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Control weather display theme settings. Light mode is the default.', style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(height: 24),
              _buildOption(
                context,
                title: 'Light Mode',
                value: 'Light Mode',
                selected: selected,
                isDark: isDark,
                onTap: () => state.updateSettingTheme('Light Mode'),
              ),
              Divider(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
              _buildOption(
                context,
                title: 'Dark Mode',
                value: 'Dark Mode',
                selected: selected,
                isDark: isDark,
                onTap: () => state.updateSettingTheme('Dark Mode'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(BuildContext context, {required String title, required String value, required String selected, required bool isDark, required VoidCallback onTap}) {
    final isSelected = value == selected;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF29B6F6) : (isDark ? Colors.white54 : Colors.grey)),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF29B6F6) : (isDark ? Colors.white : Colors.black87))),
          ],
        ),
      ),
    );
  }
}
