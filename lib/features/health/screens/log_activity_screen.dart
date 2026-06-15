import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/widgets/log_option_card.dart';
import 'activity_search_screen.dart';

class LogActivityScreen extends StatelessWidget {
  const LogActivityScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon')),
    );
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
              LogOptionCard(
                icon: Icons.fitness_center,
                iconColor: colorScheme.tertiary,
                title: 'Sync with Google Fit',
                subtitle: 'Import steps and calories burned automatically',
                animationDelay: 100.ms,
                onTap: () => _showComingSoon(context, 'Google Fit sync'),
              ),
              const SizedBox(height: 16),
              LogOptionCard(
                icon: Icons.favorite_border,
                iconColor: colorScheme.secondary,
                title: 'Sync with Apple Health',
                subtitle: 'Import steps and calories burned automatically',
                animationDelay: 150.ms,
                onTap: () => _showComingSoon(context, 'Apple Health sync'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
