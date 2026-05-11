import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../controller/auth_service.dart';
import '../widgets/dialog_text_field.dart';
import '../widgets/app_message_popup.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasNumber = false;
  bool hasSymbol = false;

  Future<void> handleSignup() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showAppMessagePopup(
        context: context,
        message: 'Please fill in all fields.',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.signup(
        username: username,
        email: email,
        password: password,
      );

      if (!mounted) return;

      showAppMessagePopup(
        context: context,
        message: result['message'] ?? 'Signup completed.',
        isSuccess: result['success'] == true,
        isError: result['success'] != true,
      );

      if (result['success'] == true) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return;

      showAppMessagePopup(
        context: context,
        message: 'Signup failed: $e',
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

  void validatePassword(String password) {
    setState(() {
      hasMinLength = password.length >= 8;
      hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      hasNumber = RegExp(r'[0-9]').hasMatch(password);
      hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
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
        title: const Text('Create Account', style: AppTextStyles.sectionTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Join PoseFit AI', style: AppTextStyles.heading),

              // const SizedBox(height: 8),

              // const Text(
              //   'Create an account to start tracking your workouts.',
              //   style: AppTextStyles.body,
              // ),
              const SizedBox(height: 28),

              DialogTextField(
                controller: usernameController,
                labelText: 'Username',
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

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
                onChanged: validatePassword,
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

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password must include:',
                      style: AppTextStyles.cardTitle,
                    ),

                    const SizedBox(height: 12),

                    _buildPasswordRequirement(
                      'At least 8 characters',
                      hasMinLength,
                    ),
                    _buildPasswordRequirement('1 capital letter', hasUppercase),
                    _buildPasswordRequirement('1 number', hasNumber),
                    _buildPasswordRequirement('1 symbol', hasSymbol),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleSignup,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Text('Sign Up', style: AppTextStyles.buttonText),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: AppTextStyles.body,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      'Log In',
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

  Widget _buildPasswordRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isValid ? AppColors.primaryGreen : AppColors.secondary,
          ),

          const SizedBox(width: 8),

          Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: isValid ? AppColors.primaryGreen : AppColors.secondary,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
