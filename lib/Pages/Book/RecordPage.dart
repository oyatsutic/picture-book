import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/Models/book.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:picturebook/Pages/HomePage.dart';
import 'package:picturebook/Providers/book_provider.dart';
import 'package:picturebook/Screens/BookScreen.dart';
import 'package:picturebook/Services/config.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart'; // Import stop_watch_timer
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

class Recordpage extends ConsumerStatefulWidget {
  const Recordpage({super.key, required this.book});
  final Book book;
  @override
  ConsumerState<Recordpage> createState() => _RecordpageState();
}

class _RecordpageState extends ConsumerState<Recordpage>
    with WidgetsBindingObserver {
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
  bool isRecording = false;
  bool isRecorded = false;
  String? _recordingPath;
  Timer? _timer;
  int _recordingDuration = 0;
  late int _maxDuration = 60;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  final _stopWatchTimer = StopWatchTimer(
    onChange: (value) => debugPrint('onChange $value'),
    onChangeRawSecond: (value) => debugPrint('onChangeRawSecond $value'),
    onChangeRawMinute: (value) => debugPrint('onChangeRawMinute $value'),
    onStopped: () {
      debugPrint('onStop');
    },
    onEnded: () {
      debugPrint('onEnded');
    },
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPdf();
    _stopWatchTimer.setPresetMinuteTime(00);
    _stopWatchTimer.setPresetSecondTime(00);
    _initializeRecorder();
    _initializeRecordingState();
    _initializeAudioPlayer();

    // Start showing buttons immediately with animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showButtons = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _stopWatchTimer.dispose();
    pdfControllerPinch.dispose();
    // _videoController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('App paused - stopping audio playback');
        if (_isPlaying) {
          _audioPlayer.stop();
          setState(() {
            _isPlaying = false;
          });
        }
        break;
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        break;
      default:
        break;
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      final hasPermission = await Permission.microphone.request();
      if (!hasPermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('マイクの許可が必要です')),
          );
          Navigator.pop(context);
        }
        return;
      }
      // Initialize the recorder
      await _audioRecorder.hasPermission();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レコーダーの初期化に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _initializeRecordingState() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final bookDir = Directory('${tempDir.path}/${widget.book.name}');
      final recordingPath = '${bookDir.path}/recording_${currentPage}.m4a';

      setState(() {
        _recordingPath = recordingPath;
      });

      // Check if recording file exists for this page
      final file = File(recordingPath);
      if (await file.exists()) {
        setState(() {
          isRecorded = true;
        });
      } else {
        setState(() {
          isRecorded = false;
        });
      }
    } catch (e) {
      // Handle error silently during initialization
      debugPrint('Error initializing recording state: $e');
    }
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      // Initialize audio player with default settings
      await _audioPlayer.setVolume(_volume);
      debugPrint('Audio player initialized successfully');
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize audio player: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (isRecording) {
      return; // Already recording, don't start another
    }

    if (!_isPdfReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF is not ready yet. Please wait.')),
        );
      }
      return;
    }

    // Check if recording already exists and show confirmation dialog
    if (isRecorded && await _doesRecordingExist()) {
      final shouldOverwrite = await _showOverwriteConfirmation();
      if (!shouldOverwrite) {
        return; // User cancelled
      }
    }

    try {
      // Stop any currently playing audio
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
      }

      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('マイクの許可が必要です')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final bookDir = Directory('${tempDir.path}/${widget.book.name}');

      // Create directory if it doesn't exist
      if (!await bookDir.exists()) {
        await bookDir.create(recursive: true);
      }

      _recordingPath = '${bookDir.path}/recording_${currentPage}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
            // encoder: AudioEncoder.aacLc,
            // bitRate: 128000,
            // sampleRate: 44100,
            ),
        path: _recordingPath!,
      );

      _timer?.cancel(); // Cancel any existing timer
      _recordingDuration = 0; // Reset recording duration

      setState(() {
        isRecording = true;
        isRecorded =
            false; // Reset recorded state since we're starting new recording
      });

      // Reset stopwatch to 00:00 and start it
      _stopWatchTimer.onResetTimer();
      _stopWatchTimer.onStartTimer();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
          if (_recordingDuration >= _maxDuration) {
            _stopRecording();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
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
                          width:190,
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
                          width:190,
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

  Future<bool> _showOverwriteConfirmation() async {
    final size = MediaQuery.sizeOf(context);
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
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
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    width: size.width * 0.5,
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'このページはすでに録音されています。\nもう一度録音しますか?',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                                height: 30,
                                width: 100,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 247, 147, 29),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Text('はい',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                )),
                            const SizedBox(width: 20),
                            SizedBox(
                                width: 100,
                                height: 30,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 0, 174, 239),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Text('いいえ',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ));
          },
        ) ??
        false;
  }

  Future<bool> _doesRecordingExist() async {
    if (_recordingPath == null) return false;
    final file = File(_recordingPath!);
    return await file.exists();
  }

  Future<bool> _isValidAudioFile() async {
    if (_recordingPath == null) return false;
    final file = File(_recordingPath!);
    if (!await file.exists()) return false;

    // Check if file has content (size > 0)
    final fileSize = await file.length();
    return fileSize > 0;
  }

  Future<void> _stopRecording() async {
    if (!isRecording) {
      return; // Not recording, nothing to stop
    }

    try {
      _timer?.cancel();
      _timer = null;

      final path = await _audioRecorder.stop();
      _stopWatchTimer.onStopTimer(); // Stop the stopwatch

      if (path != null) {
        _recordingPath = path;
        // await _processRecording();
      }

      if (mounted) {
        setState(() {
          isRecording = false;
          isRecorded =
              true; // Set recorded state to true after successful recording
          _recordingDuration = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _processRecording() async {
    try {
      // Upload audio file
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process recording: $e')),
      );
    } finally {
      setState(() {});
    }
  }

  Future<void> _playRecording() async {
    console(['_playRecording called']);

    if (_recordingPath == null || !await _isValidAudioFile()) {
      console(['No valid recording available to play']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No valid recording available to play')),
        );
      }
      return;
    }

    console(['Recording path: $_recordingPath']);

    try {
      if (_isPlaying) {
        console(['Stopping current playback']);
        // Stop playing
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.stop();

        try {
          await _audioPlayer.setVolume(_volume);
          console(['Volume set successfully']);
        } catch (e) {
          console(['Error setting volume: $e']);
        }

        try {
          await _audioPlayer.setFilePath(_recordingPath!);
          console(['Audio file set successfully']);
        } catch (e) {
          console(['Error setting file path: $e']);
          throw e; // Re-throw this error as it's critical
        }

        // Add a small delay to ensure the file is properly loaded
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          await _audioPlayer.play();
          console(['Play command sent successfully']);
        } catch (e) {
          console(['Error starting playback: $e']);
          throw e; // Re-throw this error as it's critical
        }

        setState(() {
          _isPlaying = true;
        });

        _audioPlayer.playerStateStream.listen((state) {
          debugPrint('Player state changed: ${state.processingState}');
          if (mounted) {
            if (state.processingState == ProcessingState.completed) {
              debugPrint('Playback completed');
              setState(() {
                _isPlaying = false;
              });
            } else if (state.processingState == ProcessingState.idle) {
              debugPrint('Player state idle');
              setState(() {
                _isPlaying = false;
              });
            }
          }
        });
      }
      // Note: We don't touch the stopwatch timer here - it should remain independent
    } catch (e) {
      console(['Error in _playRecording: $e']);
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play recording: $e')),
        );
      }
    }
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
    
    // PopScope(
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
                onPageChanged: (_currentPage) async {
                  // Stop any current recording or playback when changing pages
                  if (isRecording) {
                    await _stopRecording();
                  }
                  if (_isPlaying) {
                    await _audioPlayer.stop();
                  }

                  setState(() {
                    currentPage = _currentPage;
                    isRecording = false;
                    _isPlaying = false;
                    _recordingDuration = 0;
                  });

                  // Reset stopwatch
                  _stopWatchTimer.onResetTimer();

                  // Check if recording exists for the new page
                  final tempDir = await getTemporaryDirectory();
                  final bookDir =
                      Directory('${tempDir.path}/${widget.book.name}');
                  final newRecordingPath =
                      '${bookDir.path}/recording_${_currentPage}.m4a';

                  setState(() {
                    _recordingPath = newRecordingPath;
                  });

                  // Check if recording file exists for this page
                  final file = File(newRecordingPath);
                  if (await file.exists()) {
                    setState(() {
                      isRecorded = true;
                    });
                  } else {
                    setState(() {
                      isRecorded = false;
                    });
                  }
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
                          // _showButtons = false;
                        });
                        // Wait for animation to complete before navigating back
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            _showExitDialog(context);
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
                                  spreadRadius: 0),
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
                                fontSize: 14),
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
                                    width: 50,
                                  )))
                          : Container(),
                      _setVolume
                          ? GestureDetector(
                              onVerticalDragUpdate: (details) {
                                setState(() {
                                  _volume = (_volume - details.delta.dy / 100)
                                      .clamp(0.0, 1.0);
                                });
                                // Update audio player volume if playing
                                if (_isPlaying) {
                                  _audioPlayer.setVolume(_volume);
                                }
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
                                        height: size.width * 0.83 / 6.9 * 2,
                                        width: 35,
                                        fit: BoxFit.fill),
                                    Positioned(
                                      bottom: _volume * 105 + 12,
                                      child: Image.asset(
                                          'assets/images/volume_button.png',
                                          width: 26),
                                    ),
                                  ],
                                ),
                              ))
                          : Container(),
                      Stack(
                        children: [
                          SizedBox(
                              // margin: const EdgeInsets.only(bottom: 15),
                              width: size.width -150,
                              height: 70,
                              child: Image.asset(
                                  fit: BoxFit.fill,
                                  'assets/images/button_box.png')),
                          Container(
                              width: size.width -150,
                              height: 70,
                              alignment: Alignment.center,
                              child: SizedBox(
                              width: size.width -180,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CupertinoButton(
                                          padding: EdgeInsets.all(0),
                                          child: Image.asset(
                                              'assets/images/previous.png',
                                              width: 32),
                                          onPressed: () {
                                            setState(() {
                                              if (currentPage > 1) {
                                                _animatePageTransition(false);
                                              }
                                            });
                                          }),
                                      Expanded(child: Container(color: Colors.green)),
                                      CupertinoButton(
                                          padding: EdgeInsets.all(0),
                                          child: Image.asset(
                                              'assets/images/play_button.png',
                                              height: size.height * 0.13),
                                          onPressed: () {}),
                                      Expanded(
                                          child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        height: size.height * 0.12,
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Image.asset(
                                                      width: size.width *
                                                          0.83 *
                                                          0.2,
                                                      height:
                                                          size.height * 0.07,
                                                      fit: BoxFit.fill,
                                                      'assets/images/timebox.png'),
                                                  StreamBuilder<int>(
                                                    stream:
                                                        _stopWatchTimer.rawTime,
                                                    initialData: 0,
                                                    builder: (context, snap) {
                                                      final value = snap.data;
                                                      final displayMin =
                                                          StopWatchTimer
                                                              .getDisplayTimeMinute(
                                                                  value!);
                                                      final displaySec =
                                                          StopWatchTimer
                                                              .getDisplayTimeSecond(
                                                                  value);
                                                      return Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            displayMin,
                                                            style: const TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Text(
                                                            ':${displaySec.toString()}',
                                                            style: const TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            CupertinoButton(
                                                padding: EdgeInsets.all(0),
                                                child: Image.asset(
                                                    height: size.height * 0.12,
                                                    width: size.height * 0.12,
                                                    fit: BoxFit.fill,
                                                    isRecording
                                                        ? 'assets/images/stop_recording.png'
                                                        : 'assets/images/recording_button.png'),
                                                onPressed: () {
                                                  if (isRecording) {
                                                    _stopRecording();
                                                  } else {
                                                    _startRecording();
                                                  }
                                                }),
                                            Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: isRecorded
                                                    ? CupertinoButton(
                                                        padding:
                                                            EdgeInsets.all(0),
                                                        child: Image.asset(
                                                            height:
                                                                size.height *
                                                                    0.12,
                                                            width: size.height *
                                                                0.12,
                                                            fit: BoxFit.fill,
                                                            _isPlaying
                                                                ? 'assets/images/stop_recording.png'
                                                                : 'assets/images/play_recording.png'),
                                                        onPressed: () {
                                                          _playRecording();
                                                        })
                                                    : Container()),
                                          ],
                                        ),
                                      )),
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
                                          }),
                                    ],
                                  ))),
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

                );
  }
}

Widget recordWidget(BuildContext context, StopWatchTimer _stopWatchTimer) {
  final size = MediaQuery.sizeOf(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    height: size.height * 0.12,
    color: const Color.fromARGB(59, 76, 175, 79),
    child: Stack(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                  width: size.width * 0.14,
                  height: size.height * 0.07,
                  fit: BoxFit.fill,
                  'assets/images/timebox.png'),
              StreamBuilder<int>(
                stream: _stopWatchTimer.rawTime,
                initialData: 0,
                builder: (context, snap) {
                  final value = snap.data;
                  final displayMin =
                      StopWatchTimer.getDisplayTimeMinute(value!);
                  final displaySec = StopWatchTimer.getDisplayTimeSecond(value);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayMin,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ':${displaySec.toString()}',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        CupertinoButton(
            padding: EdgeInsets.all(0),
            child: Image.asset(
                height: size.height * 0.12,
                width: size.height * 0.12,
                fit: BoxFit.fill,
                'assets/images/recording_button.png'),
            onPressed: () {
              _stopWatchTimer.onStartTimer();
            }),
      ],
    ),
  );
}
