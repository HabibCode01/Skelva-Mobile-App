import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'dart:math';

// This page handles BOTH the Seller (Host) and the Viewer (Audience)
class BroadcastPage extends StatelessWidget {
  final String liveID;     // The "Room Name" (e.g., product name or seller ID)
  final bool isHost;       // TRUE if Seller, FALSE if Student
  final String userID;     // Unique ID for the user
  final String userName;   // Name to show in chat

  const BroadcastPage({
    super.key, 
    required this.liveID, 
    this.isHost = false,
    required this.userID,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltLiveStreaming(
        // --------------------------------------------------------
        // TODO: GET THESE FROM https://console.zegocloud.com/
        // --------------------------------------------------------
        appID: 12867967, // Your App ID
        appSign: "cd707a920b2f04f64b455cf4b76ee248e38ecc1aa105f3b3c10f5bac76c745c5", // Your App Sign (Fill this in string format)
        
        userID: userID,
        userName: userName,
        liveID: liveID,
        
        // --- TOP NOTCH QUALITY CONFIGURATION ---
        config: isHost
            ? (ZegoUIKitPrebuiltLiveStreamingConfig.host(
                plugins: [ZegoUIKitSignalingPlugin()],
              )
              // 1. Force High Definition Video (1080p)
              ..video = ZegoUIKitVideoConfig.preset1080P() 
              )
            : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
                plugins: [ZegoUIKitSignalingPlugin()],
              ),

        // --- EVENTS TO HANDLE LEAVING ---
        events: ZegoUIKitPrebuiltLiveStreamingEvents(
          onEnded: (event, defaultAction) async {
            // This runs when the Host clicks the "Power/End" button
            if (isHost) {
               await FirebaseFirestore.instance
                  .collection('active_lives')
                  .doc(liveID)
                  .delete();
            }
            defaultAction.call();
          },
        ),
      ),
    );
  }
}