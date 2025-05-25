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

    return
        //  PopScope(
        //     canPop: false,
        //     onPopInvoked: (bool didPop) {
        //       if (!didPop) {}
        //     },
        //     child:

        Scaffold(
            // appBar: AppBar(
            //   title: const Text('PDF Viewer'),
            // ),
            body: Stack(
      children: [
        PdfViewPinch(
          controller: pdfControllerPinch,
        ),
        const Mask(),
        Center(
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

            );
  }
}
