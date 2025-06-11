import 'package:flutter/material.dart';

class MaskButtonWidget extends StatelessWidget {
  const MaskButtonWidget(
      {super.key, required this.button_name, this.width = 0.2});
  final String button_name;
  final double width;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * width,
      child: Image.asset(
        fit: BoxFit.fitWidth,
        'assets/images/$button_name.png',
      ),
    );
  }
}
