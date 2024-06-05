import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String? accessToken;
  static var routeName = '/home';

  const HomeScreen({super.key, this.accessToken});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("accessToken: ${widget.accessToken ?? ""}"),
      ),
    );
  }
}
