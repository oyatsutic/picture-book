import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:picturebook/Pages/HomePage.dart';

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({super.key});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _showVideo = true;
  double _videoOpacity = 1.0;
  double _backgroundOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize video player
    _videoController = VideoPlayerController.asset('assets/splashvideo.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        // Start playing as soon as initialized
        _videoController.play();

        // Listen for video completion
        _videoController.addListener(() {
          // Start fading out when video is 0.5 seconds from ending
          if (_videoController.value.duration -
                  _videoController.value.position <=
              const Duration(milliseconds: 1000)) {
            setState(() {
              _videoOpacity = 0.0;
              _backgroundOpacity = 1.0;
            });
          }

          // Hide video after it's fully faded out
          if (_videoController.value.position >=
              _videoController.value.duration) {
            setState(() {
              _showVideo = false;
            });
            // Navigate to HomePage when video ends
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 1000),
              ),
            );
          }
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Video layer
          if (_showVideo && _isVideoInitialized)
            Positioned(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _videoOpacity,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  child: SizedBox(
                    width: size.width * 0.6,
                    height: size.height * 0.6,
                    child: AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _backgroundOpacity,
              duration: const Duration(milliseconds: 1000),
              child: Image.asset('assets/images/background.jpg'),
            ),
          ),
        ],
      ),
    );
  }
}
