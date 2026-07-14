import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/navigation/post_auth_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.tryAutoLogin();

    final isAuthenticated = authProvider.status == AuthStatus.authenticated;
    if (isAuthenticated) {
      if (!mounted) return;
      await context.read<ProfileProvider>().loadProfile();

      if (!mounted) return;
      await context.read<MealLogProvider>().loadLogs();
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      AppPageRoute(
        builder: (context) => isAuthenticated
            ? postAuthDestination(context)
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.ink.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(
                  size: 76,
                  borderRadius: 22,
                ).animate().scale(duration: 560.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 22),
                Text(
                      'MealNudge',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 420.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 6),
                Text(
                      'AI meal guidance that stays out of your way.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 420.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 28),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ).animate().fadeIn(delay: 420.ms, duration: 360.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
