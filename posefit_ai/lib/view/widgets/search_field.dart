import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_sizes.dart';
import '../../utils/app_text_styles.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const SearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: AppTextStyles.body,
      cursorColor: AppColors.primaryGreen,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.cardSubtitle,
        prefixIcon: const Icon(Icons.search, color: AppColors.aiMint),
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
}
