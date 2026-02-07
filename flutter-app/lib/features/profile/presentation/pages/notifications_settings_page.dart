import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // State for toggles
  bool _generalNotification = true;
  bool _sound = false;
  bool _soundCall = false;
  bool _vibrate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF8025), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Color(0xFFFF8025),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            _NotificationItem(
              title: 'General Notification',
              value: _generalNotification,
              onChanged: (val) => setState(() => _generalNotification = val),
            ),
            const SizedBox(height: 32), // Generous spacing

            _NotificationItem(
              title: 'Sound',
              value: _sound,
              onChanged: (val) => setState(() => _sound = val),
            ),
            const SizedBox(height: 32),

            _NotificationItem(
              title: 'Sound Call',
              value: _soundCall,
              onChanged: (val) => setState(() => _soundCall = val),
            ),
            const SizedBox(height: 32),

            _NotificationItem(
              title: 'Vibrate',
              value: _vibrate,
              onChanged: (val) => setState(() => _vibrate = val),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationItem({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18, // Slightly larger text
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        // Custom scaled switch to match design size
        Transform.scale(
          scale: 0.9, 
          child: Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFFF8025); // Orange Active
              }
              return const Color(0xFFD9D9D9); // Light Grey Inactive
            }),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent), // Remove border
          ),
        ),
      ],
    );
  }
}
