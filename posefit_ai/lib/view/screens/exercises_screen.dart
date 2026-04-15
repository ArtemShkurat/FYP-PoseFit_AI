import 'package:flutter/material.dart';
// import '../widgets/bottom_nav_bar.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      // bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: const Center(
        child: Text('Exercises Screen'),
      ),
    );
  }
}