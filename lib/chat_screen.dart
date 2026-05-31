import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const ChatScreen({super.key, required this.sellerId, required this.sellerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _chatId;
  String? _currentUserId;
  String _currentUserName = "User"; // Default

  @override
  void initState() {
    super.initState();
    _setupUser();
  }

  void _setupUser() async {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
    
    // Fetch current user's name for metadata
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserName = userDoc.data()?['fullName'] ?? userDoc.data()?['firstName'] ?? "User";
        });
      }
    }

    // Generate consistent Chat ID
    List<String> ids = [_currentUserId!, widget.sellerId];
    ids.sort(); // Sort to ensure "A_B" is always the same as "B_A"
    _chatId = ids.join("_");
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String msg = _messageController.text.trim();
    _messageController.clear();

    try {
      // 1. Add Message to Subcollection
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'text': msg,
        'senderId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update Chat Metadata (CRITICAL FOR INBOX)
      // We use set with merge: true so it creates the doc if it doesn't exist
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'users': [_currentUserId, widget.sellerId], // Array for querying
        'lastMessage': msg,
        'lastUpdated': FieldValue.serverTimestamp(),
        // Store names to make Inbox faster (avoid extra lookups)
        'names': {
          _currentUserId: _currentUserName,
          widget.sellerId: widget.sellerName
        }
      }, SetOptions(merge: true));

      print("✅ Message Sent & Inbox Updated for ID: $_chatId");

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      print("🔥 Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.sellerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // MESSAGES AREA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text("Start a conversation!", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest at bottom
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF335D61) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                            bottomLeft: !isMe ? Radius.zero : const Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          data['text'] ?? "",
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add, color:Color(0xFF335D61)), onPressed: () {}),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF335D61)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}