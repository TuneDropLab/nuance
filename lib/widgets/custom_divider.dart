import 'package:flutter/material.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0.3,
      color: Color.fromARGB(30, 255, 255, 255),
    );
  }
}
