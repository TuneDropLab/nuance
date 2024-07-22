// import 'package:flutter/material.dart';
// import 'package:mesh_gradient/mesh_gradient.dart';

// class AnimatedGradientButton extends StatefulWidget {
//   const AnimatedGradientButton({super.key});

//   @override
//   _AnimatedGradientButtonState createState() => _AnimatedGradientButtonState();
// }

// class _AnimatedGradientButtonState extends State<AnimatedGradientButton> {
//   late final AnimatedMeshGradientController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimatedMeshGradientController();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//           // shape: BoxShape.circle,
//           ),
//       width: 100,
//       height: 50,
//       child: ClipRRect(
//         borderRadius: const BorderRadius.all(
//           Radius.circular(10),
//         ),
//         child: Stack(
//           children: [
//             Positioned.fill(
//               child: AnimatedMeshGradient(
//                 controller: _controller,
//                 colors: const [
//                   // Color.fromARGB(255, 164, 136, 126),
//                   // Color.fromARGB(255, 239, 212, 130),
//                   Color.fromARGB(255, 151, 253, 234),
//                   Color.fromARGB(255, 151, 253, 234),
//                   Color.fromARGB(255, 147, 192, 237),
//                   Color.fromARGB(255, 147, 192, 237),
//                   // Color.fromARGB(255, 145, 145, 248),
//                   // Color.fromARGB(255, 254, 197, 254),
//                   // Color.fromARGB(255, 204, 255, 204),
//                   // Color.fromARGB(255, 255, 229, 204),
//                 ],
//                 options: AnimatedMeshGradientOptions(
//                   amplitude: 18,
//                   grain: 0.1,
//                   frequency: 5,
//                   speed: 15,
//                 ),
//                 // child:
//               ),
//             ),
//             const Center(
//               child: Icon(
//                 Icons.blur_on_sharp,
//                 color: Colors.black,
//                 size: 40,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
