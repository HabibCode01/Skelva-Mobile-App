import 'package:flutter/material.dart';
import 'onboarding_screen.dart'; // Import the next screen

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. Make the background fill the whole screen
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.86, -0.00),
            end: Alignment(0.14, 1.00),
            colors: [Color(0xFF6FB2A6), Color(0xFF183742)],
          ),
        ),
        child: Stack(
          children: [
            // 2. Background Image (The faint pattern)
            Positioned(
              left: -116,
              top: 128,
              child: Opacity(
                opacity: 0.20,
                child: Image.asset(
                  "assets/LogoStart.png", // Replace with "assets/bg_pattern.png" later
                  width: 608,
                  height: 597,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // 3. Main Content (Using Column instead of absolute positioning)
            // SafeArea ensures content doesn't go behind the notch/status bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches button width
                  children: [
                    const Spacer(flex: 2), // Pushes content down slightly
                    
                    // Title Text
                    const Text(
                      'Best Helping\nHands for you',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontFamily: 'Helvetica Rounded', // Make sure this font is in pubspec.yaml
                        fontWeight: FontWeight.w700,
                        height: 0.89,
                      ),
                    ),
                    
                    const SizedBox(height: 20), // Spacing
                    
                    // Subtitle Text
                    const Text(
                      'With Our On-Demand Product Selling App, \nWe Give Better Services To You.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Rounded up from 13.72
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.w400,
                        height: 1.31,
                        letterSpacing: 0.14,
                      ),
                    ),
                    
                    const Spacer(flex: 3), // Pushes button to bottom area
                    
                    // "Get Started" Button
                    GestureDetector(
                      // inside get_started_screen.dart
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                        );
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF963B),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Get Started', // Fixed typo "Gets Started"
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Helvetica',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}