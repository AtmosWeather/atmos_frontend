import 'package:flutter/material.dart';
import 'package:atmos_frontend/core/auth/auth_state.dart';

class UnitsPage extends StatelessWidget {
  const UnitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, child) {
        final state = AuthState();
        final selected = state.units;
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
            title: Text('Units', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Select your preferred units across the Atmos app.', style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(height: 24),
              _buildOption(
                context,
                title: 'Metric Systems',
                subtitle: '°C, mm, km, kmph, hPa, 12 h',
                value: '°C, mm, km, kmph, hPa, 12 h',
                selected: selected,
                isDark: isDark,
                onTap: () => state.updateSettingUnits('°C, mm, km, kmph, hPa, 12 h'),
              ),
              Divider(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
              _buildOption(
                context,
                title: 'Imperial Systems',
                subtitle: '°F, in, mi, mph, inHg, 12 h',
                value: '°F, in, mi, mph, inHg, 12 h',
                selected: selected,
                isDark: isDark,
                onTap: () => state.updateSettingUnits('°F, in, mi, mph, inHg, 12 h'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(BuildContext context, {required String title, required String subtitle, required String value, required String selected, required bool isDark, required VoidCallback onTap}) {
    final isSelected = value == selected;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF29B6F6) : (isDark ? Colors.white54 : Colors.grey)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF29B6F6) : (isDark ? Colors.white : Colors.black87))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
