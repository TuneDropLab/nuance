import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/artist_chip.dart';
import 'package:nuance/widgets/general_button.dart';
import 'dart:math';

class GeneratePlaylistCard extends StatelessWidget {
  final String? prompt;
  final VoidCallback onClick;

  const GeneratePlaylistCard({
    required this.prompt,
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
   
    final LinearGradient selectedGradient =
        gradients[Random().nextInt(gradients.length)];

    return GestureDetector(
      onTap: onClick,
      child: Container(
        // margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            width: 2,
            style: BorderStyle.solid,
            color: Colors.transparent,
          ),
          gradient: selectedGradient,
        ),
        child: Column(
          children: [
            Text(
              prompt ?? "",
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            SizedBox(
              width: Get.width,
              child: GeneralButton(
                hasPadding: true,
                text: "Generate",
                backgroundColor: Colors.white.withOpacity(0.4),
                color: Colors.white,
                icon: SvgPicture.asset(
                  'assets/icon4star.svg',
                  width: 10,
                  height: 10,
                ),
                onPressed: onClick,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
