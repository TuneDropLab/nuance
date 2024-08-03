import 'package:flutter/material.dart';

class GeneralButton extends StatelessWidget {
  final Color? color;
  final String? text;
  final Widget? icon;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final bool hasPadding;

  const GeneralButton({
    Key? key,
    this.color = Colors.black,
    this.text = 'Save playlist',
    this.icon,
    this.backgroundColor = Colors.orange,
    required this.onPressed,
    this.hasPadding = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 0,
        padding: hasPadding
            ? const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              )
            : const EdgeInsets.symmetric(
                horizontal: 12,
              ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon!,
          if (icon != null) const SizedBox(width: 8),
          Text(
            text as String,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
