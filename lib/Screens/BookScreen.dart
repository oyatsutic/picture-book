import 'package:flutter/cupertino.dart';
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
import 'package:picturebook/Pages/Book/ListenPage.dart';
import 'package:picturebook/Pages/Book/ReadPage.dart';
import 'package:picturebook/Pages/Book/RecordPage.dart';
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
  String currentPage = '';
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

    return
    
    //  PopScope(
    //     canPop: false,
    //     onPopInvoked: (bool didPop) {
    //       if (!didPop) {}
    //     },
    //     child: 
        
        
        // SafeArea(
        //     child: 
            
            
            
            Scaffold(
                body: Stack(
          children: [
            PdfViewPinch(
              controller: pdfControllerPinch,
            ),
            currentPage == 'readpage'
                ? Readpage(book: widget.book)
                : currentPage == 'recordpage'
                    ? Recordpage(book: widget.book)
                    : currentPage == 'listenpage'
                        ? Listenpage(book: widget.book)
                        : Container(),
            currentPage == '' ? const Mask() : Container(),
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
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
                child: Image.asset('assets/images/home_button_blue.png',
                    width: 60, height: 60),
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
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _showButtons = false;
                          currentPage = 'readpage';
                        });
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {}
                        });
                      },
                      child: const MaskButtonWidget(button_name: 'read_button'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _showButtons = false;
                          currentPage = 'listenpage';
                        });
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {}
                        });
                      },
                      child:
                          const MaskButtonWidget(button_name: 'listen_button'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _showButtons = false;
                          currentPage = 'recordpage';
                        });
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {}
                        });
                      },
                      child:
                          const MaskButtonWidget(button_name: 'record_button'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ));
  }
}
