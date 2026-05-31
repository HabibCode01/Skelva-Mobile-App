import 'package:flutter/material.dart';
import 'ai_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();
  final List<Map<String, String>> _messages = []; // Stores chat history
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial greeting
    _messages.add({
      'role': 'bot', 
      'message': 'Hi! I\'m SkelvaBot. Ask me "What is the best selling item?" or "I need a gift for my mom!"'
    });
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    String userText = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'message': userText});
      _isTyping = true;
      _controller.clear();
    });

    // Get AI Response
    String response = await _aiService.getRecommendation(userText);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'bot', 'message': response});
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      appBar: AppBar(
        title: const Text("Skelva AI Helper", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF335D61) : Colors.white,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                        bottomLeft: !isUser ? Radius.zero : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                      ]
                    ),
                    child: Text(
                      msg['message']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Typing Indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("SkelvaBot is typing...", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask for recommendations...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color(0xFFEF963B),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}