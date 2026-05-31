import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_post_screen.dart'; 

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Explore Skelva", 
          style: TextStyle(color: Colors.black, fontFamily: 'Helvetica Rounded', fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen()));
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_off, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text("No posts yet. Be the first!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1, 
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var postDoc = snapshot.data!.docs[index];
              var post = postDoc.data() as Map<String, dynamic>;
              
              return GestureDetector(
                onTap: () {
                  // Pass the Document ID to handle updates/deletes
                  _showPostDetails(context, post, postDoc.id);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      post['mediaUrl'] ?? 'https://placehold.co/200',
                      fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
                    ),
                    if (post['type'] == 'Video')
                      const Positioned(
                        right: 5,
                        top: 5,
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- DETAIL POPUP WITH COMMENTS & LIKES ---
  void _showPostDetails(BuildContext context, Map<String, dynamic> postData, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full screen effect
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => PostDetailModal(postData: postData, postId: postId, scrollController: controller),
      ),
    );
  }
}

// --- SEPARATE WIDGET FOR THE MODAL TO MANAGE STATE ---
class PostDetailModal extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String postId;
  final ScrollController scrollController;

  const PostDetailModal({super.key, required this.postData, required this.postId, required this.scrollController});

  @override
  State<PostDetailModal> createState() => _PostDetailModalState();
}

class _PostDetailModalState extends State<PostDetailModal> {
  final TextEditingController _commentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    // Check if current user already liked this post
    if (widget.postData['likes'] != null && currentUser != null) {
      isLiked = (widget.postData['likes'] as List).contains(currentUser!.uid);
    }
  }

  // --- TOGGLE LIKE FUNCTION ---
  void _toggleLike() async {
    if (currentUser == null) return;
    
    setState(() {
      isLiked = !isLiked;
    });

    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUser!.uid])
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUser!.uid])
      });
    }
  }

  // --- DELETE POST FUNCTION ---
  void _deletePost() async {
    // Show confirmation dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).delete();
      if (mounted) Navigator.pop(context); // Close modal
    }
  }

  // --- SEND COMMENT FUNCTION ---
  void _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
      'text': _commentController.text.trim(),
      'userId': currentUser!.uid,
      'userName': currentUser!.displayName ?? "Student",
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = currentUser?.uid == widget.postData['userId'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          
          // Header: User Info & Delete Button
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.postData['userImage'] != null ? NetworkImage(widget.postData['userImage']) : null,
              child: widget.postData['userImage'] == null ? Text(widget.postData['userName']?[0] ?? "U") : null,
            ),
            title: Text(widget.postData['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.postData['type'] ?? "Post"),
            trailing: isOwner 
              ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deletePost)
              : null,
          ),

          // Post Image (Scrollable Content)
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.zero,
              children: [
                Image.network(
                  widget.postData['mediaUrl'] ?? 'https://placehold.co/400',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                
                // Action Bar (Like, Comment)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.black),
                        onPressed: _toggleLike,
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.comment_outlined),
                      const SizedBox(width: 15),
                      const Icon(Icons.send),
                      const Spacer(),
                      const Icon(Icons.bookmark_border),
                    ],
                  ),
                ),
                
                // Caption
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(widget.postData['caption'] ?? "", style: const TextStyle(fontSize: 15)),
                ),
                const Divider(height: 30),
                
                // Comments Section Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                
                // Comments List (Real-time)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var comments = snapshot.data!.docs;

                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No comments yet. Say something!", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true, // Important for nesting in ListView
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var c = comments[index].data() as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 12, child: Text(c['userName'][0])),
                          title: Text(c['userName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text(c['text']),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 80), // Space for input field
              ],
            ),
          ),

          // Comment Input Field (Sticks to bottom)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _postComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}