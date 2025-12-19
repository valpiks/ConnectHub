import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final List<Color>? gradientColors;
  final bool isSecondary;
  final bool isDanger; // Новый параметр для кнопки удаления/опасного действия

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.gradientColors,
    this.isSecondary = false,
    this.isDanger = false, // По умолчанию не опасная кнопка
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _getGradient(),
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: _getBorder(),
        // Убрали тень для более чистого вида
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: _getTextColor(),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: _getIconColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: _getTextColor(),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Вспомогательные методы для определения стилей

  Gradient? _getGradient() {
    if (isSecondary || isDanger) return null;
    return LinearGradient(
      colors:
          gradientColors ?? [AppColors.electricBlue, AppColors.electricBlue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color? _getBackgroundColor() {
    if (isSecondary) return Colors.transparent;
    if (isDanger) return AppColors.error; // Красный цвет для опасных действий

    // Для основной кнопки с градиентом
    return gradientColors == null ? AppColors.electricBlue : null;
  }

  Border? _getBorder() {
    if (isSecondary) {
      return Border.all(color: AppColors.border);
    }
    if (isDanger) {
      return Border.all(color: AppColors.error.withOpacity(0.3));
    }
    return null;
  }

  Color _getIconColor() {
    if (isDanger) return Colors.white;
    if (isSecondary) return AppColors.text;
    return Colors.white;
  }

  Color _getTextColor() {
    if (isDanger) return Colors.white;
    if (isSecondary) return AppColors.text;
    return Colors.white;
  }
}
