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
  late Future<void> _initializeVideoPlayerFuture;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize video player
    _videoController = VideoPlayerController.asset('assets/splashvideo.mp4');
    
    // networkUrl(
    //   Uri.parse(
    //     'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    //   ),
    // );
    _initializeVideoPlayerFuture = _videoController.initialize().then((_) {
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController.play();
      _videoController.setLooping(true);
    });

    // Fetch books when the page loads
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
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PayPage()),
              );
            },
            child: const Text('pay page'),
          ),
          Expanded(
            child: books.isEmpty
                ? Center(
                    child: _isVideoInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController.value.aspectRatio,
                            child: VideoPlayer(_videoController),
                          )
                        : const CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return ListTile(
                        title: Text(book.name),
                        subtitle: Text(book.description),
                        // Add more book details as needed
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
