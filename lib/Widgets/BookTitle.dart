import 'package:flutter/material.dart';
import 'package:picturebook/Models/book.dart';

class BookTitle extends StatefulWidget {
  const BookTitle({super.key, required this.book});
  final Book book;
  @override
  State<BookTitle> createState() => _BookTitleState();
}

class _BookTitleState extends State<BookTitle> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.22,
      height: MediaQuery.of(context).size.width * 0.25,
      child: Image.network(widget.book.imageUrl),
    );
  }
}
