import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/url_data.dart';

class ChatBackendService {
  // Use Flask backend URL from url_data.dart
  static const String baseUrl = BASE_URL; // http://10.54.58.29:5000
  
  /// Create a new chat session for a user
  Future<Map<String, dynamic>> createSession(int userId, {String? title}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'session_title': title,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }
  
  /// Get all chat sessions for a user
  Future<List<dynamic>> getSessions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/sessions?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sessions'] as List<dynamic>;
      } else {
        throw Exception('Failed to get sessions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting sessions: $e');
    }
  }
  
  /// Send a message and get AI response (saves to database automatically)
  Future<Map<String, dynamic>> sendMessage(int sessionId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'message': message,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
  
  /// Get all messages in a chat session
  Future<Map<String, dynamic>> getMessages(int sessionId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/sessions/$sessionId/messages?page=$page'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get messages: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting messages: $e');
    }
  }
  
  /// Get chat statistics for a user
  Future<Map<String, dynamic>> getChatStatistics(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/statistics/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting statistics: $e');
    }
  }
  
  /// Delete a chat session
  Future<void> deleteSession(int sessionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/sessions/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting session: $e');
    }
  }
  
  /// Update session title
  Future<void> updateSessionTitle(int sessionId, String newTitle) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/chat/sessions/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_title': newTitle,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating session: $e');
    }
  }
}
