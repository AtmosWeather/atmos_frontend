import 'package:flutter/material.dart';
import 'package:atmos_frontend/core/auth/auth_state.dart';

class PolicyTermsPage extends StatefulWidget {
  const PolicyTermsPage({super.key});

  @override
  State<PolicyTermsPage> createState() => _PolicyTermsPageState();
}

class _PolicyTermsPageState extends State<PolicyTermsPage> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checked = AuthState().acceptedTerms;
  }

  Future<void> _handleAgree() async {
    if (!_checked) return;
    await AuthState().acceptTerms();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You have accepted the policy and terms!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleDisagree() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You have disagreed to our Policy and Terms.'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, _) {
        final alreadyAccepted = AuthState().acceptedTerms;
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
            title: Text('Policy & Terms', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C1E00) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF5C4010) : Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'To utilize the Planner System and the AI Weather Assistant, you must read and agree to both our Privacy Policy and Terms of Use. We require this consent to securely store your personal tasks and process your questions through secure AI pathways.',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.orange.shade200 : Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Privacy Policy
            Text('1. Privacy Policy', style: TextStyle(fontSize: 20, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Atmos values your privacy. By using our services, we exclusively process the email you explicitly provide (for Firebase Auth) and the queries you text strictly bounded to weather topics. No other device data is ingested.\n\nYour planner entries are stored in an encrypted cloud database tied exclusively to your account email. We do not share, sell, or distribute your personal information to any third parties.',
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Terms of Use
            Text('2. Terms of Use', style: TextStyle(fontSize: 20, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'By checking the agreement box and interacting with our AI/Planner systems, you acknowledge that you are using this atmospheric information responsibly. You agree to not hold Atmos legally accountable for weather fluctuations resulting in incorrect forecast data.\n\nThe Planner functionality is designed for personal utility, and all entries are stored securely under your account keys. The AI assistant is bounded to weather-related topics only.',
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Checkbox
            if (!alreadyAccepted) ...[
              InkWell(
                onTap: () => setState(() => _checked = !_checked),
                child: Row(
                  children: [
                    Checkbox(
                      value: _checked,
                      activeColor: const Color(0xFF29B6F6),
                      onChanged: (val) => setState(() => _checked = val ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'I have read and understood the Privacy Policy and Terms of Use.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Agree / Disagree buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _handleDisagree,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('I Disagree', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _checked ? _handleAgree : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF29B6F6),
                          disabledBackgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('I Agree', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A2B14) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF1B4E29) : Colors.green.shade200),
                ),
                child: Center(
                  child: Text(
                    '✓ You have accepted the Policy & Terms.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.green.shade300 : Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () async {
                    await AuthState().revokeTerms();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('You have revoked your agreement to the Policy & Terms.'),
                          backgroundColor: Colors.orange.shade700,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Revoke Agreement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
      },
    );
  }
}
