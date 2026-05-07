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
  Key exercisesKey = UniqueKey();
  int _currentIndex = 0;
  int? highlightLogId;
  bool showPrsOnly = false;
  bool openAddLog = false;
  bool forceChangePassword = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _currentIndex = args['tabIndex'] ?? 0;

      highlightLogId = args['highlightLogId'];

      showPrsOnly = args['showPrsOnly'] ?? false;

      openAddLog = args['openAddLog'] ?? false;

      forceChangePassword = args['forceChangePassword'] ?? false;
    }
  }

  void _changeTab(int index, {bool openAdd = false}) {
    setState(() {
      if (index == 1 && _currentIndex == 1) {
        exercisesKey = UniqueKey();
      }

      _currentIndex = index;

      openAddLog = openAdd;

      highlightLogId = null;
      showPrsOnly = false;
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          onNavigateToTab: _changeTab,
          onOpenLog: (log) {
            setState(() {
              _currentIndex = 3;
              highlightLogId = log.id;
              showPrsOnly = log.isPr;
            });
          },
        );
      case 1:
        return ExercisesScreen(key: exercisesKey);
      case 2:
        return const CameraScreen();
      case 3:
        return LogsScreen(
          highlightLogId: highlightLogId,
          initialShowPrsOnly: showPrsOnly,
          openAddDialog: openAddLog,
        );
      case 4:
        final shouldForceChangePassword = forceChangePassword;

        forceChangePassword = false;

        return AccountScreen(forceChangePassword: shouldForceChangePassword);
      default:
        return HomeScreen(
          onNavigateToTab: _changeTab,
          onOpenLog: (log) {
            setState(() {
              _currentIndex = 3;
              highlightLogId = log.id;
              showPrsOnly = log.isPr;
            });
          },
        );
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
