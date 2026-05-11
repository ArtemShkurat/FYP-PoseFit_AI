import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../controller/auth_service.dart';
import '../widgets/dialog_text_field.dart';
import '../widgets/app_message_popup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showAppMessagePopup(
        context: context,
        message: 'Please enter email and password.',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.login(email: email, password: password);

      if (!mounted) return;

      if (result['success'] == true) {
        final mustChangePassword = await AuthService.getMustChangePassword();

        if (!mounted) return;

        if (mustChangePassword == 'true' || mustChangePassword == '1') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text(
                  'Password Reset Required',
                  style: AppTextStyles.sectionTitle,
                ),
                content: const Text(
                  'You must change your password before continuing.',
                  style: AppTextStyles.body,
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/main-navigation',
                        (route) => false,
                        arguments: {'tabIndex': 4, 'forceChangePassword': true},
                      );
                    },
                    child: const Text(
                      'Change Password',
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          showAppMessagePopup(
            context: context,
            message: result['message'] ?? 'Login successful.',
            isSuccess: true,
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main-navigation',
            (route) => false,
          );
        }
      } else {
        showAppMessagePopup(
          context: context,
          message: result['message'] ?? 'Login failed.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      showAppMessagePopup(
        context: context,
        message: 'Login failed: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final forgotEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text(
            'Forgot Password',
            style: AppTextStyles.sectionTitle,
          ),
          content: DialogTextField(
            controller: forgotEmailController,
            labelText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = forgotEmailController.text.trim();

                if (email.isEmpty) {
                  showAppMessagePopup(
                    context: context,
                    message: 'Please enter your email.',
                    isError: true,
                  );
                  return;
                }

                Navigator.pop(context);

                if (!mounted) return;

                try {
                  final result = await AuthService.forgotPassword(email: email);

                  if (!mounted) return;

                  showAppMessagePopup(
                    context: this.context,
                    message: result['message'] ?? 'Request completed.',
                    isSuccess: result['success'] == true,
                    isError: result['success'] != true,
                  );
                } catch (e) {
                  if (!mounted) return;

                  showAppMessagePopup(
                    context: this.context,
                    message: 'Error: $e',
                    isError: true,
                  );
                }
              },
              child: const Text('Send', style: AppTextStyles.buttonText),
            ),
          ],
        );
      },
    );

    forgotEmailController.dispose();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.softText),
        title: const Text('Log In', style: AppTextStyles.sectionTitle),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome Back', style: AppTextStyles.heading),

              const SizedBox(height: 8),

              const Text(
                'Log in to continue tracking your workouts.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 32),

              DialogTextField(
                controller: emailController,
                labelText: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                style: AppTextStyles.body,
                cursorColor: AppColors.primaryGreen,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: AppTextStyles.small,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.aiMint,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Text('Log In', style: AppTextStyles.buttonText),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: AppTextStyles.body,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
