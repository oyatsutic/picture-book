import 'package:flutter/material.dart';

class Mask extends StatelessWidget {
  const Mask({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
        left: 0,
        top: 0,
        width: size.width,
        height: size.height,
        child: Opacity(
          opacity: 0.6,
          child: Container(
            color: Colors.black,
          ),
        ));
  }
}
