import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:picturebook/Services/config.dart';
import 'package:picturebook/Services/download.dart';
import 'package:picturebook/Widgets/BookTitle.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:developer' as developer;

final apiUrl = dotenv.env['API_URL'];

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

  final Book _book = Book(
      id: '',
      name: '',
      description: '',
      animationThumbUrl: '',
      animationUrl: '',
      price: 123,
      publish: 'publish',
      purchased: ['purchased'],
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
    Future.microtask(() async {
      await ref.read(booksProvider.notifier).fetchBooks();
      final books = ref.read(booksProvider);
      final userEmail = '';
      // await Download().downloadBookAssets(books, userEmail);
    });
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

    return PopScope(
        canPop: false,
        // onPopInvoked: (bool didPop) {
        //   if (!didPop) {}
        // },
        onPopInvokedWithResult: (bool didPop, result) {},
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Video layer
              if (_showVideo && _isVideoInitialized)
                Positioned(
                  // left: 0,
                  // top: 0,
                  // bottom: 0,
                  // right: 0,
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
              Positioned(
                  // top: 0,
                  // left: 0,
                  // right: 0,
                  child: _showPDF
                      ? books.isEmpty
                          ? const Center()
                          : Center(
                              child: AnimatedOpacity(
                                  opacity: _backgroundOpacity,
                                  duration: const Duration(milliseconds: 1000),
                                  child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      child: GridView.builder(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 30, 0, 30),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisSpacing: 20,
                                                mainAxisSpacing: 20,
                                                crossAxisCount: 3,
                                                childAspectRatio: 0.85),
                                        itemCount: books.length,
                                        itemBuilder: (context, index) {
                                          final book = books[index];
                                          return BookTitle(
                                              book: book, userEmail: '');
                                        },
                                      ))))
                      : const Center()),
            ],
          ),
        ));
  }
}
