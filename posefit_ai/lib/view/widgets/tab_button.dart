import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_sizes.dart';

class TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const TabButton({
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
          ),
        ),
      ),
    );
  }
}
