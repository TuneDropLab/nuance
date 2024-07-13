import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmDialog extends StatelessWidget {
  final String heading;
  final String subtitle;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;

  const ConfirmDialog({
    Key? key,
    required this.heading,
    required this.subtitle,
    this.confirmText = "Okay",
    this.cancelText = "Cancel",
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        heading,
        style: const TextStyle(color: Colors.white),
      ),
      content: Text(
        subtitle,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          child: Text(
            cancelText,
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          // style: TextButton.styleFrom(
          //   foregroundColor: Colors.red, // Button text color
          // ),
          onPressed: () {
            if (onConfirm != null) {
              onConfirm!();
            }
            // Get.back();
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}
