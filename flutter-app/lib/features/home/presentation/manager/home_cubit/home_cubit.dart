import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/../../../core/network/url_data.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  HomeCubit() : super(HomeState.initial()) {
    loadHomeData();
  }

  final List<String> _quotes = const [
    "أفضل وقت للإقلاع عن التدخين كان اليوم الذي بدأت فيه، والثاني أفضل وقت هو اليوم.",
    "آمن بنفسك وستكون قد قطعت نصف الطريق.",
    "لا تدع التبغ يسرق أنفاسك.",
    "كل مرة تشعل فيها سيجارة، أنت تقول أن حياتك لا تستحق العيش.",
    "حياتك بين يديك، اصنع منها ما تشاء.",
    "الإقلاع عن التدخين أسهل شيء في العالم. أعلم لأنني فعلته آلاف المرات.",
    "ركز على الحل، لا المشكلة.",
    "لم يفت الأوان أبداً لتصبح ما كنت قد حلمت أن تكونه.",
    "استبدل العادة، لا تمحوها فقط.",
    "الصحة لا تُقدّر إلا عند المرض."
  ];

  Future<void> loadHomeData() async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final userId = await storage.read(key: 'user_id');
      if (userId == null) throw Exception('User ID not found');

      final response = await http.get(
        Uri.parse('$BASE_URL/api/tracking/statistics/$userId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch stats');
      }

      final data = jsonDecode(response.body);
      final stats = data['statistics'];
      final dailyData = data['daily_data'] as List<dynamic>? ?? [];

      // Convert daily_data to moodData map (date -> mood)
      final Map<String, String> moodMap = {};
      for (var entry in dailyData) {
        if (entry['mood'] != null) {
          moodMap[entry['date']] = entry['mood'];
        }
      }

      // Get daily quote (only changes once per day)
      final dailyQuote = await _getDailyQuote();

      emit(state.copyWith(
        status: HomeStatus.success,
        currentDate: DateTime.now(),
        dailyQuote: dailyQuote,
        quitDays: stats['smoke_free_days'] ?? 0,
        cigarettesAvoided: stats['total_cigarettes_avoided'] ?? 0,
        moneySaved: stats['total_money_saved']?.toInt() ?? 0,
        moodData: moodMap,
      ));
    } catch (e) {
      print("Error loading home data: $e");
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  Future<String> _getDailyQuote() async {
    // Get today's date as a string
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    
    // Check if we have a quote for today
    final storedDate = await storage.read(key: 'quote_date');
    final storedQuote = await storage.read(key: 'daily_quote');
    
    if (storedDate == dateKey && storedQuote != null) {
      // Return cached quote for today
      return storedQuote;
    }
    
    // Generate new quote for today
    final newQuote = _quotes[Random().nextInt(_quotes.length)];
    await storage.write(key: 'quote_date', value: dateKey);
    await storage.write(key: 'daily_quote', value: newQuote);
    
    return newQuote;
  }

  Future<void> refreshAfterTracking() async {
    await loadHomeData();
  }
}
