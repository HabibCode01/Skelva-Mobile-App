import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'broadcast_page.dart'; 

class LiveFeedScreen extends StatefulWidget {
  const LiveFeedScreen({super.key});

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // --- FETCH REAL STREAMS FROM FIRESTORE ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('active_lives').snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.videocam_off, color: Colors.grey, size: 60),
                  SizedBox(height: 20),
                  Text("No one is live right now.", style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          var liveDocs = snapshot.data!.docs;
          
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: liveDocs.length,
            itemBuilder: (context, index) {
              var data = liveDocs[index].data() as Map<String, dynamic>;
              return _LiveFeedItem(liveData: data);
            },
          );
        },
      ),
    );
  }
}

// --- SUB-WIDGET TO HANDLE VIDEO & OVERLAY ---
class _LiveFeedItem extends StatefulWidget {
  final Map<String, dynamic> liveData; 
  const _LiveFeedItem({required this.liveData});

  @override
  State<_LiveFeedItem> createState() => _LiveFeedItemState();
}

class _LiveFeedItemState extends State<_LiveFeedItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    String videoUrl = widget.liveData['previewUrl'] ?? 'https://assets.mixkit.co/videos/preview/mixkit-woman-folding-laundry-during-the-day-40618-large.mp4';
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _controller.setLooping(true);
            _controller.play();
          });
        }
      }).catchError((error) {
         print("Video Error: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _joinRealStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to join")));
      return;
    }

    String realRoomID = widget.liveData['roomID']; 
    // ignore: unused_local_variable
    String sellerName = widget.liveData['sellerName'] ?? "Seller";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BroadcastPage(
          liveID: realRoomID, 
          isHost: false, 
          userID: user.uid,
          userName: user.displayName ?? "Student",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. PREVIEW VIDEO LAYER (Improved Quality Fit)
        _initialized
            ? Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.white)),

        // 2. GRADIENT OVERLAY
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.7)
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // 3. TOP HEADER
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.person, size: 20)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.liveData['sellerName'] ?? "Seller", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        const Text("Preview", style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    
                    // --- JOIN BUTTON ---
                    GestureDetector(
                      onTap: _joinRealStream,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFEF963B), borderRadius: BorderRadius.circular(20)),
                        child: const Text("JOIN LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        // 4. BIG "WATCH NOW" BUTTON
        Positioned(
          bottom: 200,
          left: 60,
          right: 60,
          child: Column(
            children: [
              Text(
                 "${widget.liveData['sellerName']} is LIVE!",
                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
               ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _joinRealStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.videocam, color: Colors.white),
                label: const Text("Watch Stream", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),

        // 5. BOTTOM CHAT PREVIEW
        Positioned(
          left: 20,
          bottom: 100,
          child: SizedBox(
            width: 250,
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChatBubble("System", "Tap 'Join Live' to chat!", Colors.greenAccent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(String user, String msg, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: "$user ", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              TextSpan(text: msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}