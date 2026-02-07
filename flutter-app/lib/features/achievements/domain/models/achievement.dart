enum AchievementCategory { beginner, intermediate, advanced }

class Achievement {
  final int id;
  final String title;
  final String description;
  final String imagePath;

  // backend-driven logic
  final String criteriaType;   // days, cigarettes, money, etc.
  final int criteriaValue;     // value required to unlock
  final double progress;       // 0 → 100
  final bool isUnlocked;

  final AchievementCategory category;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.criteriaType,
    required this.criteriaValue,
    required this.progress,
    required this.isUnlocked,
    required this.category,
  });

  factory Achievement.fromJson(Map<String, dynamic> json, {required bool unlocked}) {
    return Achievement(
      id: json['id'],
      title: json['name'],
      description: json['description'] ?? '',
      imagePath: json['icon_url'] ?? '',
      criteriaType: json['criteria_type'],
      criteriaValue: json['criteria_value'],
      progress: (json['progress_percentage'] ?? 0).toDouble(),
      isUnlocked: unlocked,
      category: _mapCategory(json['badge_type']),
    );
  }

  static AchievementCategory _mapCategory(String? badge) {
    switch (badge) {
      case 'intermediate':
        return AchievementCategory.intermediate;
      case 'advanced':
        return AchievementCategory.advanced;
      default:
        return AchievementCategory.beginner;
    }
  }
}
