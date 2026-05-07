import 'package:flutter/material.dart';
import '../../controller/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  final bool forceChangePassword;

  const AccountScreen({super.key, this.forceChangePassword = false});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String username = '';
  String email = '';
  String? profileImagePath;
  bool isLoading = true;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  late bool forceChangePasswordActive;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserData();

    forceChangePasswordActive = widget.forceChangePassword;

    if (forceChangePasswordActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showChangePasswordDialog();
      });
    }
  }

  Future<void> loadUserData() async {
    final loadedUsername = await AuthService.getUsername();
    final loadedEmail = await AuthService.getEmail();
    final userId = await AuthService.getUserId();
    final prefs = await SharedPreferences.getInstance();

    profileImagePath = prefs.getString('profileImagePath_$userId');

    if (!mounted) return;

    setState(() {
      username = loadedUsername ?? 'Unknown user';
      email = loadedEmail ?? 'No email';
      isLoading = false;
    });
  }

  Future<void> handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _showChangeUsernameDialog() async {
    final controller = TextEditingController(text: username);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change username'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New username'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = controller.text.trim();

                if (newUsername.isEmpty) return;

                final response = await AuthService.updateUsername(
                  username: newUsername,
                );

                if (!context.mounted) return;

                if (response['success'] == true) {
                  setState(() {
                    username = newUsername;
                  });

                  FocusManager.instance.primaryFocus?.unfocus();

                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage == null) return;

    final userId = await AuthService.getUserId();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('profileImagePath_$userId', pickedImage.path);

    setState(() {
      profileImagePath = pickedImage.path;
    });
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    void showDialogMessage(BuildContext dialogContext, String message) {
      showDialog(
        context: dialogContext,
        barrierDismissible: !forceChangePasswordActive,
        barrierColor: Colors.transparent,
        builder: (messageContext) {
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.canPop(messageContext)) {
              Navigator.pop(messageContext);
            }
          });

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          );
        },
      );
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: !forceChangePasswordActive,
              child: AlertDialog(
                title: const Text('Change password'),

                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: currentController,
                        obscureText: !_showCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Current password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showCurrentPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _showCurrentPassword = !_showCurrentPassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: newController,
                        obscureText: !_showNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _showNewPassword = !_showNewPassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                        ),
                      ),
                    ],
                  ),
                ),

                actions: [
                  if (!forceChangePasswordActive)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),

                  ElevatedButton(
                    onPressed: () async {
                      final currentPassword = currentController.text.trim();

                      final newPassword = newController.text.trim();

                      final confirmPassword = confirmController.text.trim();

                      if (newPassword.length < 8 ||
                          !RegExp(r'[A-Z]').hasMatch(newPassword) ||
                          !RegExp(r'[0-9]').hasMatch(newPassword) ||
                          !RegExp(r'[^A-Za-z0-9]').hasMatch(newPassword)) {
                        showDialogMessage(
                          context,
                          'Password must be at least 8 characters and include 1 capital letter, 1 number, and 1 symbol.',
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        showDialogMessage(context, 'Passwords do not match.');
                        return;
                      }

                      final response = await AuthService.changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                      );

                      if (response['success'] == true) {
                        Navigator.of(dialogContext, rootNavigator: true).pop();

                        if (!mounted) return;

                        setState(() {
                          forceChangePasswordActive = false;
                        });

                        showDialogMessage(
                          this.context,
                          'Password changed successfully.',
                        );
                      } else {
                        showDialogMessage(dialogContext, response['message']);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _profileOptionTile({
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profileImagePath != null
                        ? FileImage(File(profileImagePath!))
                        : null,
                    child: profileImagePath == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: const Icon(Icons.edit, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(email, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _profileOptionTile(
                title: 'Change username',
                onTap: _showChangeUsernameDialog,
              ),
              _profileOptionTile(
                title: 'Change password',
                onTap: _showChangePasswordDialog,
              ),
              _profileOptionTile(
                title: 'Settings',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleLogout,
                  child: const Text('Log Out'),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}
