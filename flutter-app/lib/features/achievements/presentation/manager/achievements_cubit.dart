import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/achievement.dart';
import '/../../core/network/url_data.dart';

class AchievementsState extends Equatable {
  final List<Achievement> achievements;
  final bool loading;

  const AchievementsState({
    this.achievements = const [],
    this.loading = false,
  });

  @override
  List<Object?> get props => [achievements, loading];
}

class AchievementsCubit extends Cubit<AchievementsState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AchievementsCubit() : super(const AchievementsState()) {
    loadAchievements();
  }

  Future<void> loadAchievements() async {
    emit(const AchievementsState(loading: true));

    try {
      // 🔹 Read user_id from secure storage
      final userIdStr = await _storage.read(key: 'user_id');

      if (userIdStr == null) {
        emit(const AchievementsState());
        return;
      }

      final userId = int.parse(userIdStr);

      // 🔹 API calls
      final earnedRes = await http.get(
        Uri.parse('$BASE_URL/api/achievements/earned?user_id=$userId'),
      );

      final progressRes = await http.get(
        Uri.parse('$BASE_URL/api/achievements/progress?user_id=$userId'),
      );

      final earnedJson =
          jsonDecode(earnedRes.body)['earned_achievements'] as List;

      final progressJson =
          jsonDecode(progressRes.body)['achievement_progress'] as List;

      // 🔹 Map earned achievements (unlocked)
      final earnedAchievements = earnedJson
          .map((e) => Achievement.fromJson(e, unlocked: true))
          .toList();

      // 🔹 Map unearned achievements (locked)
      final unearnedAchievements = progressJson
          .map((e) => Achievement.fromJson(e, unlocked: false))
          .toList();

      // 🔹 Combine both lists
      final achievements = [...earnedAchievements, ...unearnedAchievements];

      emit(AchievementsState(achievements: achievements));
    } catch (e) {
      emit(const AchievementsState());
    }
  }
}
