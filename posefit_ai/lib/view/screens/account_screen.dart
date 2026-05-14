import 'dart:io';
import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/auth_service.dart';
import '../widgets/app_message_popup.dart';

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
                Navigator.of(context, rootNavigator: true).pop(false);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

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
      showAppMessagePopup(
        context: dialogContext,
        message: message,
        barrierDismissible: !forceChangePasswordActive,
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

                      if (!dialogContext.mounted) return;

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
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),

        leading: Icon(icon, color: AppColors.aiMint),

        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: AppColors.softText,
            fontWeight: FontWeight.w600,
          ),
        ),

        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.secondary),

        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Profile', style: AppTextStyles.heading),
              ),

              const SizedBox(height: 28),

              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 78,
                      backgroundColor: AppColors.card,
                      backgroundImage: profileImagePath != null
                          ? FileImage(File(profileImagePath!))
                          : null,
                      child: profileImagePath == null
                          ? const Icon(
                              Icons.person,
                              size: 68,
                              color: AppColors.aiMint,
                            )
                          : null,
                    ),
                  ),

                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(username, style: AppTextStyles.sectionTitle),

              const SizedBox(height: 6),

              Text(
                email,
                style: AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),

              const SizedBox(height: 34),

              _profileOptionTile(
                title: 'Change username',
                icon: Icons.person_outline,
                onTap: _showChangeUsernameDialog,
              ),

              _profileOptionTile(
                title: 'Change password',
                icon: Icons.lock_outline,
                onTap: _showChangePasswordDialog,
              ),

              _profileOptionTile(
                title: 'Settings',
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out', style: AppTextStyles.buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
