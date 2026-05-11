import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

import '../../controller/auth_service.dart';
import '../widgets/app_message_popup.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  static const int subjectMaxLength = 80;
  static const int messageMaxLength = 500;

  bool isSending = false;

  Future<void> sendMessage() async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      showAppMessagePopup(
        context: context,
        message: 'Subject and message are required.',
        isError: true,
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    final response = await AuthService.sendSupportMessage(
      subject: subject,
      message: message,
    );

    if (!mounted) return;

    setState(() {
      isSending = false;
    });

    showAppMessagePopup(
      context: context,
      message: response['message'] ?? 'Message sent.',
      isSuccess: response['success'] == true,
      isError: response['success'] != true,
    );

    if (response['success'] == true) {
      subjectController.clear();
      messageController.clear();
    }
  }

  Widget _supportTextField({
    required TextEditingController controller,
    required String hintText,
    required int maxLength,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: AppTextStyles.body,
      cursorColor: AppColors.primaryGreen,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.small,
        counterStyle: AppTextStyles.small,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.softText),
        title: const Text('Help & Support', style: AppTextStyles.sectionTitle),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Need help?', style: AppTextStyles.heading),

              const SizedBox(height: 8),

              const Text(
                'Send a message about any issue, feedback, or question related to PoseFit AI.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 28),

              const Text('Subject', style: AppTextStyles.cardTitle),

              const SizedBox(height: 8),

              _supportTextField(
                controller: subjectController,
                hintText: 'Subject',
                maxLength: subjectMaxLength,
                maxLines: 1,
              ),

              const SizedBox(height: 16),

              const Text('Message', style: AppTextStyles.cardTitle),

              const SizedBox(height: 8),

              _supportTextField(
                controller: messageController,
                hintText: 'Write your message...',
                maxLength: messageMaxLength,
                maxLines: 8,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: isSending ? null : sendMessage,
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isSending ? 'Sending...' : 'Send',
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
