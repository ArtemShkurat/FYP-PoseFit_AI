import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import '../screens/home_screen.dart';
import '../screens/exercises_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/logs_screen.dart';
import '../screens/account_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(onNavigateToTab: _changeTab);
      case 1:
        return const ExercisesScreen();
      case 2:
        return const CameraScreen();
      case 3:
        return const LogsScreen();
      case 4:
        return const AccountScreen();
      default:
        return HomeScreen(onNavigateToTab: _changeTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
      ),
    );
  }
}