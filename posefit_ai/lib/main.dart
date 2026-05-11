import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posefit_ai/utils/app_theme.dart';

import 'controller/auth_service.dart';
import 'view/screens/starting_screen.dart';
import 'view/screens/login_screen.dart';
import 'view/screens/signup_screen.dart';
import 'view/widgets/main_navigation_screen.dart';
import 'view/screens/settings_screen.dart';
import 'view/screens/camera_settings_screen.dart';
import 'view/screens/exercise_details_screen.dart';
import 'view/screens/help_support_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const PoseFitApp());
}

class PoseFitApp extends StatelessWidget {
  const PoseFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoseFit AI',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthCheckScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/main-navigation': (context) => const MainNavigationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/camera-settings': (context) => const CameraSettingsScreen(),
        '/exercise-details': (context) => const ExerciseDetailsScreen(),
        '/help-support': (context) => const HelpSupportScreen(),
      },
    );
  }
}

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data!
            ? const MainNavigationScreen()
            : const StartingScreen();
      },
    );
  }
}
