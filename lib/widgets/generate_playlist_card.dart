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
    

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
        gradient: gradient,
      ),
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
                
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
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
    );
  }
}
