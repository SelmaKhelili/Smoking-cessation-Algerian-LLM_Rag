import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/features/splash/presentation/pages/welcome_page.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_menu_item.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'privacy_policy_page.dart';
import 'help_center_page.dart';

class ProfilePage extends StatefulWidget {
  final Function(int)? onNavigate;
  const ProfilePage({super.key, this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // Your exact logout method
  Future<bool> _logoutUser(BuildContext context) async {
    const storage = FlutterSecureStorage();
    
    try {
      // Just clear local storage (simpler approach)
      await storage.deleteAll();
      print('Local storage cleared - user logged out');
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
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
                'Logout',
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
                'Are you sure you want to log out?',
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
                          backgroundColor: const Color.fromARGB(255, 235, 219, 78),
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
                  
                  // Yes, Logout Button
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
                        onPressed: () async {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF8025),
                              ),
                            ),
                          );
                          
                          // Call your logout method
                          final success = await _logoutUser(context);
                          
                          // Close loading dialog
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading dialog
                            Navigator.pop(context); // Close bottom sheet
                            
                            if (success) {
                              // Navigate to Welcome Page
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const WelcomePage()),
                                (route) => false,
                              );
                            } else {
                              // Show error message (optional)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not log out. Please try again.'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Yes, Logout',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
          children: [
            const SizedBox(height: 60),
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'My Profile',
                    style: TextStyle(
                      color: Color(0xFFFF8025),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                child: Column(
                  children: [
                    const ProfileAvatar(),
                    const SizedBox(height: 40),

            ProfileMenuItem(
              icon: Icons.person_outline,
              text: 'Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
            ),
            const SizedBox(height: 16),

            ProfileMenuItem(
              icon: Icons.privacy_tip_outlined,
              text: 'Privacy Policy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),
            const SizedBox(height: 16),

            ProfileMenuItem(
              icon: Icons.settings_outlined,
              text: 'Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
            const SizedBox(height: 16),

            ProfileMenuItem(
              icon: Icons.help_outline,
              text: 'Help',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterPage()),
              ),
            ),
            const SizedBox(height: 16),

            ProfileMenuItem(
              icon: Icons.logout,
              text: 'Logout',
              isLogout: true,
              onTap: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
              ),
            ),
          ],
        ),
    );
  }
}