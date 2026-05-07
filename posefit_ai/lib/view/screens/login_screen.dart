import 'package:flutter/material.dart';
import '../../controller/auth_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
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
                title: const Text('Password Reset Required'),

                content: const Text(
                  'You must change your password before continuing.',
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

                    child: const Text('Change Password'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Login successful.')),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main-navigation',
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
      appBar: AppBar(title: const Text('Log In')),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              TextField(
                controller: emailController,

                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,

                decoration: InputDecoration(
                  labelText: 'Password',

                  border: const OutlineInputBorder(),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,

                child: GestureDetector(
                  onTap: () async {
                    final forgotEmailController = TextEditingController();

                    await showDialog(
                      context: context,

                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Forgot Password'),

                          content: TextField(
                            controller: forgotEmailController,

                            decoration: const InputDecoration(
                              labelText: 'Enter your email',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },

                              child: const Text('Cancel'),
                            ),

                            ElevatedButton(
                              onPressed: () async {
                                final email = forgotEmailController.text.trim();

                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your email.'),
                                    ),
                                  );

                                  return;
                                }

                                Navigator.pop(context);

                                if (!mounted) return;

                                try {
                                  final result =
                                      await AuthService.forgotPassword(
                                        email: email,
                                      );

                                  if (!mounted) return;

                                  Future.delayed(Duration.zero, () {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message']),
                                      ),
                                    );
                                  });
                                } catch (e) {
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },

                              child: const Text('Send'),
                            ),
                          ],
                        );
                      },
                    );
                  },

                  child: const Text(
                    'Forgot Password?',

                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Log In'),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(left: 100),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,

                  children: [
                    const Text("Don't have an account? "),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },

                      child: const Text(
                        'Sign Up',

                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
