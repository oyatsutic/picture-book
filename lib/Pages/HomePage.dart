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

    return Scaffold(
      body: _showVideo && _isVideoInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
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
