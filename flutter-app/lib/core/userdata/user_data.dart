import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/core/network/url_data.dart';

class UserData {
  static final UserData _instance = UserData._internal();
  factory UserData() => _instance;
  UserData._internal();

  final ValueNotifier<String> imagePath = ValueNotifier(""); // Starts with Icon
  final ValueNotifier<String> name = ValueNotifier("Guessoum");
  final ValueNotifier<String> email = ValueNotifier("ahmed@example.com");
  final ValueNotifier<String> phone = ValueNotifier("+213 0545077501");
  final ValueNotifier<String> dob = ValueNotifier("12/05/1999");

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Fetch user info from backend
  Future<void> fetchFromBackend() async {
    try {
      String? userIdStr = await storage.read(key: 'user_id');
      if (userIdStr == null) return;
      final userId = int.tryParse(userIdStr);
      if (userId == null) return;

      final response = await http.get(
        Uri.parse("$BASE_URL/api/user/profile/$userId"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final profile = data['profile'];

        name.value = user['username'] ?? name.value;
        email.value = user['email'] ?? email.value;
        phone.value = user['phone_number'] ?? phone.value;
        dob.value = user['date_of_birth'] ?? dob.value;
        imagePath.value = profile?['profile_picture_url'] ?? imagePath.value;

      } else {
        print("Failed to fetch user profile: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  // Update locally and backend - Now returns error message if any
  Future<Map<String, dynamic>> updateBackend({
    required String newName,
    required String newEmail,
    required String newPhone,
    required String newDob,
    String? newImagePath,
  }) async {
    try {
      String? userIdStr = await storage.read(key: 'user_id');
      if (userIdStr == null) return {'success': false, 'error': 'User not found'};
      final userId = int.tryParse(userIdStr);
      if (userId == null) return {'success': false, 'error': 'Invalid user ID'};

      final body = {
        "username": newName.trim(),
        "email": newEmail.trim(),
        "phone_number": newPhone,
        "date_of_birth": newDob,
        "profile_picture_url": newImagePath,
      };

      final response = await http.put(
        Uri.parse("$BASE_URL/api/user/profile/$userId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Update locally only if backend update succeeds
        name.value = newName;
        email.value = newEmail;
        phone.value = newPhone;
        dob.value = newDob;
        if (newImagePath != null) {
          imagePath.value = newImagePath;
        }
        
        print("User profile updated on backend successfully");
        return {'success': true, 'message': 'Profile updated successfully'};
        
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to update profile';
        final field = errorData['field']; // Get the specific field that failed
        
        print("Failed to update user profile: $errorMessage");
        return {
          'success': false, 
          'error': errorMessage,
          'field': field
        };
      }
    } catch (e) {
      print("Error updating user profile: $e");
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }
}