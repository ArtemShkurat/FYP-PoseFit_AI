import 'package:flutter/material.dart';
// import '../widgets/bottom_nav_bar.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      // bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: const Center(
        child: Text('Camera Screen'),
      ),
    );
  }
}