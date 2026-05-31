import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; 
import 'package:permission_handler/permission_handler.dart'; 
import 'dart:async';

class SellerLiveScreen extends StatefulWidget {
  const SellerLiveScreen({super.key});

  @override
  State<SellerLiveScreen> createState() => _SellerLiveScreenState();
}

class _SellerLiveScreenState extends State<SellerLiveScreen> {
  // --- CAMERA VARIABLES ---
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  // ------------------------

  bool _isLive = false;
  final TextEditingController _titleController = TextEditingController();
  int _viewerCount = 0;
  Timer? _viewerTimer;
  final List<String> _comments = [];

  @override
  void initState() {
    super.initState();
    _initCamera(); 
  }

  // --- INITIALIZE CAMERA (HIGH QUALITY) ---
  Future<void> _initCamera() async {
    var status = await Permission.camera.request();
    if (status.isDenied) return;

    _cameras = await availableCameras();
    
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0], 
        // --- KEY CHANGE: SET TO VERY HIGH (1080p) ---
        ResolutionPreset.veryHigh, 
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg, // Better compatibility
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  void _startStream() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a stream title")));
      return;
    }
    setState(() {
      _isLive = true;
      _viewerCount = 12;
    });
    // Simulating Viewers/Comments for the Mock
    _viewerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _viewerCount += 5;
          if (_viewerCount % 2 == 0) _comments.add("User${_viewerCount}: Hello! Is this available?");
        });
      }
    });
  }

  void _endStream() {
    _viewerTimer?.cancel();
    setState(() {
      _isLive = false;
      _viewerCount = 0;
      _comments.clear();
      _titleController.clear();
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Stream Ended"),
        content: const Text("Great job! Your live session has ended."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose(); 
    _viewerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. REAL CAMERA PREVIEW (High Res)
          if (_isCameraInitialized && _cameraController != null)
            // Use CameraPreview directly which handles aspect ratio better usually
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                  height: _cameraController!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          // 2. GRADIENT OVERLAY (Enhanced visibility)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent, Colors.black54],
              ),
            ),
          ),

          // 3. CLOSE BUTTON
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // --- UI STATE 1: SETUP MODE ---
          if (!_isLive) ...[
            Positioned(
              top: 150,
              left: 30,
              right: 30,
              child: Column(
                children: [
                  const Text("Ready to go LIVE?", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Add a title...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 100,
              left: 40,
              right: 40,
              child: ElevatedButton(
                onPressed: _startStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF963B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text("START LIVE VIDEO", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
          // --- UI STATE 2: LIVE BROADCASTING MODE ---
          else ...[
            Positioned(
              top: 50,
              left: 20,
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                    child: const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(5)),
                    child: Text("👁 $_viewerCount", style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 150,
              left: 20,
              right: 100,
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  reverse: true,
                  itemCount: _comments.length,
                  itemBuilder: (ctx, i) {
                    final comment = _comments[_comments.length - 1 - i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(comment, style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 40,
              right: 40,
              child: ElevatedButton(
                onPressed: _endStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("END STREAM", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}