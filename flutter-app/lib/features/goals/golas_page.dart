import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/network/url_data.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<dynamic> goals = [];
  bool loading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndGoals();
  }

  Future<void> _loadUserAndGoals() async {
    String? id = await storage.read(key: 'user_id');
    setState(() => userId = id);

    if (userId != null) {
      await _fetchGoals();
      await _checkAndNotifyGoals();
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _fetchGoals() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/goals/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          goals = data['goals'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching goals')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _checkAndNotifyGoals() async {
    if (userId == null) return;

    final today = DateTime.now();

    for (final goal in goals) {
      if (goal['target_date'] == null) continue;
      if (goal['notification_sent'] == true) continue;

      final targetDate = DateTime.parse(goal['target_date']);

      final isToday =
          targetDate.year == today.year &&
          targetDate.month == today.month &&
          targetDate.day == today.day;

      if (isToday) {
        await _sendGoalNotification(goal);
      }
    }
  }

  Future<void> _sendGoalNotification(Map<String, dynamic> goal) async {
    const String title = 'Goal Reminder';
    final String message =
        'Today is the deadline for your goal: ${goal['title'] ?? goal['goal_type'].replaceAll('_', ' ')}';

    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/notifications/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': int.parse(userId!),
          'notification_type': 'daily_reminder',
          'title': title,
          'message': message,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await http.patch(
          Uri.parse('$BASE_URL/api/goals/${goal['id']}/mark_notified'),
          headers: {'Content-Type': 'application/json'},
        );

        setState(() {
          goal['notification_sent'] = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
  }

  Future<void> _deleteGoal(int goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/api/goals/$goalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() => goals.removeWhere((g) => g['id'] == goalId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete goal')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markComplete(int goalId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/goals/$goalId/complete'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await _fetchGoals();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal marked as completed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete goal')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _openAddGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddGoalDialog(
        userId: userId!,
        onGoalAdded: () async {
          await _fetchGoals();
          await _checkAndNotifyGoals();
        },
      ),
    );
  }

  String _getTargetUnit(String goalType) {
    switch (goalType) {
      case 'money_saved':
        return 'DA';
      case 'smoke_free_days':
        return 'days';
      case 'reduce_daily':
        return 'cigarettes';
      case 'health_milestone':
        return 'points';
      default:
        return '';
    }
  }

  Color _getGoalCardColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'failed':
        return const Color(0xFFF44336);
      case 'paused':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFFFF8C00);
    }
  }

  IconData _getGoalIcon(String goalType) {
    switch (goalType) {
      case 'money_saved':
        return Icons.savings;
      case 'smoke_free_days':
        return Icons.smoke_free;
      case 'reduce_daily':
        return Icons.trending_down;
      case 'health_milestone':
        return Icons.health_and_safety;
      default:
        return Icons.flag;
    }
  }

  Color _getGoalTypeBackground(String goalType) {
    switch (goalType) {
      case 'money_saved':
        return const Color(0xFFFFF3E0);
      case 'smoke_free_days':
        return const Color(0xFFE8F5E9);
      case 'reduce_daily':
        return const Color(0xFFFFEBEE);
      case 'health_milestone':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  String _formatGoalType(String goalType) {
    return goalType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFF8C00)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Goals',
          style: TextStyle(
            color: Color(0xFFFF8C00),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF8C00)),
            onPressed: _fetchGoals,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF8C00)),
                  SizedBox(height: 16),
                  Text(
                    'Loading your goals...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ],
              ),
            )
          : goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No goals yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap the + button to create your first goal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF8C00),
                  onRefresh: _fetchGoals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      double progress = goal['progress_percentage']?.toDouble() ?? 0;
                      String unit = _getTargetUnit(goal['goal_type'] ?? '');
                      Color statusColor = _getGoalCardColor(goal['status'] ?? '');
                      String goalTitle = goal['title'] ?? _formatGoalType(goal['goal_type'] ?? '');
                      Color cardBackground = _getGoalTypeBackground(goal['goal_type'] ?? '');
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Top accent bar based on goal type
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: cardBackground.withOpacity(0.8),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: cardBackground,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getGoalIcon(goal['goal_type'] ?? ''),
                                          color: const Color(0xFFFF8C00),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    goalTitle,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    goal['status'].toString().toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusColor,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatGoalType(goal['goal_type'] ?? ''),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Progress section
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Progress',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            '${progress.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFF8C00),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Background
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            // Progress
                                            FractionallySizedBox(
                                              widthFactor: progress / 100,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF8C00),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Current: ${goal['current_value'] ?? 0} $unit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Target: ${goal['target_value'] ?? 0} $unit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Date and actions row
                                  Container(
                                    padding: const EdgeInsets.only(top: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey.withOpacity(0.15),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            goal['target_date'] != null
                                                ? 'Due: ${DateTime.parse(goal['target_date']).toLocal().toString().split(' ')[0]}'
                                                : 'No due date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (goal['status'] != 'completed')
                                          GestureDetector(
                                            onTap: () => _markComplete(goal['id']),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.check, size: 14, color: Colors.white),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Complete',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _deleteGoal(goal['id']),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.delete_outline, color: Colors.grey[600], size: 18),
                                          ),
                                        ),
                                      ],
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
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddGoalDialog,
        backgroundColor: const Color(0xFFFF8C00),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }
}

class AddGoalDialog extends StatefulWidget {
  final String userId;
  final VoidCallback onGoalAdded;
  const AddGoalDialog({super.key, required this.userId, required this.onGoalAdded});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController targetValueController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? startDate;
  DateTime? targetDate;
  bool submitting = false;

  final List<String> goalTypes = [
    'reduce_daily',
    'smoke_free_days',
    'money_saved',
    'health_milestone',
  ];

  final Map<String, IconData> goalTypeIcons = {
    'reduce_daily': Icons.trending_down,
    'smoke_free_days': Icons.smoke_free,
    'money_saved': Icons.savings,
    'health_milestone': Icons.health_and_safety,
  };

  final Map<String, String> goalTypeDescriptions = {
    'reduce_daily': 'Reduce daily cigarette consumption',
    'smoke_free_days': 'Maintain smoke-free days streak',
    'money_saved': 'Save money by reducing smoking',
    'health_milestone': 'Achieve health improvement milestones',
  };

  final Map<String, Color> goalTypeColors = {
    'reduce_daily': const Color(0xFFFFF3E0),
    'smoke_free_days': const Color(0xFFE8F5E9),
    'money_saved': const Color(0xFFFFEBEE),
    'health_milestone': const Color(0xFFE3F2FD),
  };

  String? selectedGoalType;

  String _unitForSelectedGoal() {
    switch (selectedGoalType) {
      case 'money_saved':
        return 'DA';
      case 'smoke_free_days':
        return 'days';
      case 'reduce_daily':
        return 'cigarettes/day';
      case 'health_milestone':
        return 'points';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGoalType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goal type')),
      );
      return;
    }
    if (targetValueController.text.isEmpty || int.tryParse(targetValueController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target value must be a number')),
      );
      return;
    }

    setState(() => submitting = true);
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/goals/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': int.parse(widget.userId),
          'goal_type': selectedGoalType,
          'title': titleController.text.isEmpty ? null : titleController.text,
          'target_value': int.parse(targetValueController.text),
          'start_date': startDate?.toIso8601String().split('T').first,
          'target_date': targetDate?.toIso8601String().split('T').first,
          'description': descriptionController.text.isEmpty ? null : descriptionController.text,
        }),
      );

      if (response.statusCode == 201) {
        widget.onGoalAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎯 Goal added successfully!')),
        );
      } else {
        var error = 'Unknown error';
        try {
          error = jsonDecode(response.body)['error'] ?? error;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => submitting = false);
    }
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8C00),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => startDate = picked);
    }
  }

  Future<void> _pickTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: targetDate ?? (startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8C00),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => targetDate = picked);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    targetValueController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flag, color: Color(0xFFFF8C00), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create New Goal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: submitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Goal Title
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title (Optional)',
                  hintText: 'Give your goal a name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.title, color: Color(0xFFFF8C00)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Goal Type
              const Text(
                'Goal Type *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: goalTypes.map((type) {
                    bool isSelected = selectedGoalType == type;
                    return GestureDetector(
                      onTap: () => setState(() => selectedGoalType = type),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF8C00) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF8C00) : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              goalTypeIcons[type],
                              size: 18,
                              color: isSelected ? Colors.white : const Color(0xFFFF8C00),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              if (selectedGoalType != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goalTypeColors[selectedGoalType]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        goalTypeIcons[selectedGoalType!],
                        size: 16,
                        color: const Color(0xFFFF8C00),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goalTypeDescriptions[selectedGoalType!]!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Target Value
              TextFormField(
                controller: targetValueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Value *',
                  hintText: 'Enter target ${_unitForSelectedGoal()}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                  ),
                  suffixText: selectedGoalType != null ? _unitForSelectedGoal() : null,
                  suffixStyle: const TextStyle(
                    color: Color(0xFFFF8C00),
                    fontWeight: FontWeight.bold,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.tablet, color: Color(0xFFFF8C00)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add more details about your goal...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.description, color: Color(0xFFFF8C00)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date Selection
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: startDate == null ? Colors.grey : const Color(0xFFFF8C00),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                startDate == null
                                    ? 'Start Date (Optional)'
                                    : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(
                                  color: startDate == null ? Colors.grey : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTargetDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag,
                              size: 18,
                              color: targetDate == null ? Colors.grey : const Color(0xFFFF8C00),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                targetDate == null
                                    ? 'Target Date (Optional)'
                                    : 'Target: ${targetDate!.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(
                                  color: targetDate == null ? Colors.grey : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create Goal',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}