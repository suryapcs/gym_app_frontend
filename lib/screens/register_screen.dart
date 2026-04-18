import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      if (success) {
        // Auto-login after successful registration
        final loginSuccess = await _authService.login(email, password);
        if (!mounted) return;

        if (loginSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Successful! Welcome to vettri Gym.'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          // If auto login fails for some reason, at least go back to login screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Successful! Please login.'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JOIN VETTRI GYM')),
      body: Stack(
        children: [
          // Background pattern
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'START YOUR\nJOURNEY',
                      textAlign: TextAlign.left,
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill out the form below to create your account.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 48),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _register(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('CREATE ACCOUNT'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
