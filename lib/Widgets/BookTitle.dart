import 'package:flutter/material.dart';
import 'package:picturebook/Models/book.dart';
import 'package:picturebook/Pages/HomePage.dart';
import 'package:picturebook/Screens/BookScreen.dart';
import 'package:picturebook/Screens/MaskScreen.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: isBookAccessible
            ? () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => BookScreen(
                          book: widget.book,
                        )
                    // MaskScreen()

                    ));
              }
            : () {
// go to download page
              },
        child: Stack(
          children: [
            Container(
              // width: double.infinity,
              // height: double.infinity,
              child: Image.asset(
                  width: double.infinity,
                  height: double.infinity,
                  'assets/images/bookpage.jpg',
                  fit: BoxFit.cover),
            ),
            if (!isBookAccessible)
              Opacity(
                  opacity: isBookAccessible ? 1.0 : 0.4,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: const Center(
                      child: Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    // child: Icon(Icons.download),
                  )),
            // Positioned.fill(
            //   child: Center(),
            // ),
          ],
        ));
  }
}
