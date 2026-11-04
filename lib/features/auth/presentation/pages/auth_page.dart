
import 'package:flutter/material.dart';
import 'package:motora/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/auth_text_field.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const Color _background = Color(0xFF101114);
  static const Color _surface = Color(0xFF1E2024);
  static const Color _accent = Color(0xFFF8ED00);

  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        final response = await _authService.signUp(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response.session == null && mounted) {
          _showMessage(
            'Account created. Check your email to confirm your account.',
          );
        } else if (mounted) {
          _showMessage('Account created successfully.');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showMessage(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Something went wrong. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.redAccent : const Color(0xFF292C31),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.18),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: Colors.black,
            size: 40,
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'MOTORA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'DRIVE YOUR NEXT EXPERIENCE',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLogin ? 'Welcome Back' : 'Create Account',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _isLogin
              ? 'Sign in to continue your journey.'
              : 'Join MOTORA and discover your next car.',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            AuthTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: _nameController,
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 19),
          ],
          AuthTextField(
            label: 'Email Address',
            hint: 'example@email.com',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 19),
          AuthTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: _validatePassword,
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 19),
            AuthTextField(
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              controller: _confirmPasswordController,
              prefixIcon: Icons.lock_reset_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withValues(alpha: 0.5),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : Text(
                _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildSwitchMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin
              ? "Don't have an account?"
              : 'Already have an account?',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _formKey.currentState?.reset();
                  });
                },
          child: Text(
            _isLogin ? 'Create Account' : 'Sign In',
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 28,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildLogo()),
                  const SizedBox(height: 45),
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildForm(),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 14),
                  _buildSwitchMode(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
