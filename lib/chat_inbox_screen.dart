import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'chat_screen.dart'; 

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- QUERY ---
        // IMPORTANT: I commented out 'orderBy' to ensure data loads first. 
        // If data appears now, check Debug Console for a link to create an Index, then uncomment it.
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            // .orderBy('lastUpdated', descending: true) // <--- UNCOMMENT AFTER CREATING INDEX
            .snapshots(),
        builder: (context, snapshot) {
          // --- DEBUGGING ---
          if (snapshot.hasError) {
            print("🔥 Inbox Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.hasData) {
            print("✅ Found ${snapshot.data!.docs.length} chats");
          }
          // -----------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatDoc = snapshot.data!.docs[index];
              var chatData = chatDoc.data() as Map<String, dynamic>;
              
              // 1. Identify Other User
              List<dynamic> users = chatData['users'] ?? [];
              String otherUserId = users.firstWhere((id) => id != currentUserId, orElse: () => "");

              // 2. Get Name (Try 'names' map first, fallback to 'User')
              Map<String, dynamic> names = chatData['names'] != null 
                  ? Map<String, dynamic>.from(chatData['names']) 
                  : {};
              
              String displayName = names[otherUserId] ?? "User";

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF335D61),
                  child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white)),
                ),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chatData['lastMessage'] ?? "Sent an attachment", 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Text(
                  _formatTimestamp(chatData['lastUpdated']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        sellerId: otherUserId, 
                        sellerName: displayName // Pass name we found
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_chat_unread_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("No messages yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}