import 'package:flutter/material.dart';
import '../../domain/models/chatbot_model.dart';
import 'chat_page.dart'; // Import the Chat Page

class ChatbotPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const ChatbotPage({super.key, this.onNavigate});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  // Dummy Data
  final List<ChatbotModel> _chatbots = [
    const ChatbotModel(
      id: '1',
      name: 'Sai',
      profession: 'Assistant',
      cb_imagePath: 'assets/images/dr_ahmed.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chatbots',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B6EB9),
                ),
              ),
              const SizedBox(height: 32),
              
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _chatbots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  return _ChatbotCard(chatbot: _chatbots[index]);
                },
              ),
            ],
          ),
        ),
    );
  }
}

class _ChatbotCard extends StatelessWidget {
  final ChatbotModel chatbot;

  const _ChatbotCard({required this.chatbot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6), // Cream background
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(chatbot.cb_imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 28),
          
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chatbot.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8025),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chatbot.profession,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Info Button -> Navigates to ChatPage
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(chatbot: chatbot),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8025),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
