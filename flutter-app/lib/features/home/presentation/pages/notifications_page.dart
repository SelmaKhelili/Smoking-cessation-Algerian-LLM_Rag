import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/core/network/url_data.dart';
import '../../domain/models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int? _userId; // Will be fetched from secure storage
  final String _baseUrl = '$BASE_URL/api/notifications'; // Replace with your backend URL

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchNotifications();
  }

  Future<void> _loadUserIdAndFetchNotifications() async {
    String? storedUserId = await _secureStorage.read(key: 'user_id');
    if (storedUserId == null) {
      // Handle missing user ID
      debugPrint('No user_id found in secure storage');
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _userId = int.tryParse(storedUserId);
    });

    if (_userId != null) {
      await _fetchNotifications();
    } else {
      debugPrint('Invalid user_id in secure storage');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/?user_id=$_userId&per_page=100'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List notificationsJson = data['notifications'] ?? [];
        setState(() {
          _notifications = notificationsJson
              .map((e) => NotificationModel.fromJson(e))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint('Failed to load notifications: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching notifications: $e');
    }
  }



  Future<void> _markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/read-all?user_id=$_userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          for (var note in _notifications) {
            note.isRead = true;
          }
        });
      } else {
        debugPrint('Failed to mark all as read: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _markAsRead(int index) async {
    final note = _notifications[index];
    if (note.isRead) return;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${note.id}/read'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications[index].isRead = true;
        });
      } else {
        debugPrint('Failed to mark notification as read: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Map<String, List<NotificationModel>> _groupNotifications() {
    Map<String, List<NotificationModel>> groups = {};
    for (var note in _notifications) {
      if (!groups.containsKey(note.section)) {
        groups[note.section] = [];
      }
      groups[note.section]!.add(note);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final groupedNotes = _groupNotifications();
    final sections = groupedNotes.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFFFF8025), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFFFF8025),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          final sectionTitle = sections[sectionIndex];
          final notesInSection = groupedNotes[sectionTitle]!;

          final isToday = sectionTitle == 'Today';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: sectionTitle,
                hasAction: isToday,
                onActionTap: isToday ? _markAllAsRead : null,
              ),
              ...notesInSection.map((note) {
                final mainIndex = _notifications.indexOf(note);
                return _NotificationItemWidget(
                  item: note,
                  onTap: () => _markAsRead(mainIndex),
                );
              }),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

// --- WIDGETS ---

class _NotificationItemWidget extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationItemWidget({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: !item.isRead ? const Color(0xFFFFF8E1) : Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8025),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool hasAction;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.hasAction = false,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFD48C00),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (hasAction)
            GestureDetector(
              onTap: onActionTap,
              child: const Text(
                'Mark all',
                style: TextStyle(
                  color: Color(0xFFFF8025),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
