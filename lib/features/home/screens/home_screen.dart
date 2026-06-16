import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../food/models/meal_log.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../food/screens/log_meal_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../../settings/screens/settings_screen.dart';

const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatToday() {
  final now = DateTime.now();
  return '${_weekdayNames[now.weekday - 1]}, ${now.day} ${_monthNames[now.month - 1]}';
}

/// Home tab: today's calorie/macro summary and meal log.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profile = context.watch<ProfileProvider>().profile;
    final mealLogProvider = context.watch<MealLogProvider>();
    final todayLogs = mealLogProvider.todayLogs;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${user?.name.isNotEmpty == true ? user!.name : 'there'}',
                              style: textTheme.headlineSmall?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatToday(),
                              style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white),
                          tooltip: 'Settings',
                          onPressed: () {
                            Navigator.of(context).push(
                              AppPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.1, end: 0),
                  if (profile != null) ...[
                    const SizedBox(height: 20),
                    _CalorieRing(
                      consumed: mealLogProvider.todayCalories,
                      goal: profile.dailyCalorieGoal,
                    ).animate().fadeIn(delay: 100.ms, duration: 450.ms).scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                        ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (profile != null)
                    Row(
                      children: [
                        Expanded(
                          child: _MacroCard(
                            icon: Icons.egg_outlined,
                            label: 'Protein',
                            value: '${mealLogProvider.todayProtein.toStringAsFixed(0)} g',
                            color: AppTheme.proteinColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MacroCard(
                            icon: Icons.rice_bowl_outlined,
                            label: 'Carbs',
                            value: '${mealLogProvider.todayCarbs.toStringAsFixed(0)} g',
                            color: AppTheme.carbsColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MacroCard(
                            icon: Icons.water_drop_outlined,
                            label: 'Fat',
                            value: '${mealLogProvider.todayFat.toStringAsFixed(0)} g',
                            color: AppTheme.fatColor,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text("Today's Meals", style: textTheme.titleMedium),
                      const Spacer(),
                      if (todayLogs.isNotEmpty)
                        Text(
                          '${todayLogs.length} logged',
                          style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
                  const SizedBox(height: 8),
                  if (todayLogs.isEmpty)
                    _EmptyMealsCard().animate().fadeIn(delay: 250.ms, duration: 350.ms)
                  else
                    ...todayLogs.asMap().entries.map(
                          (entry) => _MealCard(
                            log: entry.value,
                            onDelete: () => context.read<MealLogProvider>().removeLog(entry.value.id),
                          ).animate().fadeIn(delay: (200 + entry.key * 60).ms, duration: 300.ms).slideX(begin: 0.06, end: 0),
                        ),
                  const SizedBox(height: 72),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_log_meal',
        onPressed: () {
          Navigator.of(context).push(
            AppPageRoute(builder: (_) => const LogMealScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ).animate().fadeIn(delay: 300.ms, duration: 350.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.consumed, required this.goal});

  final double consumed;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final ratio = goal == 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
    final remaining = (goal - consumed).clamp(0, double.infinity);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: 168,
              height: 168,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                consumed.toStringAsFixed(0),
                style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              Text(
                'of $goal kcal',
                style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 4),
              Text(
                '${remaining.toStringAsFixed(0)} kcal left',
                style: textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _EmptyMealsCard extends StatelessWidget {
  const _EmptyMealsCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 40, color: colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No meals logged yet today', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Tap "Log Meal" to add your first entry.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.log, required this.onDelete});

  final MealLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(Icons.restaurant, color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.foodName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    '${log.servings.toStringAsFixed(log.servings == log.servings.roundToDouble() ? 0 : 1)} '
                    '× ${log.servingDescription}',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '${log.calories.toStringAsFixed(0)} kcal',
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
