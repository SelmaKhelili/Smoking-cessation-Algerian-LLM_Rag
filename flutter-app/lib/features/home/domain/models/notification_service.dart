import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/url_data.dart';

class NotificationService {
  // Get unread count using /unread endpoint
  static Future<int> getUnreadCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/notifications/unread?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0; // Your API returns {'count': number}
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Alternative: Get unread count using /statistics endpoint
  static Future<int> getUnreadCountFromStatistics(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/notifications/statistics/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['statistics']['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Get all notifications (your existing method)
  static Future<List<dynamic>> getNotifications(int userId) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/notifications/?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'];
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(int notificationId) async {
    final response = await http.put(
      Uri.parse('$BASE_URL/api/notifications/$notificationId/read'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead(int userId) async {
    final response = await http.put(
      Uri.parse('$BASE_URL/api/notifications/read-all?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }
}