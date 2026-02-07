import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_app/core/userdata/user_data.dart'; 

class HeaderSection extends StatelessWidget {
  final VoidCallback onNotificationTap;
  final int unreadCount;

  const HeaderSection({
    super.key, 
    required this.onNotificationTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          // --- PROFILE IMAGE LOGIC ---
          ValueListenableBuilder<String>(
            valueListenable: UserData().imagePath,
            builder: (context, path, _) {
              
              // CHECK: Is it the default/empty state?
              // You can change "assets/images/profile_ahmed.jpg" to "" in UserData if you want to start with an Icon
              bool isDefault = path.isEmpty || path == "default"; 

              if (isDefault) {
                // SHOW DEFAULT ICON
                return Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCE8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF2775FF), size: 32),
                );
              } else {
                // SHOW SELECTED IMAGE
                ImageProvider imgProvider;
                if (path.startsWith('assets/')) {
                  imgProvider = AssetImage(path);
                } else {
                  imgProvider = FileImage(File(path));
                }

                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE8FF),
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imgProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }
            },
          ),
          // --- END PROFILE IMAGE LOGIC ---

          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: UserData().name,
                  builder: (context, name, _) {
                    return Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onNotificationTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8025), // Same orange color
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Unread notification badge - shows only when unreadCount > 0
              if (unreadCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}