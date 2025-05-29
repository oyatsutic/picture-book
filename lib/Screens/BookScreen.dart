import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:picturebook/Services/config.dart';
import 'package:picturebook/Widgets/Mask.dart';
import 'package:picturebook/Widgets/MaskButton.dart';
import 'package:video_player/video_player.dart';

class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key, required this.book});
  final Book book;
  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  String? _localPdfPath;
  bool _loading = true;
  bool _showButtons = false;
  late PdfController pdfController;
  late PdfControllerPinch pdfControllerPinch;
  // late VideoPlayerController _videoController;
  // bool _isVideoInitialized = false;
  // bool _showVideo = true;
  // bool _showPDF = false;
  // double _videoOpacity = 1.0;
  // double _backgroundOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPdf();

    // Start showing buttons immediately with animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showButtons = true;
        });
      }
    });

    //   // Initialize video player
    //   _videoController = VideoPlayerController.asset('assets/splashvideo.mp4')
    //     ..initialize().then((_) {
    //       setState(() {
    //         _isVideoInitialized = true;
    //       });
    //       // Start playing as soon as initialized
    //       _videoController.play();

    //       // Listen for video completion
    //       _videoController.addListener(() {
    //         // Start fading out when video is 0.5 seconds from ending
    //         if (_videoController.value.duration -
    //                 _videoController.value.position <=
    //             const Duration(milliseconds: 1000)) {
    //           setState(() {
    //             _videoOpacity = 0.0;
    //             _backgroundOpacity = 1.0;
    //           });
    //         }

    //         // Hide video after it's fully faded out
    //         if (_videoController.value.position >=
    //             _videoController.value.duration) {
    //           setState(() {
    //             _showVideo = false;
    //           });
    //         }
    //         // show pdf after it's fully faded out

    //         if (_videoController.value.duration -
    //                 _videoController.value.position <=
    //             const Duration(milliseconds: 2000)) {
    //           setState(() {
    //             _showPDF = true;
    //           });
    //         }
    //       });
    //     });
  }

  Future<void> _loadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${widget.book.id}.pdf';
      final file = File(filePath);

      if (await file.exists()) {
        setState(() {
          _localPdfPath = filePath;
          pdfController = PdfController(
            document: PdfDocument.openFile(_localPdfPath!),
          );
          pdfControllerPinch = PdfControllerPinch(
              document: PdfDocument.openFile(_localPdfPath!));
          _loading = false;
        });
      } else {
        setState(() {
          _localPdfPath = null;
          _loading = false;
        });
      }
    } catch (e) {
      console(['Error loading PDF: $e']);
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    pdfController.dispose();
    // _videoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_localPdfPath == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('PDF not found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (!didPop) {}
        },
        child: SafeArea(
            child: Scaffold(
                // appBar: AppBar(
                //   title: const Text('PDF Viewer'),
                // ),
                body: Stack(
          children: [
            PdfViewPinch(
              controller: pdfControllerPinch,
            ),
            const Mask(),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              top: _showButtons ? 10 : -100,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showButtons = false;
                  });
                  // Wait for animation to complete before navigating back
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(1.5, 2),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/home_button.png',
                      width: 45, height: 45),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              bottom: _showButtons ? size.height * 0.5 - 50 : -100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showButtons ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1000),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MaterialButton(
                      onPressed: () {},
                      child: MaskButton(button_name: 'read_button'),
                    ),
                    MaterialButton(
                      onPressed: () {},
                      child: MaskButton(button_name: 'listen_button'),
                    ),
                    MaterialButton(
                      onPressed: () {},
                      child: MaskButton(button_name: 'record_button'),
                    ),
                  ],
                ),
              ),
            )
          ],
        )

                // PdfView(
                //   controller: pdfController,
                //   onDocumentLoaded: (document) {
                //     console(['Document loaded: ${document.pagesCount} pages']);
                //   },
                // ),
                // )

                )));
  }
}
