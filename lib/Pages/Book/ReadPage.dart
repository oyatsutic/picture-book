import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:picturebook/Pages/Book/ReadPage.dart';
import 'package:picturebook/Pages/HomePage.dart';
import 'package:picturebook/Screens/BookScreen.dart';
import 'package:picturebook/Services/config.dart';
import 'package:picturebook/Widgets/Mask.dart';
import 'package:picturebook/Widgets/MaskButton.dart';
import 'package:picturebook/Widgets/NextButton.dart';
import 'package:picturebook/Widgets/PreviousButton.dart';
import 'package:video_player/video_player.dart';

class Readpage extends ConsumerStatefulWidget {
  const Readpage({super.key, required this.book});
  final Book book;
  @override
  ConsumerState<Readpage> createState() => _ReadpageState();
}

class _ReadpageState extends ConsumerState<Readpage> {
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
  int currentPage = 1;
  int totalPage = 1;
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

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (!didPop) {}
        },
        child: SafeArea(
            child: Scaffold(
                body: Stack(
          children: [
            AnimatedOpacity(
              opacity: _loading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: PdfViewPinch(
                onDocumentLoaded: (document) => {
                  setState(() {
                    totalPage = document.pagesCount.toInt();
                    console([document, 'this is document']);
                  })
                },
                onPageChanged: (_currentPage) {
                  setState(() {
                    currentPage = _currentPage;
                  });
                },
                scrollDirection: Axis.horizontal,
                controller: pdfControllerPinch,
              ),
            ),
            AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                top: _showButtons ? 10 : -100,
                left: 20,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showExitDialog(context);
                      },
                      child: Image.asset('assets/images/home_button_green.png',
                          width: 60, height: 60),
                    ),
                    Container(
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(139, 0, 0, 0),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ]),
                        width: 60,
                        height: 20,
                        child: Center(
                          child: Text(
                            '$currentPage/$totalPage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 59, 138, 61),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ))
                  ],
                )),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              bottom: _showButtons ? 0 : -100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showButtons ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1000),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.all(0),
                      onPressed: () {
                        setState(() {
                          if (currentPage > 1) {
                            pdfControllerPinch.previousPage(
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeInOut);
                          }
                        });
                      },
                      child: const PreviousbuttonWidget(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.all(0),
                      onPressed: () {
                        setState(() {
                          if (currentPage < totalPage) {
                            pdfControllerPinch.nextPage(
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeInOut);
                          }
                        });
                      },
                      child: const NextbuttonWidget(),
                    )
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

  void _showExitDialog(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Exit Dialog",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 249, 186),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              height: size.width * 0.3,
              width: size.width * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'どこに行きたいですか?',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                          height: 35,
                          width: size.width * 0.3,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 247, 147, 29),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.logout, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text('ライブラリーへ',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ],
                              ))),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: size.width * 0.3,
                          height: 35,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 174, 239),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          BookScreen(book: widget.book)),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.bookmark, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text('はじめに戻る',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ],
                              ))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(anim1),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
}
