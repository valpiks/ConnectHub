import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF0056CC), Color(0xFF003A99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Decorative Circles
          Positioned(
            top: -150,
            right: -100,
            child: _buildCircle(300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildCircle(200),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: MediaQuery.of(context).size.width * 0.2,
            child: _buildCircle(150),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFE3F2FD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Ionicons.people, size: 52, color: Color(0xFF007AFF)),
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
                  
                  const SizedBox(height: 40),

                  // Texts
                  const Text(
                    'ConnectHub',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    'Соединяем профессионалов, создаем проекты, меняем мир вместе',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const Spacer(),

                  // Buttons
                  PrimaryButton(
                    text: 'Войти в аккаунт',
                    icon: Ionicons.log_in,
                    onPressed: () => context.go('/auth/login'),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  _buildSecondaryButton(
                    context,
                    text: 'Создать аккаунт',
                    icon: Ionicons.person_add,
                    onPressed: () => context.go('/auth/register'),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 40),

                  // Footer
                  const Text.rich(
                    TextSpan(
                      text: 'Нажимая продолжить, вы соглашаетесь с ',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                      children: [
                        TextSpan(
                          text: 'Условиями использования',
                          style: TextStyle(decoration: TextDecoration.underline, color: Colors.white),
                        ),
                        TextSpan(text: ' и '),
                        TextSpan(
                          text: 'Политикой конфиденциальности',
                          style: TextStyle(decoration: TextDecoration.underline, color: Colors.white),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 800.ms),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, {required String text, required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
