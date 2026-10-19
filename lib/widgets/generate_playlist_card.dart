import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import 'package:nuance/widgets/general_button.dart';

class GeneratePlaylistCard extends StatelessWidget {
  final String? prompt;
  final String? image;
  final LinearGradient gradient;
  final VoidCallback onClick;

  const GeneratePlaylistCard({
    required this.prompt,
    this.image,
    required this.gradient,
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.trim().isNotEmpty;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          width: 1.5,
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Gradient Fallback
            if (hasImage)
              CachedNetworkImage(
                imageUrl: image!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(gradient: gradient),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(gradient: gradient),
              ),

            // Subtle dark overlay to ensure text contrast and premium feel
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    hasImage
                        ? Colors.black.withOpacity(0.4)
                        : gradient.colors.first.withOpacity(0.4),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),

            // Foreground Text & Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: prompt ?? "",
                    child: Text(
                      prompt ?? "",
                      maxLines: 3,
                      style: const TextStyle(
                        height: 1.2,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: Get.width,
                    child: GeneralButton(
                      hasPadding: true,
                      text: "Generate",
                      backgroundColor: Colors.white.withOpacity(0.25),
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
          ],
        ),
      ),
    );
  }
}
