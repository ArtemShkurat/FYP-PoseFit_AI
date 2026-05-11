import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../controller/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final String appVersion = 'v1.0';

  Widget _settingsTile({
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),

        leading: icon == null ? null : Icon(icon, color: AppColors.aiMint),

        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: AppColors.softText,
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: AppTextStyles.small.copyWith(color: AppColors.secondary),
              ),

        trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),

        onTap: onTap,
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final result = await AuthService.deleteAccount();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Something went wrong.')),
    );

    if (result['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Settings', style: AppTextStyles.sectionTitle),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Preferences', style: AppTextStyles.sectionTitle),

              const SizedBox(height: 18),

              _settingsTile(
                title: 'Camera settings',
                subtitle: 'Permissions and camera access',
                icon: Icons.camera_alt_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/camera-settings');
                },
              ),

              _settingsTile(
                title: 'Notification settings',
                subtitle: 'Not implemented yet',
                icon: Icons.notifications_none,
              ),

              _settingsTile(
                title: 'Exercise History settings',
                subtitle: 'Not implemented yet',
                icon: Icons.history,
              ),

              _settingsTile(
                title: 'Help & Support',
                subtitle: 'FAQs and support',
                icon: Icons.help_outline,
                onTap: () {
                  Navigator.pushNamed(context, '/help-support');
                },
              ),

              const SizedBox(height: 34),

              const Text('System Info', style: AppTextStyles.sectionTitle),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),

                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.aiMint),

                        const SizedBox(width: 12),

                        Text(
                          'App version',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.softText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    Text(
                      appVersion,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),

                  onPressed: () => _handleDeleteAccount(context),

                  icon: const Icon(Icons.delete_outline),

                  label: const Text(
                    'Delete Account',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
