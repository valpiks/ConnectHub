import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/theme/app_theme.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onInfo;
  final String mode;

  const ActionButtons({
    super.key,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onInfo,
    this.mode = 'users',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Nope Button
        _buildCircleButton(
          onTap: onSwipeLeft,
          size: 70,
          colors: [const Color(0xFFFF3B30), const Color(0xFFFF9500)],
          icon: Ionicons.close,
          iconSize: 32,
        ),
        const SizedBox(width: 40),
        
        // Info Button
        _buildCircleButton(
          onTap: onInfo,
          size: 60,
          colors: [const Color(0xFF007AFF), const Color(0xFF5856D6)],
          icon: Ionicons.information_circle,
          iconSize: 24,
        ),
        const SizedBox(width: 40),

        // Like Button
        _buildCircleButton(
          onTap: onSwipeRight,
          size: 70,
          colors: mode == 'users' 
            ? [const Color(0xFF4CD964), const Color(0xFF2ECC71)]
            : [const Color(0xFFFFD700), const Color(0xFFFF9500)],
          icon: mode == 'users' ? Ionicons.heart : Ionicons.star,
          iconSize: 32,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onTap,
    required double size,
    required List<Color> colors,
    required IconData icon,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
         shape: BoxShape.circle,
         gradient: LinearGradient(
           colors: colors,
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.2),
             blurRadius: 12,
             offset: const Offset(0, 6),
           )
         ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}
