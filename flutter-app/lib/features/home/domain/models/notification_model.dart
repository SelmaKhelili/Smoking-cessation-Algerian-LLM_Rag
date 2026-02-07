import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String time; // You can format this later
  final IconData icon;
  final String section; // e.g., "Today", "Yesterday"
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.section,
    this.isRead = false,
  });

  // Factory constructor to create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
    String sectionLabel = _generateSectionLabel(createdAt);

    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      body: json['message'] ?? '',
      time: _formatTime(createdAt),
      icon: Icons.notifications, // You can later map type to icon
      section: sectionLabel,
      isRead: json['is_read'] ?? false,
    );
  }

  // Helper to generate section like "Today", "Yesterday"
  static String _generateSectionLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${date.day} ${_monthName(date.month)}';
  }

  // Simple formatter for display
  static String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes} M';
    if (difference.inHours < 24) return '${difference.inHours} H';
    return '${difference.inDays} D';
  }

  // Helper to convert month number to name
  static String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}
