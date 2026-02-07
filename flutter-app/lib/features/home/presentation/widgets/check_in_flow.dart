import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/url_data.dart';


class CheckInFlow extends StatefulWidget {
  final VoidCallback? onComplete;
  const CheckInFlow({super.key, this.onComplete});

  @override
  State<CheckInFlow> createState() => _CheckInFlowState();
}

class _CheckInFlowState extends State<CheckInFlow> {
  int _currentStep = 0;

  String _selectedMood = 'Depressed';
  int _sleepHours = 8;
  int _cigarettesSmoked = 10;

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _close() async {
    await _submitCheckIn();
    Navigator.of(context).pop();
  }

  Future<int?> _getUserId() async {
    String? userIdStr = await storage.read(key: 'user_id');
    if (userIdStr != null) {
      return int.tryParse(userIdStr);
    }
    return null;
  }

  Future<void> _submitCheckIn() async {
    int? userId = await _getUserId();
    if (userId == null) return;

    String recordUrl = '$BASE_URL/api/tracking/record';
    Map<String, dynamic> payload = {
      'user_id': userId,
      'record_date': DateTime.now().toIso8601String().split('T')[0],
      'cigarettes_smoked': _cigarettesSmoked,
      'cravings_count': 0,
      'mood': _selectedMood,
      'notes': 'Check-in submitted from app',
    };

    try {
      final response = await http.post(
        Uri.parse(recordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        print('Record created successfully');
      } else if (response.statusCode == 400 &&
          response.body.contains('Record already exists')) {
        print('Record exists, updating instead...');
        await _updateRecord(userId);
      } else {
        print('Error submitting record: ${response.body}');
        return;
      }

      await _checkAchievements(userId);

      // Notify parent to refresh
      widget.onComplete?.call();
    } catch (e) {
      print('Exception submitting check-in: $e');
    }
  }

  Future<void> _checkAchievements(int userId) async {
    String url = '$BASE_URL/api/achievements/check';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newlyEarned = data['newly_earned'] as List;
        if (newlyEarned.isNotEmpty) {
          print('Newly earned achievements: $newlyEarned');
        }
      }
    } catch (e) {
      print('Exception checking achievements: $e');
    }
  }

  Future<void> _updateRecord(int userId) async {
    String getRecordsUrl = '$BASE_URL/api/tracking/records/$userId';
    try {
      final getResponse = await http.get(Uri.parse(getRecordsUrl));
      if (getResponse.statusCode == 200) {
        final records = jsonDecode(getResponse.body)['records'];
        final today = DateTime.now().toIso8601String().split('T')[0];

        final todayRecord = records.firstWhere(
          (r) => r['record_date'] == today,
          orElse: () => null,
        );

        if (todayRecord != null) {
          String updateUrl =
              '$BASE_URL/api/tracking/records/update/${todayRecord['id']}';

          Map<String, dynamic> updatePayload = {
            'cigarettes_smoked': _cigarettesSmoked,
            'mood': _selectedMood,
          };

          final updateResponse = await http.put(
            Uri.parse(updateUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatePayload),
          );

          if (updateResponse.statusCode == 200) {
            print('Record updated successfully');
          }
        }
      }
    } catch (e) {
      print('Exception in updating record: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5FA),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _WelcomeStep(onStart: _nextStep);
      case 1:
        return _MoodStep(
          onConfirm: _nextStep,
          initialMood: _selectedMood,
          onMoodChanged: (val) => _selectedMood = val,
        );
      case 2:
        return _SleepStep(
          onConfirm: _nextStep,
          initialValue: _sleepHours,
          onChanged: (val) => _sleepHours = val,
        );
      case 3:
        return _CigaretteStep(
          onConfirm: _nextStep,
          initialValue: _cigarettesSmoked,
          onChanged: (val) => _cigarettesSmoked = val,
        );
      case 4:
        return _CompletionStep(onConfirm: _close);
      default:
        return const SizedBox.shrink();
    }
  }
}



// --- STEP 1: WELCOME ---
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomeStep({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0A1A30)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Are you ready for your another day of fighting!',
          style: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400, color: Color(0xFF5A6B80)),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onStart,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B6EB9), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: const Text(
              'Start Check in',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B6EB9)),
            ),
          ),
        ),
      ],
    );
  }
}

// --- STEP 2: MOOD ---
class _MoodStep extends StatefulWidget {
  final VoidCallback onConfirm;
  final String initialMood;
  final ValueChanged<String> onMoodChanged;

  const _MoodStep({required this.onConfirm, required this.initialMood, required this.onMoodChanged});

  @override
  State<_MoodStep> createState() => _MoodStepState();
}

class _MoodStepState extends State<_MoodStep> {
  late String _mood;
  final List<String> _moods = ['Depressed', 'Sad', 'Happy', 'Angry'];
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _mood = widget.initialMood;
    _currentIndex = _moods.indexOf(_mood);
    if (_currentIndex == -1) _currentIndex = 2;
  }

  void _changeMood(int delta) {
    setState(() {
      int newIndex = _currentIndex + delta;
      if (newIndex < 0) {
        newIndex = _moods.length - 1;
      } else if (newIndex >= _moods.length) newIndex = 0;
      _currentIndex = newIndex;
      _mood = _moods[_currentIndex];
      widget.onMoodChanged(_mood);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('How are you feeling today?', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontStyle: FontStyle.italic, fontFamily: 'Cursive', color: Color(0xFF0A1A30))),
        const SizedBox(height: 40),
        Container(
          width: 160, height: 160,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Image.asset(_getMoodImagePath(_mood), fit: BoxFit.contain),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavArrow(icon: Icons.chevron_left, onTap: () => _changeMood(-1)),
            Text(_mood, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF0A1A30))),
            _NavArrow(icon: Icons.chevron_right, onTap: () => _changeMood(1)),
          ],
        ),
        const SizedBox(height: 40),
        _ConfirmButton(onPressed: widget.onConfirm),
      ],
    );
  }

  String _getMoodImagePath(String mood) {
    switch (mood) {
      case 'Depressed': return 'assets/icons/mood_depressed.png';
      case 'Sad': return 'assets/icons/mood_sad.png';
      case 'Happy': return 'assets/icons/mood_happy.png';
      case 'Angry': return 'assets/icons/mood_angry.png';
      default: return 'assets/icons/mood_happy.png';
    }
  }
}

// --- STEP 3: SLEEP ---
class _SleepStep extends StatefulWidget {
  final VoidCallback onConfirm;
  final int initialValue;
  final ValueChanged<int> onChanged;

  const _SleepStep({required this.onConfirm, required this.initialValue, required this.onChanged});

  @override
  State<_SleepStep> createState() => _SleepStepState();
}

class _SleepStepState extends State<_SleepStep> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _increment(int delta) {
    setState(() {
      _value = (_value + delta).clamp(0, 12); // Max 12 hours (half a day)
      widget.onChanged(_value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total flames to show
    final totalFlames = _value > 8 ? _value : 8;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How many hours did you sleep\ntoday?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontFamily: 'Cursive',
            color: Color(0xFF0A1A30),
          ),
        ),
        const SizedBox(height: 40),
        
        // Flame grid (4x3 = 12 max)
        SizedBox(
          width: 240,
          height: 180,
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(totalFlames, (index) {
                // First _value flames are full opacity
                // Remaining (up to 8 total) are 50% opacity
                final opacity = index < _value ? 1.0 : 0.5;
                
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: opacity,
                  child: Image.asset(
                    'assets/icons/hours_slept.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                );
              }),
            ),
          ),
        ),
        
        const SizedBox(height: 50),
        _CounterRow(
          value: _value,
          onIncrement: () => _increment(1),
          onDecrement: () => _increment(-1),
        ),
        const SizedBox(height: 40),
        _ConfirmButton(onPressed: widget.onConfirm),
      ],
    );
  }
}

// --- STEP 4: CIGARETTES ---
class _CigaretteStep extends StatefulWidget {
  final VoidCallback onConfirm;
  final int initialValue;
  final ValueChanged<int> onChanged;

  const _CigaretteStep({required this.onConfirm, required this.initialValue, required this.onChanged});

  @override
  State<_CigaretteStep> createState() => _CigaretteStepState();
}

class _CigaretteStepState extends State<_CigaretteStep> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _increment(int delta) {
    setState(() {
      _value = (_value + delta).clamp(0, 25); // Max 25 cigarettes
      widget.onChanged(_value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How many cigarettes did you smoke\ntoday?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontFamily: 'Cursive',
            color: Color(0xFF0A1A30),
          ),
        ),
        const SizedBox(height: 20),
        
        // Cigarette grid - shows exactly _value cigarettes
        SizedBox(
          width: 320,
          height: 260,
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 0,
              runSpacing: 0,
              children: List.generate(_value, (index) {
                return Image.asset(
                  'assets/icons/cigarettes_smoked.png',
                  width: 55,
                  height: 65,
                  fit: BoxFit.contain,
                );
              }),
            ),
          ),
        ),
        
        const SizedBox(height: 55),
        _CounterRow(
          value: _value,
          onIncrement: () => _increment(1),
          onDecrement: () => _increment(-1),
        ),
        const SizedBox(height: 40),
        _ConfirmButton(onPressed: widget.onConfirm),
      ],
    );
  }
}

// --- STEP 5: COMPLETION ---
class _CompletionStep extends StatelessWidget {
  final VoidCallback onConfirm;

  const _CompletionStep({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Good Job completing your daily\ncheck!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Cursive', // Or standard font if preferred
            fontStyle: FontStyle.italic,
            color: Color(0xFF0A1A30),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 40),
        
        // Checkmark Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF8025), width: 8), // Thick Orange Border
          ),
          child: const Icon(
            Icons.check,
            size: 60,
            color: Color(0xFFFF8025), // Orange Check
          ),
        ),
        
        const SizedBox(height: 60),
        
        // Custom Confirm Button (Blue outline, blue text to match design)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onConfirm,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B6EB9), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: Colors.white, // White background
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B6EB9)),
            ),
          ),
        ),
      ],
    );
  }
}

// --- REUSABLE COMPONENTS ---
class _ConfirmButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ConfirmButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1B6EB9), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B6EB9))),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
        child: Icon(icon, color: const Color(0xFF1B6EB9), size: 24),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterRow({required this.value, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleButton(icon: Icons.remove, onTap: onDecrement),
        Text(value.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0A1A30))),
        _CircleButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48, height: 48,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
        child: Icon(icon, color: const Color(0xFF1B6EB9), size: 28),
      ),
    );
  }
}
