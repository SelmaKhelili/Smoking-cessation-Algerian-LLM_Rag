import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFF8025)),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
