import 'package:flutter/material.dart';
import '../../domain/models/chatbot_model.dart';
import '../../domain/models/message_model.dart';
import '../../../home/presentation/widgets/home_bottom_nav.dart'; // Adjust import
import '../../data/services/rag_api_service.dart';
import '../../data/services/chat_backend_service.dart';

class ChatPage extends StatefulWidget {
  final ChatbotModel chatbot;

  const ChatPage({super.key, required this.chatbot});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int _selectedIndex = 2; // Chat tab active
  final TextEditingController _controller = TextEditingController();
  final RagApiService _ragService = RagApiService();
  final ChatBackendService _chatService = ChatBackendService();
  bool _isLoading = false;
  int? _sessionId; // For database saving
  final int _userId = 1; // TODO: Get from auth/shared preferences

  // Initial welcome message
  final List<MessageModel> _messages = [
    const MessageModel(
      text: 'السلام عليكم! أنا Sai، مساعدك باش تقلع على التدخين. حكيلي بالداريجة وانا نعاونك.',
      isSentByMe: false,
      time: '06:41',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
    // _initializeDatabaseSession(); // DISABLED - uncomment when Flask backend is running
  }

  /// Check if the RAG API is available
  Future<void> _checkApiHealth() async {
    try {
      final isHealthy = await _ragService.checkHealth();
      if (!isHealthy && mounted) {
        _showSnackBar('⚠️ تحذير: API غير متاح. تأكد من تشغيل ngrok!', Colors.orange);
      }
    } catch (e) {
      // Silently fail, will show error when user sends message
    }
  }

  /// Initialize database session (background, non-blocking)
  Future<void> _initializeDatabaseSession() async {
    try {
      final sessionData = await _chatService.createSession(
        _userId,
        title: 'Chat with ${widget.chatbot.name}',
      );
      setState(() {
        _sessionId = sessionData['session']['id'];
      });
      print('✅ Database session created: $_sessionId');
    } catch (e) {
      print('⚠️ Database session creation failed (will work without DB): $e');
      // Don't show error to user - app will work without database
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// Send message to RAG API and get response (HYBRID: also saves to DB)
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    final timeString = _formatTime();

    // Add user message to chat
    setState(() {
      _messages.add(MessageModel(
        text: userMessage,
        isSentByMe: true,
        time: timeString,
      ));
      _isLoading = true;
    });

    _controller.clear();

    try {
      // 1️⃣ Call RAG API directly (FAST - for immediate response)
      final response = await _ragService.sendQuery(userMessage);
      final aiResponse = response['answer'] ?? 'معليش، ما قدرتش نجاوب.';

      // Add AI response to chat
      setState(() {
        _messages.add(MessageModel(
          text: aiResponse,
          isSentByMe: false,
          time: _formatTime(),
        ));
        _isLoading = false;
      });

      // Optional: Log metadata for debugging
      print('📊 Query Metadata:');
      print('  Confidence: ${response['confidence']}');
      print('  RAG Used: ${response['rag_used']}');
      print('  Query Type: ${response['query_type']}');

      // 2️⃣ Save to database (BACKGROUND - fire and forget)
      _saveToDatabaseAsync(userMessage, aiResponse);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(MessageModel(
          text: 'معليش، وقعت مشكلة في الاتصال بالخادم. تأكد من تشغيل ngrok والـAPI.',
          isSentByMe: false,
          time: _formatTime(),
        ));
      });
      
      _showSnackBar('خطأ في الاتصال: $e', Colors.red);
    }
  }

  /// Save conversation to database (background, non-blocking)
  Future<void> _saveToDatabaseAsync(String userMessage, String aiResponse) async {
    if (_sessionId == null) {
      print('⚠️ No database session - skipping save');
      return;
    }

    try {
      // Note: Backend expects to call RAG API itself, but we already have the response
      // So we'll save the user message, and the backend will call RAG again
      // This is redundant but ensures database has RAG metadata
      await _chatService.sendMessage(_sessionId!, userMessage);
      print('💾 Saved to database: session $_sessionId');
    } catch (e) {
      print('⚠️ Failed to save to database (non-critical): $e');
      // Silently fail - user already has response, database is optional
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedIndex) return;
    // Add navigation logic (e.g., Navigator.pop or push)
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA), // Light blue-grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8025), // Orange Header
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.chatbot.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Chat List ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // --- Input Area (Floating above Nav Bar) ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: const Color(0xFFE8ECF9), // Match bottom area color from image
            child: Row(
              children: [
                // Text Field
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_isLoading,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        // Send Button inside field
                        GestureDetector(
                          onTap: _isLoading ? null : _sendMessage,
                          child: Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isLoading 
                                  ? Colors.grey 
                                  : const Color(0xFF1B6EB9), // Blue Send Button
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Reusing Home Bottom Nav (Orange Bar)
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
// Typing indicator widget
class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotIndicator(delay: 0),
              const SizedBox(width: 4),
              _DotIndicator(delay: 200),
              const SizedBox(width: 4),
              _DotIndicator(delay: 400),
            ],
          ),
        ),
      ],
    );
  }
}

class _DotIndicator extends StatefulWidget {
  final int delay;
  const _DotIndicator({required this.delay});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
class _MessageBubble extends StatelessWidget {
  final MessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;
    
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF007BFF) : Colors.white, // Blue vs White
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4), // Sharp corner logic
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
            ),
            boxShadow: [
              if (!isMe) // Slight shadow for white bubbles
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            message.text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        // Time Label
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            message.time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }
}
