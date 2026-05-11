import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

class CameraSettingsScreen extends StatefulWidget {
  const CameraSettingsScreen({super.key});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen>
    with WidgetsBindingObserver {
  String cameraStatusText = 'Checking...';
  Color statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStatus();
    }
  }

  Future<void> _loadPermissionStatus() async {
    final status = await Permission.camera.status;

    if (!mounted) return;

    setState(() {
      if (status.isGranted) {
        cameraStatusText = 'Allowed';
        statusColor = Colors.blue;
      } else {
        cameraStatusText = 'Not allowed';
        statusColor = Colors.red;
      }
    });
  }

  Future<void> _openAppSettingsWithWarning() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Camera access'),
          content: const Text(
            'You will be redirected to system settings to change camera access.\n\n'
            'Note: The app may close after changing this setting. '
            'If it does, simply reopen the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.softText),
        title: const Text('Camera Settings', style: AppTextStyles.sectionTitle),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Permissions', style: AppTextStyles.heading),

              const SizedBox(height: 8),

              const Text(
                'Manage camera access used for exercise detection.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: AppSizes.sectionSpacing),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.aiMint,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Camera consent',
                            style: AppTextStyles.cardTitle,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Tap to manage access in device settings.',
                            style: AppTextStyles.small,
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: _openAppSettingsWithWarning,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSizes.buttonRadius,
                          ),
                        ),
                        child: Text(
                          cameraStatusText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
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
