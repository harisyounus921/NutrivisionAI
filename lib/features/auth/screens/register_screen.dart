import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/navigation/post_auth_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

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

    try {
      await context.read<AuthProvider>().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!mounted) return;
    await context.read<ProfileProvider>().loadProfile();

    if (!mounted) return;
    await context.read<MealLogProvider>().loadLogs();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: postAuthDestination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 12),
                    Text(
                          'Create your account',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 6),
                    Text(
                          'Start tracking meals, activity, and progress',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Enter your name'
                                : null,
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 350.ms)
                          .slideX(begin: 0.08, end: 0),
                      const SizedBox(height: 16),
                      TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 350.ms)
                          .slideX(begin: 0.08, end: 0),
                      const SizedBox(height: 16),
                      TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 350.ms)
                          .slideX(begin: 0.08, end: 0),
                      const SizedBox(height: 16),
                      TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 350.ms)
                          .slideX(begin: 0.08, end: 0),
                      const SizedBox(height: 28),
                      FilledButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Create Account'),
                          )
                          .animate()
                          .fadeIn(delay: 325.ms, duration: 350.ms)
                          .slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
