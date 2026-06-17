import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/widgets/log_option_card.dart';
import '../services/health_api_service.dart';
import '../services/health_device_service.dart';
import 'activity_search_screen.dart';

class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final _healthApiService = HealthApiService();
  bool _syncing = false;

  Future<void> _syncFromDevice() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    try {
      // Only request permissions if we haven't been granted before
      final alreadyGranted = await HealthDeviceService.wasPermissionGranted();
      if (!alreadyGranted) {
        if (!mounted) return;
        final granted = await HealthDeviceService.requestPermissions();
        if (!granted) {
          if (!mounted) return;
          setState(() => _syncing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health permission denied. Enable it in Settings.')),
          );
          return;
        }
      }

      final data = await HealthDeviceService.readToday();
      if (!mounted) return;
      if (data == null) {
        setState(() => _syncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read health data. Make sure the Health app has data.')),
        );
        return;
      }

      await _healthApiService.syncHealthData(
        date: DateTime.now(),
        steps: data.steps,
        caloriesBurned: data.caloriesBurned,
        activeMinutes: data.activeMinutes,
      );

      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced: ${data.steps} steps · ${data.caloriesBurned.toStringAsFixed(0)} kcal burned'),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Activity')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How would you like to log this activity?',
                style: Theme.of(context).textTheme.titleMedium,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 20),
              LogOptionCard(
                icon: Icons.directions_run,
                iconColor: colorScheme.primary,
                title: 'Choose Activity',
                subtitle: 'Pick an activity and log its duration',
                animationDelay: 50.ms,
                onTap: () {
                  Navigator.of(context).push(
                    AppPageRoute(builder: (_) => const ActivitySearchScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (Platform.isAndroid)
                LogOptionCard(
                  icon: _syncing ? Icons.hourglass_top : Icons.fitness_center,
                  iconColor: colorScheme.tertiary,
                  title: 'Sync with Google Fit',
                  subtitle: _syncing ? 'Syncing…' : 'Import today\'s steps and calories from Google Fit',
                  animationDelay: 100.ms,
                  onTap: _syncing ? () {} : _syncFromDevice,
                ),
              if (Platform.isIOS)
                LogOptionCard(
                  icon: _syncing ? Icons.hourglass_top : Icons.favorite_border,
                  iconColor: colorScheme.secondary,
                  title: 'Sync with Apple Health',
                  subtitle: _syncing ? 'Syncing…' : 'Import today\'s steps and calories from Apple Health',
                  animationDelay: 100.ms,
                  onTap: _syncing ? () {} : _syncFromDevice,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
