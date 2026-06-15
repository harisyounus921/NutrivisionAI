import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/widgets/log_option_card.dart';
import 'food_search_screen.dart';

class LogMealScreen extends StatelessWidget {
  const LogMealScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Meal')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How would you like to log this meal?',
                style: Theme.of(context).textTheme.titleMedium,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 20),
              LogOptionCard(
                icon: Icons.search,
                iconColor: colorScheme.primary,
                title: 'Search Food',
                subtitle: 'Find a food and log it manually',
                animationDelay: 50.ms,
                onTap: () {
                  Navigator.of(context).push(
                    AppPageRoute(builder: (_) => const FoodSearchScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              LogOptionCard(
                icon: Icons.qr_code_scanner,
                iconColor: colorScheme.tertiary,
                title: 'Scan Barcode',
                subtitle: 'Scan a packaged food barcode',
                animationDelay: 100.ms,
                onTap: () => _showComingSoon(context, 'Barcode scanning'),
              ),
              const SizedBox(height: 16),
              LogOptionCard(
                icon: Icons.camera_alt_outlined,
                iconColor: colorScheme.secondary,
                title: 'Take Photo',
                subtitle: 'Recognize food from a photo',
                animationDelay: 150.ms,
                onTap: () => _showComingSoon(context, 'Photo recognition'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
