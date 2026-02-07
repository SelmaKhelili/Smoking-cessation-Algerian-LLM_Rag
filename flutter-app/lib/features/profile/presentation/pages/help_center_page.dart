import 'package:flutter/material.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  bool _isFaqSelected = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- HEADER SECTION ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // Padding for content
            decoration: const BoxDecoration(
              color: Color(0xFFFF8025), 
              image: DecorationImage(
                image: AssetImage('assets/images/help_header.png'), 
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Help Center',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24), // Balance back button
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'How Can We Help You?',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Search Bar (Inside Header)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _isFaqSelected ? 'Search FAQ...' : 'Search Contact...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, color: Colors.black54),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- TABS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    text: 'FAQ',
                    isSelected: _isFaqSelected,
                    onTap: () => setState(() => _isFaqSelected = true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TabButton(
                    text: 'Contact Us',
                    isSelected: !_isFaqSelected,
                    onTap: () => setState(() => _isFaqSelected = false),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- CONTENT LIST ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isFaqSelected 
                  ? _FaqContent(searchQuery: _searchQuery) 
                  : _ContactUsContent(searchQuery: _searchQuery),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TABS ---
class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8025) : const Color(0xFFFFE082).withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFFF8025),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _FaqContent extends StatelessWidget {
  final String searchQuery;

  const _FaqContent({required this.searchQuery});

  static const List<Map<String, String>> _allFaqs = [
    {'title': 'How do I reset my password?', 'content': 'Go to Settings > Password Manager to change your password securely.'},
    {'title': 'How does the tracker work?', 'content': 'The tracker calculates days smoke-free based on your quit date set in the profile.'},
    {'title': 'Is my data private?', 'content': 'Yes, all your data is stored locally and encrypted. We prioritize your privacy.'},
    {'title': 'Can I change my daily goal?', 'content': 'Yes, navigate to the Home page and click "Daily Goals" to adjust your targets.'},
    {'title': 'How do I contact support?', 'content': 'Switch to the "Contact Us" tab above to find our phone number and email.'},
    {'title': 'What if I relapse?', 'content': 'Don\'t worry! Use the "Check-in" feature to log it and get motivation to start again.'},
    {'title': 'Can I export my data?', 'content': 'Currently, data export is not available.'},
    {'title': 'How do I delete my account?', 'content': 'Go to Settings > Delete Account. Note that this action is irreversible.'},
    {'title': 'Is the app free to use?', 'content': 'Yes, the core features are free.'},
    {'title': 'Why are notifications not working?', 'content': 'Check your device settings to ensure notifications are enabled for SAI app.'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _allFaqs.where((faq) {
      return faq['title']!.toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredFaqs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text('No matching questions found', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: filteredFaqs.map((faq) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ExpandableItem(title: faq['title']!, content: faq['content']!),
      )).toList(),
    );
  }
}

class _ContactUsContent extends StatelessWidget {
  final String searchQuery;

  const _ContactUsContent({required this.searchQuery});

  static const List<Map<String, dynamic>> _allContacts = [
    {'icon': Icons.headset_mic_outlined, 'title': 'Customer Service', 'detail': 'SaiApp@Gmail.com'},
    {'icon': Icons.language, 'title': 'Website', 'detail': 'www.sai-app.com'},
    {'icon': Icons.message, 'title': 'Whatsapp', 'detail': '+213 777 888 999'},
    {'icon': Icons.facebook, 'title': 'Facebook', 'detail': 'facebook.com/sai_app'},
    {'icon': Icons.camera_alt_outlined, 'title': 'Instagram', 'detail': '@sai_official'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _allContacts.where((contact) {
      return contact['title'].toString().toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredContacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text('No contact options found', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: filteredContacts.map((contact) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ContactItem(
          icon: contact['icon'],
          title: contact['title'],
          detail: contact['detail'],
        ),
      )).toList(),
    );
  }
}

class _ExpandableItem extends StatelessWidget {
  final String title;
  final String content;

  const _ExpandableItem({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          iconColor: const Color(0xFFFF8025),
          collapsedIconColor: Colors.grey,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(content, style: const TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _ContactItem({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFFF8025), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          iconColor: Colors.grey,
          collapsedIconColor: Colors.grey,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 8),
              alignment: Alignment.centerLeft,
              child: SelectableText(detail, style: const TextStyle(color: Color(0xFF1B6EB9), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
