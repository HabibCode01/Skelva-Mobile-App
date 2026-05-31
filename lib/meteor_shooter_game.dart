import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeteorShooterGame extends StatefulWidget {
  const MeteorShooterGame({super.key});

  @override
  State<MeteorShooterGame> createState() => _MeteorShooterGameState();
}

class _MeteorShooterGameState extends State<MeteorShooterGame> {
  // Game State
  double _playerX = 0.0; // Range -1.0 to 1.0 (Alignment)
  List<Map<String, double>> _missiles = []; // {x, y}
  List<Map<String, double>> _meteors = []; // {x, y}
  int _score = 0;
  int _timeLeft = 30; // 30 Seconds game
  bool _gameOver = false;
  
  // --- NEW VARIABLES FOR AUTO-FIRE ---
  bool _isDragging = false; // Is the player holding the ship?
  int _shootCooldown = 0;   // Delays shots so it's not too fast
  // -----------------------------------

  Timer? _gameLoop;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // Main Game Loop (~60 FPS)
    _gameLoop = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_gameOver) {
        timer.cancel();
        return;
      }
      _updateGame();
    });

    // Countdown Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        _endGame();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _updateGame() {
    setState(() {
      // --- NEW AUTO-FIRE LOGIC ---
      if (_isDragging && _shootCooldown <= 0) {
        _shoot();
        _shootCooldown = 5; // Fire every 5 ticks (approx 250ms)
      }
      if (_shootCooldown > 0) {
        _shootCooldown--;
      }
      // ---------------------------

      // 1. Move Missiles Up
      for (var m in _missiles) m['y'] = m['y']! - 0.05;
      _missiles.removeWhere((m) => m['y']! < -1.1); // Remove off-screen

      // 2. Move Meteors Down
      for (var m in _meteors) m['y'] = m['y']! + 0.02;
      _meteors.removeWhere((m) => m['y']! > 1.1);

      // 3. Spawn Meteors Randomly (approx 1 every 20 ticks)
      if (Random().nextInt(20) == 0) {
        _meteors.add({'x': Random().nextDouble() * 2 - 1, 'y': -1.2});
      }

      // 4. Collision Detection
      List<Map<String, double>> missilesToRemove = [];
      List<Map<String, double>> meteorsToRemove = [];

      for (var missile in _missiles) {
        for (var meteor in _meteors) {
          double dx = (missile['x']! - meteor['x']!).abs();
          double dy = (missile['y']! - meteor['y']!).abs();
          
          // Hitbox check
          if (dx < 0.15 && dy < 0.15) {
            missilesToRemove.add(missile);
            meteorsToRemove.add(meteor);
            _score++; // Hit!
          }
        }
      }

      // Cleanup hit objects
      for (var m in missilesToRemove) _missiles.remove(m);
      for (var m in meteorsToRemove) _meteors.remove(m);
    });
  }

  void _shoot() {
    if (_gameOver) return;
    // Don't call setState here because it's already called inside _updateGame
    _missiles.add({'x': _playerX, 'y': 0.8}); // Spawn at player pos
  }

  void _endGame() async {
    _gameOver = true;
    _gameLoop?.cancel();
    _timer?.cancel();

    double earnings = _score * 0.1; // 0.1 coin per hit

    // Update Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'coins': FieldValue.increment(earnings),
      });
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Mission Complete!"),
          content: Text("Score: $_score\nEarned: ${earnings.toStringAsFixed(1)} Coins", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, earnings);
              },
              child: const Text("Collect"),
            )
          ],
        )
      );
    }
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // --- UPDATED GESTURE LOGIC ---
        // 1. Start firing when touch begins
        onHorizontalDragStart: (details) {
          setState(() => _isDragging = true);
        },
        // 2. Update position while dragging
        onHorizontalDragUpdate: (details) {
          setState(() {
            _playerX += details.delta.dx * 0.005;
            _playerX = _playerX.clamp(-1.0, 1.0);
            _isDragging = true; // Ensure flag is true
          });
        },
        // 3. Stop firing when touch ends
        onHorizontalDragEnd: (details) {
          setState(() => _isDragging = false);
        },
        onHorizontalDragCancel: () {
          setState(() => _isDragging = false);
        },
        // -----------------------------

        child: Stack(
          children: [
            // Background Stars
            ...List.generate(20, (index) => Positioned(
              top: Random().nextDouble() * MediaQuery.of(context).size.height,
              left: Random().nextDouble() * MediaQuery.of(context).size.width,
              child: Container(width: 2, height: 2, color: Colors.white),
            )),

            // UI: Score & Time
            Positioned(
              top: 40, left: 20,
              child: Text("Score: $_score", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Positioned(
              top: 40, right: 20,
              child: Text("Time: $_timeLeft", style: TextStyle(color: _timeLeft < 5 ? Colors.red : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            // Player Ship
            Align(
              alignment: Alignment(_playerX, 0.9),
              child: const Icon(Icons.rocket, color: Colors.cyan, size: 40),
            ),

            // Missiles
            ..._missiles.map((m) => Align(
              alignment: Alignment(m['x']!, m['y']!),
              child: Container(width: 4, height: 10, color: Colors.yellow),
            )),

            // Meteors
            ..._meteors.map((m) => Align(
              alignment: Alignment(m['x']!, m['y']!),
              child: const Icon(Icons.public, color: Colors.brown, size: 30),
            )),
            
            // Helper Text
            if (_timeLeft > 25 && !_isDragging)
              const Center(child: Text("Hold & Drag to Auto-Fire", style: TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }
}