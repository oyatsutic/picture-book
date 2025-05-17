import 'package:flutter/material.dart';
import 'package:picturebook/Models/book.dart';

class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key, required this.book});
  final Book book;
  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
