import 'package:flutter/material.dart';

class QuoteCard extends StatelessWidget {
  final String quote;

  const QuoteCard({
    super.key,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quote of the day',
              style: TextStyle(
                  color: Color(0xFF2775FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text('"$quote"',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8025),
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}
