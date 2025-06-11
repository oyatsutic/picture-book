import 'package:flutter/material.dart';

class PreviousbuttonWidget extends StatelessWidget {
  const PreviousbuttonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      child: Image.asset(
        fit: BoxFit.fitWidth,
        'assets/images/previous_button.png',
      ),
    );
  }
}
