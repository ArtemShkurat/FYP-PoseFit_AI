import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_sizes.dart';
import '../../utils/app_text_styles.dart';

void showAppMessagePopup({
  required BuildContext context,
  required String message,
  bool barrierDismissible = true,
  bool isError = false,
  bool isSuccess = false,
}) {
  final Color accentColor = isSuccess
      ? AppColors.primaryGreen
      : isError
      ? Colors.redAccent
      : AppColors.aiMint;

  final IconData icon = isSuccess
      ? Icons.check_circle_outline
      : isError
      ? Icons.error_outline
      : Icons.info_outline;

  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.transparent,

    builder: (messageContext) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!messageContext.mounted) return;

        if (Navigator.canPop(messageContext)) {
          Navigator.pop(messageContext);
        }
      });

      return Center(
        child: Material(
          color: Colors.transparent,

          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),

            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),

            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.96),

              borderRadius: BorderRadius.circular(AppSizes.cardRadius),

              border: Border.all(
                color: accentColor.withValues(alpha: 0.45),
                width: 1.4,
              ),

              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accentColor, size: 24),

                const SizedBox(width: 12),

                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,

                    style: AppTextStyles.body.copyWith(
                      color: AppColors.softText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
