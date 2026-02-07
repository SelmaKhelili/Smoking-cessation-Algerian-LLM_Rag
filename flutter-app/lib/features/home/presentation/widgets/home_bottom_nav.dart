import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';

// Type alias for backward compatibility
typedef HomeBottomNav = HomeBottomNavBar;

class HomeBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const HomeBottomNavBar(
      {super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
            color: const Color(0xFFFF8025),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFF8025).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
                icon: Icons.home_rounded,
                isSelected: selectedIndex == 0,
                onTap: () => Navigator.pushNamed(context, AppRoutes.home)),
            _NavItem(
                icon: Icons.bar_chart_rounded,
                isSelected: selectedIndex == 1,
                onTap: () =>  Navigator.pushNamed(context, AppRoutes.podcastspage)),
            _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                isSelected: selectedIndex == 2,
                onTap: () => Navigator.pushNamed(context, AppRoutes.chatbots_list_page)),
            _NavItem(
                icon: Icons.person_outline_rounded,
                isSelected: selectedIndex == 3,
                onTap: () => Navigator.pushNamed(context, AppRoutes.profilepage)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white.withOpacity(0.2), shape: BoxShape.circle)
              : null,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
