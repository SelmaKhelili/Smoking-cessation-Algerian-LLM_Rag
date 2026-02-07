import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF8025), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFFFF8025),
            fontWeight: FontWeight.w600,
            fontSize: 20, // Slightly larger title
          ),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: TextStyle(
                color: Color(0xFFFF8025),
                fontSize: 20, // Larger sub-header
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24),
            
            _PrivacyItem(
              number: '1.',
              text: 'SAI respects your privacy. We collect only the information needed to help you use the app effectively, such as your email or progress data, and we never sell or share your personal details with third parties.',
            ),
            SizedBox(height: 24),
            
            _PrivacyItem(
              number: '2.',
              text: 'All information is stored securely and used only to improve your experience and provide support in your quit journey. You can request to delete your data anytime by contacting our support team.',
            ),
            SizedBox(height: 24),
            
            _PrivacyItem(
              number: '3.',
              text: 'By using SAI, you agree to this policy and our mission to keep your information private and safe.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final String number;
  final String text;

  const _PrivacyItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 16, // Larger text
            color: Color(0xFF424242), // Darker Grey
            height: 1.6, 
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16, // Larger text
              color: Color(0xFF424242), // Darker Grey (Readable)
              height: 1.6, // Better spacing
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
