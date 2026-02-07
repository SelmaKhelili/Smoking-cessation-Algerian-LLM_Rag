import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final int quitDays;
  final int cigarettesAvoided;
  final int moneySaved;

  const StatsRow({
    super.key,
    required this.quitDays,
    required this.cigarettesAvoided,
    required this.moneySaved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatItem(
          icon: Icons.calendar_today_outlined,
          value: '$quitDays',
          label: 'quit days',
          color: const Color(0xFF2775FF),
        ),
        StatItem(
          icon: Icons.smoking_rooms_outlined,
          value: '$cigarettesAvoided',
          label: 'Cigarets avoided',
          color: const Color(0xFF2775FF),
        ),
        StatItem(
          icon: Icons.account_balance_wallet_outlined,
          value: '$moneySaved',
          label: 'da saved',
          color: const Color(0xFFFF8025),
        ),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          '$value $label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
