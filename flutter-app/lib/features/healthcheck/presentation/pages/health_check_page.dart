import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/url_data.dart';
import '../models/option_item.dart';
import '../widgets/option_selector.dart';
import '../widgets/question_section.dart';


class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  // 1. State variables
  String? _coughOption;
  String? _throatOption;
  String? _tiredOption;
  String? _headacheOption;
  String? _appetiteOption;
  String? _dizzinessOption;
  String? _betterWorseOption;

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // 2. Calculate progress based on non-null values
  double get _progress {
    final answers = [
      _coughOption,
      _throatOption,
      _tiredOption,
      _headacheOption,
      _appetiteOption,
      _dizzinessOption,
      _betterWorseOption,
    ];
    int answeredCount = answers.where((a) => a != null).length;
    return answeredCount / 7.0;
  }

  Future<void> _submitHealthCheck() async {
    try {
      // Get user_id from secure storage
      String? userId = await storage.read(key: 'user_id');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      // Prepare health data
      Map<String, dynamic> healthData = {
        'health_conditions': jsonEncode({
          'cough': _coughOption,
          'throat': _throatOption,
          'tired': _tiredOption,
          'headache': _headacheOption,
          'appetite': _appetiteOption,
          'dizziness': _dizzinessOption,
          'better_worse': _betterWorseOption,
        }),
      };

      // Send PUT request to backend
      final response = await http.put(
        Uri.parse('$BASE_URL/api/user/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health check submitted successfully.')),
        );
        Navigator.pop(context);
      } else {
        var error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting data: $e')),
      );
    }
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2775FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Health Check',
          style: TextStyle(
            color: Color(0xFF2775FF),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arabic Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'قل لنا عن أعراضك حتى نتمكن من\nمساعدتك بشكلٍ أفضل.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.monitor_heart_outlined,
                      color: Color(0xFFFF8025), size: 32),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Animated Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCirc,
                tween: Tween<double>(begin: 0, end: _progress),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFFE5EEFF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2775FF)),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Questions List
            QuestionSection(
              question: 'Any Cough Or Chest Discomfort Today?',
              child: OptionSelector(
                options: const [
                  OptionItem(label: 'No', icon: '🚫', value: 'No'),
                  OptionItem(label: 'A Little', icon: '😐', value: 'A Little'),
                  OptionItem(label: 'A Lot', icon: '😷', value: 'A Lot'),
                ],
                selectedValue: _coughOption,
                onChanged: (val) => setState(() => _coughOption = val),
              ),
            ),
            QuestionSection(
              question: "How's Your Throat Feeling?",
              child: OptionSelector(
                options: const [
                  OptionItem(label: 'Fine', icon: '😄', value: 'Fine'),
                  OptionItem(label: 'Dry', icon: '😐', value: 'Dry'),
                  OptionItem(label: 'Hurts', icon: '🔥', value: 'Hurts'),
                ],
                selectedValue: _throatOption,
                onChanged: (val) => setState(() => _throatOption = val),
              ),
            ),
            QuestionSection(
              question: 'Feeling More Tired Than Usual?',
              child: OptionSelector(
                options: const [
                  OptionItem(label: 'No', icon: '💪', value: 'No'),
                  OptionItem(label: 'A Little', icon: '😐', value: 'A Little'),
                  OptionItem(label: 'Very Tired', icon: '😫', value: 'Very Tired'),
                ],
                selectedValue: _tiredOption,
                onChanged: (val) => setState(() => _tiredOption = val),
              ),
            ),
            QuestionSection(
              question: 'Any Headaches Today?',
              child: OptionSelector(
                options: const [
                  OptionItem(label: 'No', icon: '🚫', value: 'No'),
                  OptionItem(label: 'Sometimes', icon: '😐', value: 'Sometimes'),
                  OptionItem(label: 'Yes', icon: '🤕', value: 'Yes'),
                ],
                selectedValue: _headacheOption,
                onChanged: (val) => setState(() => _headacheOption = val),
              ),
            ),
            QuestionSection(
              question: 'Appetite Today?',
              child: OptionSelector(
                options: const [
                  OptionItem(label: 'Normal', icon: '🍽️', value: 'Normal'),
                  OptionItem(label: 'Less', icon: '😐', value: 'Less'),
                  OptionItem(label: 'None', icon: '🚫', value: 'No Appetite'),
                ],
                selectedValue: _appetiteOption,
                onChanged: (val) => setState(() => _appetiteOption = val),
              ),
            ),
            QuestionSection(
              question: 'Did You Notice Any Dizziness Or Nausea?',
              child: OptionSelector(
                options: const [
                  OptionItem(label: 'No', icon: '🚫', value: 'No'),
                  OptionItem(label: 'A Bit', icon: '😐', value: 'A Bit'),
                  OptionItem(label: 'Yes', icon: '🤢', value: 'Yes'),
                ],
                selectedValue: _dizzinessOption,
                onChanged: (val) => setState(() => _dizzinessOption = val),
              ),
            ),
            QuestionSection(
              question: 'Do You Feel Physically Better Or Worse Than Yesterday?',
              child: OptionSelector(
                options: const [
                  OptionItem(label: 'Better', icon: '⬆️', value: 'Better'),
                  OptionItem(label: 'Same', icon: '➖', value: 'Same'),
                  OptionItem(label: 'Worse', icon: '⬇️', value: 'Worse'),
                ],
                selectedValue: _betterWorseOption,
                onChanged: (val) => setState(() => _betterWorseOption = val),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _progress == 1.0 ? _submitHealthCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  disabledBackgroundColor: const Color(0xFF007BFF).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Bottom Nav Visual
            Container(
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8025),
                borderRadius: BorderRadius.circular(35),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.home_rounded, color: Colors.white, size: 28),
                  Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 28),
                  Icon(Icons.chat_bubble_outline_rounded, color: Colors.white70, size: 28),
                  Icon(Icons.person_outline_rounded, color: Colors.white70, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
