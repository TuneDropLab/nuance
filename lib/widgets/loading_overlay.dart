import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final bool? isSuccess;

  const LoadingOverlay({Key? key, required this.isLoading, this.isSuccess})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : isSuccess != null
            ? Container(
                color: Colors.black54,
                child: Center(
                  child: Icon(
                    isSuccess! ? Icons.check_circle : Icons.error,
                    color: isSuccess! ? Colors.green : Colors.red,
                    size: 60,
                  ),
                ),
              )
            : const SizedBox.shrink();
  }
}
