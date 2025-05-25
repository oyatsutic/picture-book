import 'package:flutter/material.dart';
import 'package:picturebook/Widgets/Mask.dart';

class MaskScreen extends StatefulWidget {
  const MaskScreen({super.key});

  @override
  State<MaskScreen> createState() => _MaskScreenState();
}

class _MaskScreenState extends State<MaskScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Mask(),
          Center(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon: Row(
                          children: [Icon(Icons.abc_outlined)],
                        ))
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
