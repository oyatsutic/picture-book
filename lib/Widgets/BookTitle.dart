import 'package:flutter/material.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Pages/HomePage.dart';
import 'package:picturebook/Screens/BookScreen.dart';
import 'package:picturebook/Screens/MaskScreen.dart';
import 'package:picturebook/Services/config.dart';
import 'package:picturebook/Services/download.dart';

class BookTitle extends StatefulWidget {
  const BookTitle({
    super.key,
    required this.book,
    required this.userEmail,
  });
  final Book book;
  final String userEmail;

  @override
  State<BookTitle> createState() => _BookTitleState();
}

class _BookTitleState extends State<BookTitle> {
  bool get isBookAccessible =>
      widget.book.price == 0 ||
      widget.book.purchased.contains(widget.userEmail);

  bool _isDownloaded = false;
  bool _isDownloading = false;
  bool _isLoading = true;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  @override
  void didUpdateWidget(BookTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _checkDownloadStatus();
    }
  }

  Future<void> _checkDownloadStatus() async {
    setState(() {
      _isLoading = true;
    });

    final downloaded = await Download().isDownloaded('${widget.book.id}.pdf');
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadBook() async {
    print('Download started for book: ${widget.book.id}');
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await Download().downloadBook(
        widget.book,
        widget.userEmail,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
      }
      print('Download completed for book: ${widget.book.id}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
      print('Download failed for book: ${widget.book.id}. Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: isBookAccessible && _isDownloaded
          ? () {
              print('Opening book: ${widget.book.id}');
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => BookScreen(book: widget.book)));
            }
          : isBookAccessible && !_isDownloaded
              ? () {
                  print('Starting download for book: ${widget.book.id}');
                  _downloadBook();
                }
              : () {
                  print('Book is locked: ${widget.book.id}');
                },
      child: Stack(
        children: [
          Container(
            child: Image.asset(
              'assets/images/bookpage.jpg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          if (!isBookAccessible)
            Opacity(
                opacity: 0.5,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ))
          else if (!_isDownloaded)
            Opacity(
                opacity: 0.5,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Center(
                      child: _isDownloading
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: _downloadProgress,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_downloadProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(widget.book.size).ceil()} MB',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                              ],
                            )),
                )),
        ],
      ),
    );
  }
}
