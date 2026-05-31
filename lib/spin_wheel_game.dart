import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpinWheelGame extends StatefulWidget {
  const SpinWheelGame({super.key});

  @override
  State<SpinWheelGame> createState() => _SpinWheelGameState();
}

class _SpinWheelGameState extends State<SpinWheelGame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();
  double _startAngle = 0;
  
  // Prizes: Label, Value (Coins), Color
  final List<Map<String, dynamic>> _sectors = [
    {'label': '10', 'value': 10.0, 'color': Colors.red},
    {'label': '20', 'value': 20.0, 'color': Colors.orange},
    {'label': '0', 'value': 0.0, 'color': Colors.grey},
    {'label': '50', 'value': 50.0, 'color': Colors.green},
    {'label': '5', 'value': 5.0, 'color': Colors.blue},
    {'label': '0', 'value': 0.0, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _calculateResult();
      }
    });
  }

  void _spin() {
    if (_controller.isAnimating) return;
    
    // Random rotations (min 5 full spins + random offset)
    double randomAngle = _random.nextDouble() * 2 * pi;
    double endAngle = _startAngle + (5 * 2 * pi) + randomAngle;

    _animation = Tween<double>(begin: _startAngle, end: endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate)
    );

    _controller.forward(from: 0).then((_) {
      setState(() => _startAngle = endAngle % (2 * pi));
    });
  }

  void _calculateResult() async {
    // Determine which sector is at the top (pointer is usually at -pi/2 or 0 depending on drawing)
    // Here we assume pointer is at TOP (270 degrees or 3*pi/2)
    
    double normalizedAngle = _startAngle % (2 * pi);
    double sectorAngle = 2 * pi / _sectors.length;
    
    // Calculate index hit
    // The wheel rotates clockwise, so the index effectively moves counter-clockwise
    int index = _sectors.length - 1 - ((normalizedAngle / sectorAngle).floor() % _sectors.length);
    
    final prize = _sectors[index];
    double wonCoins = prize['value'];

    // Update Firestore
    if (wonCoins > 0) {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'coins': FieldValue.increment(wonCoins),
      });
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(wonCoins > 0 ? "🎉 You Won!" : "😢 Oh no!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                wonCoins > 0 ? "+${wonCoins.toInt()} Coins" : "Better luck next time!",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFEF963B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close Dialog
                Navigator.pop(context, wonCoins); // Return to Arcade
              }, 
              child: const Text("Collect & Exit")
            )
          ],
        )
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF335D61),
      appBar: AppBar(title: const Text("Spin & Win"), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // POINTER
            const Icon(Icons.arrow_drop_down, size: 50, color: Colors.white),
            
            // WHEEL
            GestureDetector(
              onTap: _spin,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.isAnimating ? _animation.value : _startAngle,
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: WheelPainter(_sectors),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _spin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF963B),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
              ),
              child: const Text("SPIN!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> sectors;
  WheelPainter(this.sectors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * pi / sectors.length;

    for (int i = 0; i < sectors.length; i++) {
      final paint = Paint()..color = sectors[i]['color'];
      canvas.drawArc(rect, i * sweepAngle, sweepAngle, true, paint);
      
      // Draw Text
      _drawText(canvas, center, radius, i * sweepAngle + sweepAngle / 2, sectors[i]['label']);
    }
  }

  void _drawText(Canvas canvas, Offset center, double radius, double angle, String text) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final x = center.dx + (radius * 0.7) * cos(angle);
    final y = center.dy + (radius * 0.7) * sin(angle);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle + pi / 2); // Rotate text to face center
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}