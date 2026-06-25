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

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profile = context.watch<ProfileProvider>().profile;
    final mealLogProvider = context.watch<MealLogProvider>();
    final todayLogs = mealLogProvider.todayLogs;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MealNudge',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Hi, ${user?.name.isNotEmpty == true ? user!.name : 'there'}',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      AppPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.08, end: 0),
            const SizedBox(height: 14),
            _TodayStrip(date: _formatToday())
                .animate()
                .fadeIn(delay: 50.ms, duration: 300.ms)
                .slideY(begin: 0.06, end: 0),
            if (profile != null) ...[
              const SizedBox(height: 14),
              _DailySnapshotCard(
                    consumed: mealLogProvider.todayCalories,
                    goal: profile.dailyCalorieGoal,
                    protein: mealLogProvider.todayProtein,
                    carbs: mealLogProvider.todayCarbs,
                    fat: mealLogProvider.todayFat,
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 380.ms)
                  .slideY(begin: 0.06, end: 0),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Text("Today's Meals", style: textTheme.titleMedium),
                const Spacer(),
                if (todayLogs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${todayLogs.length} logged',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
            const SizedBox(height: 8),
            if (todayLogs.isEmpty)
              _EmptyMealsCard().animate().fadeIn(
                delay: 220.ms,
                duration: 320.ms,
              )
            else
              ...todayLogs.asMap().entries.map(
                (entry) =>
                    _MealCard(
                          log: entry.value,
                          onDelete: () => context
                              .read<MealLogProvider>()
                              .removeLog(entry.value.id),
                        )
                        .animate()
                        .fadeIn(
                          delay: (180 + entry.key * 50).ms,
                          duration: 280.ms,
                        )
                        .slideX(begin: 0.04, end: 0),
              ),
            const SizedBox(height: 96),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
                heroTag: 'fab_log_meal',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(AppPageRoute(builder: (_) => const LogMealScreen()));
                },
                icon: const Icon(Icons.add),
                label: const Text('Log Meal'),
              )
              .animate()
              .fadeIn(delay: 260.ms, duration: 320.ms)
              .scale(
                begin: const Offset(0.88, 0.88),
                end: const Offset(1, 1),
                curve: Curves.easeOutCubic,
              ),
    );
  }
}

class _TodayStrip extends StatelessWidget {
  const _TodayStrip({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 17,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              date,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _DailySnapshotCard extends StatelessWidget {
  const _DailySnapshotCard({
    required this.consumed,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double consumed;
  final int goal;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ratio = goal == 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
    final remaining = (goal - consumed).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily balance',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          consumed.toStringAsFixed(0),
                          style: textTheme.displaySmall?.copyWith(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'kcal',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${remaining.toStringAsFixed(0)} left',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 11,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(AppTheme.seed),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroChip(
                  label: 'Protein',
                  value: '${protein.toStringAsFixed(0)}g',
                  color: AppTheme.proteinColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Carbs',
                  value: '${carbs.toStringAsFixed(0)}g',
                  color: AppTheme.carbsColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Fat',
                  value: '${fat.toStringAsFixed(0)}g',
                  color: AppTheme.fatColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
            Icon(
              Icons.restaurant_menu,
              size: 40,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text('No meals logged yet today', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Tap "Log Meal" to add your first entry.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
              child: Icon(
                Icons.restaurant,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.foodName,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${log.servings.toStringAsFixed(log.servings == log.servings.roundToDouble() ? 0 : 1)} '
                    '× ${log.servingDescription}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${log.calories.toStringAsFixed(0)} kcal',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
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
