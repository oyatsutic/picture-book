import 'package:flutter/material.dart';

class MaskButton extends StatelessWidget {
  const MaskButton({super.key, required this.button_name});
  final String button_name;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return MaterialButton(
      onPressed: () {},
      child: Container(
        width: size.width * 0.2,
        child: Image.asset(
          fit: BoxFit.fitWidth,
          'assets/images/$button_name.png',
        ),
      ),
    );
  }
}
