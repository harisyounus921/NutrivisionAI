import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/activity_log.dart';
import '../providers/activity_log_provider.dart';
import 'log_activity_screen.dart';

/// Health tab: net calorie balance (consumed vs. burned), today's steps,
/// activity log, and Google Fit/Apple Health sync entry points (FR-12, UC-09).
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogProvider>().loadLogs();
    });
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final mealLogProvider = context.watch<MealLogProvider>();
    final activityLogProvider = context.watch<ActivityLogProvider>();
    final todayLogs = activityLogProvider.todayLogs;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final consumed = mealLogProvider.todayCalories;
    final burned = activityLogProvider.todayCaloriesBurned;
    final net = consumed - burned;

    return Scaffold(
      appBar: AppBar(title: const Text('Health')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _NetCaloriesCard(consumed: consumed, burned: burned, net: net, goal: profile?.dailyCalorieGoal)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            _StepsCard(steps: activityLogProvider.todaySteps)
                .animate()
                .fadeIn(delay: 100.ms, duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            _SyncCard(
              onSyncGoogleFit: () => _showComingSoon(context, 'Google Fit sync'),
              onSyncAppleHealth: () => _showComingSoon(context, 'Apple Health sync'),
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 24),
            Row(
              children: [
                Text("Today's Activity", style: textTheme.titleMedium),
                const Spacer(),
                if (todayLogs.isNotEmpty)
                  Text(
                    '${todayLogs.length} logged',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ).animate().fadeIn(delay: 250.ms, duration: 350.ms),
            const SizedBox(height: 8),
            if (todayLogs.isEmpty)
              const _EmptyActivityCard().animate().fadeIn(delay: 300.ms, duration: 350.ms)
            else
              ...todayLogs.asMap().entries.map(
                    (entry) => _ActivityCard(
                      log: entry.value,
                      onDelete: () => context.read<ActivityLogProvider>().removeLog(entry.value.id),
                    ).animate().fadeIn(delay: (250 + entry.key * 60).ms, duration: 300.ms).slideX(begin: 0.06, end: 0),
                  ),
            const SizedBox(height: 72),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            AppPageRoute(builder: (_) => const LogActivityScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Activity'),
      ).animate().fadeIn(delay: 300.ms, duration: 350.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _NetCaloriesCard extends StatelessWidget {
  const _NetCaloriesCard({required this.consumed, required this.burned, required this.net, required this.goal});

  final double consumed;
  final double burned;
  final double net;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOver = goal != null && net > goal!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                  child: const Icon(Icons.balance, size: 18, color: AppTheme.secondary),
                ),
                const SizedBox(width: 12),
                Text('Net Calorie Balance', style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _StatRow(label: 'Consumed', value: '${consumed.toStringAsFixed(0)} kcal'),
            _StatRow(label: 'Burned', value: '-${burned.toStringAsFixed(0)} kcal'),
            const Divider(),
            _StatRow(
              label: 'Net intake',
              value: '${net.toStringAsFixed(0)} kcal',
              valueColor: isOver ? colorScheme.error : colorScheme.primary,
            ),
            if (goal != null) ...[
              const SizedBox(height: 4),
              Text(
                net <= goal!
                    ? '${(goal! - net).toStringAsFixed(0)} kcal under your $goal kcal goal'
                    : '${(net - goal!).toStringAsFixed(0)} kcal over your $goal kcal goal',
                style: textTheme.bodySmall?.copyWith(
                  color: isOver ? colorScheme.error : colorScheme.onSurfaceVariant,
                  fontWeight: isOver ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.steps});

  final int steps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.directions_walk, color: colorScheme.onPrimaryContainer, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Steps", style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '$steps',
                  style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.onSyncGoogleFit, required this.onSyncAppleHealth});

  final VoidCallback onSyncGoogleFit;
  final VoidCallback onSyncAppleHealth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.18),
                  child: const Icon(Icons.sync, size: 18, color: AppTheme.accent),
                ),
                const SizedBox(width: 12),
                Text('Sync Activity Data', style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Automatically import steps and calories burned from your phone.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSyncGoogleFit,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Sync with Google Fit'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onSyncAppleHealth,
              icon: const Icon(Icons.favorite_border),
              label: const Text('Sync with Apple Health'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.directions_run, size: 40, color: colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No activity logged yet today', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Tap "Log Activity" to add your first entry.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.log, required this.onDelete});

  final ActivityLog log;
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
              child: Icon(Icons.directions_run, color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.activityName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    log.steps > 0 ? '${log.steps} steps · ${log.source.label}' : log.source.label,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '-${log.caloriesBurned.toStringAsFixed(0)} kcal',
              style: textTheme.titleSmall?.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.w700),
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
