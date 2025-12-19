import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ModeSwitch extends StatelessWidget {
  final String mode; // 'users' or 'events'
  final Function(String) onModeChange;

  const ModeSwitch({
    super.key,
    required this.mode,
    required this.onModeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab(context, 'users', 'Люди'),
          _buildTab(context, 'events', 'Мероприятия'),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String tabMode, String label) {
    final isActive = mode == tabMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChange(tabMode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: isActive
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? Colors.black : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}
