import 'package:flutter/material.dart';
import 'package:my_app/features/auth/presentation/pages/set_password_page.dart';
import 'package:my_app/features/splash/presentation/pages/welcome_page.dart';
import 'placeholder_page.dart';
import 'notifications_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF8025), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFFFF8025),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // Top Divider
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFE0E0E0)),

            _SettingsItem(
              icon: Icons.notifications_none_outlined,
              text: 'Notification Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
              ),
            ),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFE0E0E0)),

            _SettingsItem(
              icon: Icons.smart_toy_outlined, // Changed to a more relevant icon if you like, or keep vpn_key
              text: 'Chatbot Settings',
              // Fixed: Empty closure that does nothing
              onTap: () {},
            ),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFE0E0E0)),

            _SettingsItem(
              icon: Icons.vpn_key_outlined,
              text: 'Password Manager',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SetPasswordPage()),
              ),
            ),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFE0E0E0)),

            _SettingsItem(
              icon: Icons.account_circle_outlined,
              text: 'Delete Account',
              // Updated: Calls the bottom sheet confirmation
              onTap: () => _showDeleteConfirmation(context),
            ),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFE0E0E0)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional Handle bar for visual cue
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Delete Account',
                style: TextStyle(
                  color: Color(0xFFFF8025),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Divider
              Divider(color: Colors.grey[200], thickness: 1),
              const SizedBox(height: 16),

              // Message
              const Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Buttons Row
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF48F), // Yellowish tone
                          foregroundColor: const Color(0xFFFF8025),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Yes, Delete Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8025),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          // Close the bottom sheet
                          Navigator.pop(context);
                          // Navigate to Welcome Page (simulating account deletion)
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const WelcomePage()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Yes, Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Placeholder helper logic - kept if you need it elsewhere
  void _navTo(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceholderPage(title: title)),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF8025),
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Color(0xFFFF8025),
            ),
          ],
        ),
      ),
    );
  }
}
