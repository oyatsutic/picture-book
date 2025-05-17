import 'package:flutter/material.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Screens/PDFScreen.dart';

class BookTitle extends StatefulWidget {
  const BookTitle({super.key, required this.book});
  final Book book;
  @override
  State<BookTitle> createState() => _BookTitleState();
}

class _BookTitleState extends State<BookTitle> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PdfScreen(
                    book: widget.book,
                  )));
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.20,
          height: MediaQuery.of(context).size.width * 0.3,
          // child: Image.network(widget.book.animationThumbUrl),
          child: Image.asset(
            'assets/images/bookpage.jpg',
            fit: BoxFit.cover,
          ),
        ));
  }
}

