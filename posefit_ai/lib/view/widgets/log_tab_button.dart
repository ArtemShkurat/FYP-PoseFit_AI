import 'package:flutter/material.dart';
import 'package:posefit_ai/utils/app_colors.dart';
import 'package:posefit_ai/utils/app_sizes.dart';

class LogTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const LogTabButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.background : AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
