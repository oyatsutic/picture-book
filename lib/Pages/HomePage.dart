import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Pages/Pay/PayPage.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:picturebook/Widgets/BookTitle.dart';
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
  bool _showPDF = false;
  double _videoOpacity = 1.0;
  double _backgroundOpacity = 0.0;
  Book _book = new Book(
      id: '',
      name: '',
      description: '',
      animationThumbUrl: '',
      animationUrl: '',
      price: 123,
      publish: 'publish',
      shared: ['shared'],
      modifiedAt: 'modifiedAt',
      size: 11,
      pdfFile: new PdfFile(name: 'name', size: 12, url: 'url'),
      audioFiles: []);
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
          }
          // show pdf after it's fully faded out

          if (_videoController.value.duration -
                  _videoController.value.position <=
              const Duration(milliseconds: 2000)) {
            setState(() {
              _showPDF = true;
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Video layer
          if (_showVideo && _isVideoInitialized)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _videoOpacity,
                  duration: const Duration(milliseconds: 1000),
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
              ),
            )
          else
            // Optional: Add a placeholder or keep background clear
            Positioned.fill(
              child: Container(
                color: Colors.white, // or your preferred background
              ),
            ),
          Positioned.fill(
              child: _showPDF
                  ? AnimatedOpacity(
                      opacity: _backgroundOpacity,
                      duration: const Duration(milliseconds: 2000),
                      // curve: Curves.bounceIn,
                      child: Image.asset('assets/images/background.jpg'))
                  : const Center()),
          // ListView or other content
          Positioned.fill(
              child: _showPDF
                  ? books.isEmpty
                      ? const Center()
                      : AnimatedOpacity(
                          opacity: _backgroundOpacity,
                          duration: const Duration(milliseconds: 1000),
                          child: ListView.builder(
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return BookTitle(book: book);
                            },
                          ))
                  : const Center()),
        ],
      ),
    );
  }
}
