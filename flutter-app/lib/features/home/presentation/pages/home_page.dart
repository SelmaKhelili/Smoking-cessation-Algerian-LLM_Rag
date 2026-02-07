import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/core/userdata/user_data.dart';
import 'package:my_app/features/goals/golas_page.dart';
import 'package:my_app/features/home/domain/models/notification_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../widgets/header_section.dart';
import '../widgets/stats_row.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/action_card.dart';
import '../widgets/quote_card.dart';
import '../widgets/check_in_flow.dart';
import 'notifications_page.dart';
import '../manager/home_cubit/home_cubit.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeCubit _homeCubit;
  int _unreadNotificationCount = 0;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Timer _notificationTimer;
  @override
  void initState() {
    super.initState();

    // Fetch user info
    UserData().fetchFromBackend().then((_) {
      setState(() {});
      _loadUnreadNotificationsCount(); // Load notifications after user data
    });

    // Create HomeCubit ONCE
    _homeCubit = HomeCubit();
    _startNotificationPolling();

    // Set up periodic refresh (optional)
    // Timer.periodic(Duration(minutes: 5), (timer) => _loadUnreadNotificationsCount());
  }
   @override
  void dispose() {
    _notificationTimer.cancel(); // Cancel timer when page is disposed
    super.dispose();
  }
   void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadUnreadNotificationsCount();
    });
  }
  Future<void> _loadUnreadNotificationsCount() async {
    try {
      // Get userId from secure storage
      final userIdString = await _secureStorage.read(key: 'user_id');
      
      if (userIdString != null && userIdString.isNotEmpty) {
        // Convert to int since your API expects int
        final userId = int.tryParse(userIdString);
        
        if (userId != null) {
          final count = await NotificationService.getUnreadCount(userId);
          if (mounted) {
            setState(() {
              _unreadNotificationCount = count;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading unread notifications count: $e');
      // Don't show error to user, just keep count as 0
    }
  }

  void _showCheckInDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => CheckInFlow(
        onComplete: () {
          // Refresh home data after check-in completes
          _homeCubit.loadHomeData();
        },
      ),
    );
  }

  // Function to navigate to notifications page
  void _navigateToNotifications() async {
    // Navigate to notification page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationPage(),
      ),
    );
    
    // Refresh unread count when returning from notifications page
    if (mounted) {
      await _loadUnreadNotificationsCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
              if (state.status == HomeStatus.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF8025)),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Updated HeaderSection with notification count
                    HeaderSection(
                      onNotificationTap: _navigateToNotifications,
                      unreadCount: _unreadNotificationCount,
                    ),
                    const SizedBox(height: 24),

                    StatsRow(
                      quitDays: state.quitDays,
                      cigarettesAvoided: state.cigarettesAvoided,
                      moneySaved: state.moneySaved,
                    ),

                    const SizedBox(height: 24),
                    CalendarStrip(
                      currentDate: state.currentDate,
                      moodData: state.moodData,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Daily check-in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Daily actions (UNCHANGED UI)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) /
                                      2.3,
                              child: ActionCard(
                                label: 'Check-in',
                                onTap: _showCheckInDialog,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) /
                                      2.3,
                              child: ActionCard(
                                label: 'Health check',
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.healthCheck),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) /
                                      2.3,
                              child: ActionCard(
                                label: 'Achievements',
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.achievements),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) /
                                      2.3,
                              child: ActionCard(
                                label: 'Goals',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const GoalPage()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    QuoteCard(quote: state.dailyQuote),
                    
                    const SizedBox(height: 24),
                    
                    // Subtle Emergency Section at the bottom with a little color
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFE0B2),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Small title with subtle color
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_hospital,
                                color: const Color(0xFFFF8C00).withOpacity(0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'أرقام الطوارئ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFFFF8C00).withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Emergency numbers in a single line with subtle color
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildSubtleNumberItem('16', 'الإسعاف'),
                              _buildSubtleNumberItem('1021', 'الحماية المدنية'),
                              _buildSubtleNumberItem('14', 'الإسعاف البديل'),
                              _buildSubtleNumberItem('112', 'من المحمول'),
                              _buildSubtleNumberItem('021-979898', 'مكافحة السموم'),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Very subtle note
                          Text(
                            'للاستخدام في حالات الطوارئ',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFFFF8C00).withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
  
  Widget _buildSubtleNumberItem(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFE0B2),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF8C00).withOpacity(0.8),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFFFF8C00).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}