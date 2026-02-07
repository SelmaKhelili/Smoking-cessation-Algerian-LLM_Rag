import 'package:flutter/material.dart';

class CalendarStrip extends StatelessWidget {
  final DateTime currentDate;
  final Map<String, String>? moodData; // Map of date string to mood (happy, sad, etc)

  const CalendarStrip({
    super.key,
    required this.currentDate,
    this.moodData,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate the Sunday of the current week
    // Weekday 1 = Mon, ... 7 = Sun
    final now = currentDate;
    // If Sunday (weekday 7), it's already the start; otherwise go back to previous Sunday
    final sunday = now.weekday == 7 
        ? now 
        : now.subtract(Duration(days: now.weekday));

    // 2. Generate the 7 days of this week starting from Sunday
    final List<DateTime> weekDates = List.generate(7, (index) {
      return sunday.add(Duration(days: index));
    });

    return SizedBox(
      height: 105,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDates.map((date) {
          // Check if this date matches 'now' (ignoring time)
          final isSelected = _isSameDay(date, now);
          
          // Get mood for this date
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final mood = moodData?[dateKey];
          
          IconData? moodIcon;
          Color? moodColor;
          
          // Display mood if available (for any day including today)
          if (mood != null) {
            switch (mood.toLowerCase()) {
              case 'happy':
                moodIcon = Icons.sentiment_very_satisfied;
                moodColor = isSelected ? Colors.white : Colors.green;
                break;
              case 'sad':
                moodIcon = Icons.sentiment_dissatisfied;
                moodColor = isSelected ? Colors.white : Colors.orange;
                break;
              case 'depressed':
                moodIcon = Icons.sentiment_very_dissatisfied;
                moodColor = isSelected ? Colors.white : Colors.red;
                break;
              case 'angry':
                moodIcon = Icons.mood_bad;
                moodColor = isSelected ? Colors.white : Colors.deepOrange;
                break;
              default:
                moodIcon = Icons.sentiment_neutral;
                moodColor = isSelected ? Colors.white : Colors.grey;
            }
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2775FF) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2775FF).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day Label (MO, TU, etc.)
                    Text(
                      _getDayLabel(date.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Date Number
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Status Indicator (Mood icon takes priority, then dot for today)
                    if (moodIcon != null)
                      Icon(moodIcon, size: 18, color: moodColor)
                    else if (isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper to format weekday number to string
  String _getDayLabel(int weekday) {
    const labels = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    // weekday is 1-based (1=Mon, 7=Sun), convert to 0-based starting with Sun
    // Map: Mon(1)->1, Tue(2)->2, ..., Sat(6)->6, Sun(7)->0
    final index = weekday == 7 ? 0 : weekday;
    return labels[index];
  }

  // Helper to check if two dates represent the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Helper to check if date 'a' is strictly before date 'b' (ignoring time)
  bool _isBeforeToday(DateTime a, DateTime b) {
    final dateA = DateTime(a.year, a.month, a.day);
    final dateB = DateTime(b.year, b.month, b.day);
    return dateA.isBefore(dateB);
  }
}
