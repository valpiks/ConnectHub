import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;

  // Validation State
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid =
          RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = value.length >= 6;
    });
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
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
        // Clean up error message if exception wrapper
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

    final bool isFormValid = _isEmailValid && _isPasswordValid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Вход в аккаунт',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Введите ваши данные для входа',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
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
                    validator: (value) => value?.isEmpty == true
                        ? 'Введите email'
                        : (_isEmailValid ? null : 'Некорректный email'),
                  ),

                  const SizedBox(height: 24),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Пароль',
                    placeholder: 'Введите пароль',
                    obscureText: !_isPasswordVisible,
                    prefixIcon: Ionicons.lock_closed_outline,
                    iconColor: _isPasswordValid
                        ? AppColors.electricBlue
                        : (_passwordController.text.isNotEmpty
                            ? AppColors.neonPink
                            : null),
                    borderColor: _passwordController.text.isEmpty
                        ? null
                        : (_isPasswordValid ? null : AppColors.neonPink),
                    onChanged: _validatePassword,
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
                  if (!_isPasswordValid && _passwordController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Минимум 6 символов',
                          style: TextStyle(
                              color: AppColors.neonPink, fontSize: 12)),
                    ),

                  const SizedBox(height: 40),

                  PrimaryButton(
                    text: 'Войти',
                    isLoading: isLoading,
                    onPressed: isFormValid ? _login : () {},
                    gradientColors: isFormValid
                        ? [AppColors.electricBlue, AppColors.electricBlue]
                        : [AppColors.border, AppColors.border],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Нет аккаунта? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.replace('/auth/register'),
                        child: const Text(
                          'Зарегистрироваться',
                          style: TextStyle(
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Нажимая «Войти», вы соглашаетесь с нашими ',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Условиями использования',
                        style: TextStyle(
                            color: AppColors.electricBlue, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        ' и ',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Политикой конфиденциальности',
                        style: TextStyle(
                            color: AppColors.electricBlue, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
