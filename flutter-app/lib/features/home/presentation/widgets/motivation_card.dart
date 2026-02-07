import 'package:flutter/material.dart';

class MotivationCard extends StatefulWidget {
  final String title;
  final String author;
  final String duration;
  final VoidCallback onTap;

  const MotivationCard({
    super.key,
    required this.title,
    required this.author,
    required this.duration,
    required this.onTap,
  });

  @override
  State<MotivationCard> createState() => _MotivationCardState();
}

class _MotivationCardState extends State<MotivationCard> {
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, // Tapping the card body still does the main action
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Play/Pause Button Box (Left)
            GestureDetector(
              onTap: () {
                setState(() {
                  isPlaying = !isPlaying;
                });
                // TODO: Add logic here to actually play/pause audio if needed
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  // Toggle icon based on state
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text (Middle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.author,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // EQ Icon (Right)
            const Icon(Icons.graphic_eq, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
