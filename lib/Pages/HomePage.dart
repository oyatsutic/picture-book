import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Pages/Pay/PayPage.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:video_player/video_player.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _showVideo = true;
  double _videoOpacity = 1.0;

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
          if (_videoController.value.duration - _videoController.value.position <= const Duration(milliseconds: 500)) {
            setState(() {
              _videoOpacity = 0.0;
            });
          }
          
          // Hide video after it's fully faded out
          if (_videoController.value.position >= _videoController.value.duration) {
            setState(() {
              _showVideo = false;
            });
          }
        });
      });

    // Fetch books in parallel
    Future.microtask(() => ref.read(booksProvider.notifier).fetchBooks());
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: _showVideo && _isVideoInitialized
          ? Center(
              child: AnimatedOpacity(
                opacity: _videoOpacity,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: SizedBox(
                  width: size.width * 0.8,
                  height: size.height * 0.8,
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            )
          : books.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return ListTile(
                      title: Text(book.name),
                      subtitle: Text(book.description),
                    );
                  },
                ),
    );
  }
}
