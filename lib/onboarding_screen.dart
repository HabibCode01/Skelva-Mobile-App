import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1), // Pushes content down slightly

            // --- 1. ILLUSTRATION IMAGE ---
            // I used a placeholder. Replace "assets/onboarding1.png" with your real image later.
            Transform.translate(
              offset: const Offset(100, 650), // 👇 (X, Y) -> Moves 20px Right. Use -20 to move Left.
              child: Container(
                width: 232,
                height: 238,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage("assets/LogoOnboarding.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2), // Flexible space

           Transform.translate(
              offset: const Offset(10, -180), // 👇 (X, Y) -> Moves 20px Right. Use -20 to move Left.
              child: Container(
                width: 330,
                height: 268,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage("assets/Layer_1.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // --- 2. TEXT SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const Text(
                    'Choose a service',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF33353C),
                      fontSize: 22,
                      fontFamily: 'Helvetica Rounded', // Ensure font is in pubspec
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: 0.80,
                    child: const Text(
                      'Find the right product selling for your needs \neasily, with a variety of options \navailable at your fingertips.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF282828),
                        fontSize: 16,
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.w700,
                        height: 1.5, // Added line height for readability
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // --- 3. DOTS INDICATOR ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(isActive: true),  // Active dot (Black)
                _buildDot(isActive: false), // Inactive (Grey)
                _buildDot(isActive: false), // Inactive (Grey)
              ],
            ),

            const Spacer(flex: 2),

            // --- 4. BOTTOM BUTTONS (Skip & Next) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: () {
                  Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontFamily: 'Roboto Flex',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Next Button
                  GestureDetector(
                    onTap: () {
                  Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Container(
                      width: 108,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF264B52),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Finish',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontFamily: 'Roboto Flex',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to draw the dots
  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 8.26,
      height: 8.26,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF231F20) : const Color(0xFFC4C4C4),
        shape: BoxShape.circle,
      ),
    );
  }
}