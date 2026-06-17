import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/health/services/health_device_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/coach/providers/chat_provider.dart';
import 'features/food/providers/meal_log_provider.dart';
import 'features/health/providers/activity_log_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/gamification/providers/gamification_provider.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await HealthDeviceService.configure();
  runApp(const NutrivisionApp());
}

class NutrivisionApp extends StatelessWidget {
  const NutrivisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MealLogProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ActivityLogProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nutrivision AI',
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
