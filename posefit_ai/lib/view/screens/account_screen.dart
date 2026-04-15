import 'package:flutter/material.dart';
// import '../widgets/bottom_nav_bar.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      // bottomNavigationBar: const BottomNavBar(currentIndex: 4),
      body: const Center(
        child: Text('Account Screen'),
      ),
    );
  }
}