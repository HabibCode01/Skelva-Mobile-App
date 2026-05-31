import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'get_started_screen.dart'; 
import 'home_screen.dart'; // Import Home Screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start timer
    Timer(const Duration(seconds: 3), () {
      _checkUserAndNavigate();
    });
  }

  void _checkUserAndNavigate() {
    // 1. Check if user is logged in
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // --- USER EXISTS: GO TO HOME ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // --- NEW USER: GO TO GET STARTED ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GetStartedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.85, 0.03),
            end: Alignment(0.20, 1.00),
            colors: [Color(0xFF335D61), Color(0xFF6FB2A6)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Center(
          child: Container(
            width: 192,
            height: 51,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/LogoSplash.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}