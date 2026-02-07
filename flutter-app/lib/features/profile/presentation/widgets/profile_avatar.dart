import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_app/core/userdata/user_data.dart'; 

import '../pages/edit_profile_page.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                // Listen to Image Changes
                child: ValueListenableBuilder<String>(
                  valueListenable: UserData().imagePath,
                  builder: (context, path, _) {
                    
                    // CHECK: Is it default/empty?
                    bool isDefault = path.isEmpty || path == "default";

                    if (isDefault) {
                      // SHOW DEFAULT ICON
                      return const CircleAvatar(
                        backgroundColor: Color(0xFFDCE8FF), // Light blue background matching header
                        radius: 50,
                        child: Icon(
                          Icons.person, 
                          size: 50, 
                          color: Color(0xFF2775FF) // Blue icon matching header
                        ),
                      );
                    } else {
                      // SHOW IMAGE
                      ImageProvider imgProvider;
                      if (path.startsWith('assets/')) {
                        imgProvider = AssetImage(path);
                      } else {
                        imgProvider = FileImage(File(path));
                      }
                      
                      return CircleAvatar(
                        backgroundColor: Colors.grey,
                        backgroundImage: imgProvider,
                        radius: 50,
                      );
                    }
                  },
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const EditProfilePage())
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8025),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        ValueListenableBuilder<String>(
          valueListenable: UserData().name,
          builder: (context, name, _) {
            return Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            );
          },
        ),
      ],
    );
  }
}
