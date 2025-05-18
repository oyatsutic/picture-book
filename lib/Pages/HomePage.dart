import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Pages/Pay/PayPage.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:picturebook/Services/config.dart';
import 'package:picturebook/Widgets/BookTitle.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  Book _book = new Book(
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

  Future<void> downloadFile(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);
    }
  } 

  Future<void> downloadBookAssets(List<Book> books, String userEmail) async {
    for (final book in books) {
      final isFree = book.price == 0;
      final isPurchased = book.purchased.contains(userEmail);
      if (isFree || isPurchased) {
        // Download PDF
        await downloadFile(book.pdfFile.url, '${book.id}.pdf');
        // Download animation
        await downloadFile(book.animationUrl, '${book.id}_animation.mp4');
        // Download audio files
        for (final audio in book.audioFiles) {
          await downloadFile(audio.url, '${book.id}_${audio.name}.mp3');
        }
      }
    }
  }

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
      await downloadBookAssets(books, userEmail);
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

    return Scaffold(
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
                                  width: size.width * 0.8,
                                  child: GridView.builder(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 30, 0, 30),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 20,
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.9, // adjust as needed
                                    ),
                                    itemCount: 10,
                                    itemBuilder: (context, index) {
                                      final book = books[index];
                                      return BookTitle(book: book);
                                    },
                                  ))))
                  : const Center()),
        ],
      ),
    );
  }
}
