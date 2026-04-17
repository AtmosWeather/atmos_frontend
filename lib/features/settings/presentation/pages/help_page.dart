import 'package:flutter/material.dart';

import 'package:atmos_frontend/core/auth/auth_state.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

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
            title: Text('App Help', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Welcome to Atmos Help!', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('You can navigate inside Atmos using the Bottom tab bar. Below is a quick overview of how our user services operate:', style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(height: 24),
              
              Text('Weather Home', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Easily search locations and check hourly forecasts. Make sure to tailor your UI using Settings -> Theme and set your preferred unit metric.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
              const SizedBox(height: 16),
              
              Text('Planner System', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Add tasks securely against your specific login. You will see a notification dot directly on the tab telling you how many remain active for completion.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
              const SizedBox(height: 16),
              
              Text('AI Weather Assistant', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('To effectively query the machine, simply type your question regarding climate issues. Requires agreeing to our User Policies inside Settings heavily checking chat moderation boundaries.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}
