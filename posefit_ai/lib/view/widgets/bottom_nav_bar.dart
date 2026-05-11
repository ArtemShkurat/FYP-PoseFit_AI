import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,

      backgroundColor: AppColors.card,

      selectedItemColor: AppColors.primaryGreen,

      unselectedItemColor: AppColors.secondary,

      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),

      unselectedLabelStyle: const TextStyle(fontSize: 12),

      onTap: onTap,

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Exercises',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.photo_camera),
          label: 'Camera',
        ),

        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Logs'),

        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}
