import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/achievement.dart';
import '../manager/achievements_cubit.dart';
import '../../../home/presentation/widgets/home_bottom_nav.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  int _selectedIndex = 2;

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AchievementsCubit(), // cubit already loads data
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2775FF)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Achievements',
            style: TextStyle(
              color: Color(0xFF2775FF),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: BlocBuilder<AchievementsCubit, AchievementsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final beginner = state.achievements
                .where((a) => a.category == AchievementCategory.beginner)
                .toList();

            final intermediate = state.achievements
                .where((a) => a.category == AchievementCategory.intermediate)
                .toList();

            final advanced = state.achievements
                .where((a) => a.category == AchievementCategory.advanced)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AchievementSection(title: 'Beginner', achievements: beginner),
                  const SizedBox(height: 32),
                  _AchievementSection(title: 'Intermediate', achievements: intermediate),
                  const SizedBox(height: 32),
                  _AchievementSection(title: 'Advanced', achievements: advanced),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: HomeBottomNavBar(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
      ),
    );
  }
}

class _AchievementSection extends StatelessWidget {
  final String title;
  final List<Achievement> achievements;

  const _AchievementSection({
    required this.title,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];

            return _AchievementItem(
              achievement: achievement,
              isUnlocked: achievement.isUnlocked,
            );
          },
        ),
      ],
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementItem({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: isUnlocked
                ? Image.asset(
                    achievement.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.hexagon, size: 40, color: Colors.amber),
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Image.asset(
                      achievement.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.hexagon, size: 40, color: Colors.grey),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          achievement.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
