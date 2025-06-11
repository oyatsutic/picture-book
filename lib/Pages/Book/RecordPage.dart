import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:picturebook/Pages/HomePage.dart';
import 'package:picturebook/Services/config.dart';

class Recordpage extends ConsumerStatefulWidget {
  const Recordpage({super.key, required this.book});
  final Book book;
  @override
  ConsumerState<Recordpage> createState() => _RecordpageState();
}

class _RecordpageState extends ConsumerState<Recordpage> {
  String? _localPdfPath;
  bool _loading = true;
  bool _showButtons = false;
  bool _setVolume = false;
  double _volume = 0.5;
  late PdfController pdfController;
  late PdfControllerPinch pdfControllerPinch;
  int currentPage = 1;
  int totalPage = 1;
  double _pdfOpacity = 1.0;
  bool _isTransitioning = false;
  bool _isPdfReady = false;

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
        // Preload the PDF document
        final document = PdfDocument.openFile(filePath);

        setState(() {
          _localPdfPath = filePath;
          pdfControllerPinch = PdfControllerPinch(document: document);
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

  Future<void> _animatePageTransition(bool isNext) async {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      _pdfOpacity = 0.2;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    if (isNext && currentPage < totalPage) {
      pdfControllerPinch.jumpToPage(currentPage);
      setState(() {
        currentPage = currentPage + 1;
      });
    } else if (!isNext && currentPage > 1) {
      pdfControllerPinch.jumpToPage(currentPage - 2);
      setState(() {
        currentPage = currentPage - 1;
      });
    }
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _pdfOpacity = 1.0;
      _isTransitioning = false;
    });
  }

  @override
  void dispose() {
    pdfControllerPinch.dispose();
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
              opacity: _loading ? 0.0 : _pdfOpacity,
              duration: const Duration(milliseconds: 100),
              child: PdfViewPinch(
                onDocumentLoaded: (document) {
                  setState(() {
                    totalPage = document.pagesCount.toInt();
                    _isPdfReady = true;
                  });
                },
                onPageChanged: (_currentPage) {
                  setState(() {
                    currentPage = _currentPage;
                  });
                },
                scrollDirection: Axis.horizontal,
                controller: pdfControllerPinch,
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  pageLoaderBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, error) =>
                      Center(child: Text(error.toString())),
                ),
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
                        setState(() {
                          _showButtons = false;
                        });
                        // Wait for animation to complete before navigating back
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()));
                          }
                        });
                      },
                      child: Image.asset('assets/images/home_button_blue.png',
                          width: 55, height: 55),
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
                        width: 55,
                        height: 18,
                        child: Center(
                          child: Text(
                            '$currentPage/$totalPage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 59, 138, 61),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
              height: size.height * 0.5,
              child: AnimatedOpacity(
                opacity: _showButtons ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1000),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      !_setVolume
                          ? SizedBox(
                              width: size.width * 0.15 / 2 - 5,
                              child: CupertinoButton(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  onPressed: () {
                                    setState(() {
                                      _setVolume = true;
                                    });
                                  },
                                  child: Image.asset(
                                    'assets/images/volume_button.png',
                                    width: size.width * 0.15 / 2 - 5,
                                  )))
                          : Container(),
                      _setVolume
                          ? GestureDetector(
                              onVerticalDragUpdate: (details) {
                                setState(() {
                                  _volume = (_volume - details.delta.dy / 100)
                                      .clamp(0.0, 1.0);
                                });
                              },
                              onTap: () {
                                setState(() {
                                  _setVolume = false;
                                });
                              },
                              child: SizedBox(
                                width: size.width * 0.15 / 2 - 5,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/volume_lable.png',
                                      height: size.width * 0.85 / 6.9 * 2,
                                      width: 35,
                                      fit: BoxFit.fill,
                                    ),
                                    Positioned(
                                      bottom: _volume * 105 + 12,
                                      child: Image.asset(
                                        'assets/images/volume_button.png',
                                        width: 26,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          : Container(),
                      Stack(
                        children: [
                          SizedBox(
                            // margin: const EdgeInsets.only(bottom: 15),
                            width: size.width * 0.85,
                            child: Image.asset('assets/images/button_box.png'),
                          ),
                          Container(
                              width: size.width * 0.85,
                              height: size.width * 0.85 / 6.5625,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: size.width * 0.85 - 30,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CupertinoButton(
                                        padding: EdgeInsets.all(0),
                                        child: Image.asset(
                                          'assets/images/previous.png',
                                          width: 32,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (currentPage > 1) {
                                              _animatePageTransition(false);
                                            }
                                          });
                                        }),
                                    CupertinoButton(
                                        padding: EdgeInsets.all(0),
                                        child: Image.asset(
                                          'assets/images/play_button.png',
                                          width: 50,
                                        ),
                                        onPressed: () {}),
                                    CupertinoButton(
                                        padding: EdgeInsets.all(0),
                                        child: Image.asset(
                                            'assets/images/next.png',
                                            width: 32),
                                        onPressed: () {
                                          setState(() {
                                            if (currentPage < totalPage) {
                                              _animatePageTransition(true);
                                            }
                                          });
                                        })
                                  ],
                                ),
                              )),
                        ],
                      ),
                      CupertinoButton(
                        onPressed: () {},
                        child: Text(''),
                      )
                    ]),

                // CupertinoButton(
                //   onPressed: () {
                //     setState(() {
                //       if (currentPage > 1) {
                //         pdfControllerPinch.previousPage(
                //             duration: const Duration(milliseconds: 500),
                //             curve: Curves.easeInOut);
                //       }
                //     });
                //   },
                //   child: const PreviousbuttonWidget(),
                // ),
                // CupertinoButton(
                //   onPressed: () {
                //     setState(() {
                //       if (currentPage < totalPage) {
                //         pdfControllerPinch.nextPage(
                //             duration: const Duration(milliseconds: 500),
                //             curve: Curves.easeInOut);
                //       }
                //     });
                //   },
                //   child: const NextbuttonWidget(),
                // )
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
