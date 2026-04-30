import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
      appBar: AppBar(title: const Text('Camera settings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: const Text(
                'Camera consent',
                style: TextStyle(fontSize: 18),
              ),
              trailing: Text(
                cameraStatusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
              onTap: _openAppSettingsWithWarning,
            ),
          ),
        ),
      ),
    );
  }
}
