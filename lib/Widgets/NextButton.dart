import 'package:flutter/material.dart';

class NextbuttonWidget extends StatelessWidget {
  const NextbuttonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      child: Image.asset(
        height: 70,
        fit: BoxFit.fitWidth,
        'assets/images/next_button.png',
      ),
    );
  }
}
