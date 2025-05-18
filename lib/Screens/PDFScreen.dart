import 'package:flutter/material.dart';
import 'package:picturebook/Models/book.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key, required this.book});
  final Book book;
  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  String? _localPdfPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${widget.book.id}.pdf';
    final file = File(filePath);
    if (await file.exists()) {
      setState(() {
        _localPdfPath = filePath;
        _loading = false;
      });
    } else {
      setState(() {
        _localPdfPath = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localPdfPath == null) {
      return const Center(child: Text('PDF not found.'));
    }
    return SfPdfViewer.file(File(_localPdfPath!));
  }
}
