import 'package:flutter/material.dart';

class NextbuttonWidget extends StatelessWidget {
  const NextbuttonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      child: Image.asset(
        fit: BoxFit.fitWidth,
        'assets/images/next_button.png',
      ),
    );
  }
}
