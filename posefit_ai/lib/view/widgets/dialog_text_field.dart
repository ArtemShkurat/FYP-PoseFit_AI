import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_text_styles.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

class DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const DialogTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      style: AppTextStyles.body,
      cursorColor: AppColors.primaryGreen,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppTextStyles.small,
        hintText: hintText,
        hintStyle: AppTextStyles.small,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.aiMint),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
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
}
