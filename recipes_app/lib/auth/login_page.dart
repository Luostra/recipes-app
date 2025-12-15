import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginPage({super.key, required this.onSwitchToRegister});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabaseClient = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  bool _obscurePassword = true;

  void _updateState({bool? loading, String? error}) {
    if (!mounted) return;
    setState(() {
      if (loading != null) _isLoading = loading;
      if (error != null) _errorText = error;
    });
  }

  Future<void> _signInUser() async {
    if (!_formKey.currentState!.validate()) return;

    _updateState(loading: true, error: null);

    try {
      final userEmail = _emailController.text.trim();
      final userPassword = _passwordController.text.trim();

      final authResponse = await supabaseClient.auth.signInWithPassword(
        email: userEmail,
        password: userPassword,
      );

      if (authResponse.user != null) {
        // Успешный вход - управление навигацией через AuthWrapper в app.dart
      } else {
        _updateState(error: 'Ошибка входа, проверьте e-mail и пароль');
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
    if (message.contains('Invalid login credentials')) {
      return 'Неверный email или пароль';
    } else if (message.contains('Email not confirmed')) {
      return 'Email не подтверждён. Проверьте вашу почту';
    } else if (message.contains('Invalid email')) {
      return 'Неверный формат email';
    }
    return message;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            'Вход в аккаунт',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Введите ваши данные для входа',
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
              labelStyle: TextStyle(color: Colors.grey[700]),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Color.fromARGB(255, 97, 97, 97),
              ),
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
              if (!value.contains('@')) {
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
              labelStyle: TextStyle(color: Colors.grey[700]),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color.fromARGB(255, 97, 97, 97),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Color.fromARGB(255, 97, 97, 97),
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

          const SizedBox(height: 8),

          // Забыли пароль
          /*
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Реализовать восстановление пароля
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Функция восстановления пароля в разработке'),
                  ),
                );
              },
              child: Text(
                'Забыли пароль?',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          */
          // Сообщение об ошибке
          if (_errorText != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromARGB(255, 255, 206, 211),
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

          // Кнопка входа
          ElevatedButton(
            onPressed: _isLoading ? null : _signInUser,
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
                    'Войти',
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

          // Ссылка на регистрацию
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Нет аккаунта?', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.onSwitchToRegister,
                child: const Text(
                  'Зарегистрироваться',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
