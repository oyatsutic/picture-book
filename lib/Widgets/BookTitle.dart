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
      // child: Image.network(widget.book.imageUrl),
      // child: Image.network('https://firebasestorage.googleapis.com/v0/b/atamanote-c354a.firebasestorage.app/o/book1.png?alt=media&token=52c565d8-7966-449c-96f3-68c7bad07a52'),
      // child: Image.asset('assets/images/bookpage.jpg'),
    );
  }
}
