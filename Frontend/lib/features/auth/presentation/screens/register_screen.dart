import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  // Validation State
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    setState(() {
      _isNameValid = value.length >= 2;
    });
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid =
          RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = value.length >= 6 &&
          value.contains(RegExp(r'[A-Z]')) &&
          value.contains(RegExp(r'[0-9]'));
    });
    _validateConfirmPassword(_confirmPasswordController.text);
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _isConfirmPasswordValid =
          value.isNotEmpty && value == _passwordController.text;
    });
  }

  Map<String, dynamic> get _passwordStrength {
    final password = _passwordController.text;
    if (password.isEmpty)
      return {'text': 'Слабый', 'color': AppColors.textTertiary, 'width': 0.25};

    int score = 0;
    if (password.length >= 6) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    if (score <= 1) {
      return {'text': 'Слабый', 'color': AppColors.error, 'width': 0.25};
    }
    if (score == 2) {
      return {'text': 'Средний', 'color': AppColors.warning, 'width': 0.5};
    }
    if (score == 3) {
      return {
        'text': 'Хороший',
        'color': AppColors.electricBlue,
        'width': 0.75
      };
    }
    return {'text': 'Надежный', 'color': AppColors.success, 'width': 1.0};
  }

  void _register() {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      ref.read(authProvider.notifier).register(
            _emailController.text,
            _passwordController.text,
            _nameController.text,
          );
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Примите условия использования'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    ref.listen(authProvider, (previous, next) {
      if (next is AsyncError) {
        String errorMessage = next.error.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceAll('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final bool isFormValid = _isNameValid &&
        _isEmailValid &&
        _isPasswordValid &&
        _isConfirmPasswordValid &&
        _acceptTerms;
    final strength = _passwordStrength;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Регистрация',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                      fontFamily: 'Inter'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Создайте новый аккаунт',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Имя',
                  placeholder: 'Ваше имя',
                  prefixIcon: Ionicons.person_outline,
                  iconColor: _isNameValid
                      ? AppColors.electricBlue
                      : (_nameController.text.isNotEmpty
                          ? AppColors.neonPink
                          : null),
                  suffixIcon: _isNameValid
                      ? const Icon(Ionicons.checkmark_circle,
                          color: AppColors.success)
                      : null,
                  borderColor: _nameController.text.isEmpty
                      ? null
                      : (_isNameValid ? AppColors.success : AppColors.neonPink),
                  onChanged: _validateName,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Введите имя' : null,
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  placeholder: 'example@mail.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Ionicons.mail_outline,
                  iconColor: _isEmailValid
                      ? AppColors.electricBlue
                      : (_emailController.text.isNotEmpty
                          ? AppColors.neonPink
                          : null),
                  suffixIcon: _isEmailValid
                      ? const Icon(Ionicons.checkmark_circle,
                          color: AppColors.success)
                      : null,
                  borderColor: _emailController.text.isEmpty
                      ? null
                      : (_isEmailValid
                          ? AppColors.success
                          : AppColors.neonPink),
                  onChanged: _validateEmail,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Введите email' : null,
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Пароль',
                  placeholder: 'Придумайте пароль',
                  obscureText: !_isPasswordVisible,
                  prefixIcon: Ionicons.lock_closed_outline,
                  iconColor: _isPasswordValid
                      ? AppColors.electricBlue
                      : (_passwordController.text.isNotEmpty
                          ? AppColors.neonPink
                          : null),
                  onChanged: _validatePassword,
                  borderColor: _passwordController.text.isEmpty
                      ? null
                      : (_isPasswordValid ? null : AppColors.neonPink),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Ionicons.eye_off_outline
                          : Ionicons.eye_outline,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Введите пароль' : null,
                ),

                // Password Strength Meter
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: AppColors.backgroundSecondary,
                                        borderRadius:
                                            BorderRadius.circular(2))),
                                FractionallySizedBox(
                                  widthFactor: strength['width'],
                                  child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                          color: strength['color'],
                                          borderRadius:
                                              BorderRadius.circular(2))),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Надежность: ${strength['text']}',
                              style: TextStyle(
                                  color: strength['color'], fontSize: 12),
                            )
                          ],
                        ),
                      )
                    ],
                  )
                ],
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Подтверждение пароля',
                  placeholder: 'Повторите пароль',
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: Ionicons.lock_closed_outline,
                  iconColor: _isConfirmPasswordValid
                      ? AppColors.electricBlue
                      : (_confirmPasswordController.text.isNotEmpty
                          ? AppColors.neonPink
                          : null),
                  onChanged: _validateConfirmPassword,
                  borderColor: _confirmPasswordController.text.isEmpty
                      ? null
                      : (_isConfirmPasswordValid
                          ? AppColors.success
                          : AppColors.neonPink),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Ionicons.eye_off_outline
                          : Ionicons.eye_outline,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () => setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Подтвердите пароль' : null,
                ),

                const SizedBox(height: 24),

                // Terms
                GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _acceptTerms
                              ? AppColors.electricBlue
                              : Colors.white,
                          border: Border.all(
                              color: _acceptTerms
                                  ? AppColors.electricBlue
                                  : AppColors.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _acceptTerms
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Wrap(
                          children: [
                            Text('Я принимаю ',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            Text('Условия использования',
                                style: TextStyle(
                                    color: AppColors.electricBlue,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                            Text(' и ',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            Text('Политикой конфиденциальности',
                                style: TextStyle(
                                    color: AppColors.electricBlue,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Создать аккаунт',
                  isLoading: isLoading,
                  onPressed: isFormValid ? _register : () {},
                  gradientColors: isFormValid
                      ? [AppColors.electricBlue, AppColors.electricBlue]
                      : [AppColors.border, AppColors.border],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Уже есть аккаунт? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.replace('/auth/login'),
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
