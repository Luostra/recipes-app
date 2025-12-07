import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterPage({super.key, required this.onSwitchToLogin});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabaseClient = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  void _updateState({bool? loading, String? error}) {
    if (!mounted) return;
    setState(() {
      if (loading != null) _isLoading = loading;
      if (error != null) _errorText = error;
    });
  }

  Future<void> _signUpUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      _updateState(error: 'Необходимо принять условия использования');
      return;
    }

    _updateState(loading: true, error: null);

    try {
      final userEmail = _emailController.text.trim();
      final userPassword = _passwordController.text.trim();

      final registrationResponse = await supabaseClient.auth.signUp(
        email: userEmail,
        password: userPassword,
      );

      if (registrationResponse.user != null) {
        // Показываем сообщение об успешной регистрации
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Регистрация успешна! Проверьте вашу почту для подтверждения.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Переключаемся на страницу входа
          widget.onSwitchToLogin();
        }
      } else {
        _updateState(error: 'Ошибка регистрации');
      }
    } on AuthException catch (e) {
      _updateState(error: _getAuthErrorMessage(e.message));
    } catch (e) {
      _updateState(error: 'Произошла ошибка, попробуйте позже');
    } finally {
      if (mounted) _updateState(loading: false);
    }
  }

  String _getAuthErrorMessage(String message) {
    if (message.contains('User already registered')) {
      return 'Пользователь с таким email уже зарегистрирован';
    } else if (message.contains('Password should be at least')) {
      return 'Пароль должен быть не менее 6 символов';
    } else if (message.contains('Invalid email')) {
      return 'Неверный формат email';
    } else if (message.contains('Email rate limit exceeded')) {
      return 'Слишком много попыток. Попробуйте позже';
    }
    return message;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок
          Text(
            'Создание аккаунта',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Заполните форму для регистрации',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Поле email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Введите корректный email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Поле пароля
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: _togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите пароль';
              }
              if (value.length < 6) {
                return 'Пароль должен быть не менее 6 символов';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Подтверждение пароля
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Подтвердите пароль',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: _toggleConfirmPasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Подтвердите пароль';
              }
              if (value != _passwordController.text) {
                return 'Пароли не совпадают';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Соглашение с условиями
          Row(
            children: [
              Checkbox(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                activeColor: const Color(0xFF2196F3),
              ),
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      'Я принимаю ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Показать условия использования
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Условия использования'),
                            content: const SingleChildScrollView(
                              child: Text(
                                'Приложение RecipesApp позволяет хранить ваши кулинарные рецепты. '
                                'Вы можете создавать папки, добавлять рецепты с фотографиями и отмечать избранные рецепты. '
                                'Все данные хранятся на защищённых серверах и доступны только вам.\n\n'
                                'Используя приложение, вы соглашаетесь с политикой конфиденциальности.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Закрыть'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'условия использования',
                        style: TextStyle(
                          color: const Color(0xFF2196F3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Сообщение об ошибке
          if (_errorText != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromARGB(255, 255, 205, 210),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Кнопка регистрации
          ElevatedButton(
            onPressed: _isLoading ? null : _signUpUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Зарегистрироваться',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),

          const SizedBox(height: 24),

          // Разделитель
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('или', style: TextStyle(color: Colors.grey[500])),
              ),
              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
            ],
          ),

          const SizedBox(height: 24),

          // Ссылка на вход
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Уже есть аккаунт?',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.onSwitchToLogin,
                child: const Text(
                  'Войти',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Информация о подтверждении email
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(255, 187, 222, 251),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'После регистрации проверьте вашу почту для подтверждения email',
                    style: TextStyle(color: Colors.blue[800], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
