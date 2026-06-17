import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/activity_log.dart';
import '../providers/activity_log_provider.dart';
import '../services/health_api_service.dart';
import '../services/health_device_service.dart';
import 'log_activity_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _healthApiService = HealthApiService();

  List<HealthSummaryDay> _serverSummary = [];
  bool _syncing = false;
  String? _syncResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogProvider>().loadLogs();
      _loadServerSummary();
    });
  }

  Future<void> _loadServerSummary() async {
    try {
      final summary = await _healthApiService.getSummary();
      if (mounted) setState(() => _serverSummary = summary);
    } catch (_) {}
  }

  Future<void> _syncHealthData() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncResult = null;
    });

    try {
      // 1. Request permissions
      final hasPerms = await HealthDeviceService.hasPermissions();
      if (!hasPerms) {
        final granted = await HealthDeviceService.requestPermissions();
        if (!granted) {
          if (!mounted) return;
          setState(() {
            _syncing = false;
            _syncResult = 'Permission denied. Please grant health access in Settings.';
          });
          return;
        }
      }

      // 2. Read today's device data
      final data = await HealthDeviceService.readToday();
      if (data == null) {
        if (!mounted) return;
        setState(() {
          _syncing = false;
          _syncResult = 'Could not read health data. Make sure the Health app has data for today.';
        });
        return;
      }

      // 3. Sync to backend
      await _healthApiService.syncHealthData(
        date: DateTime.now(),
        steps: data.steps,
        caloriesBurned: data.caloriesBurned,
        activeMinutes: data.activeMinutes,
      );

      // 4. Refresh server summary
      await _loadServerSummary();

      if (!mounted) return;
      setState(() {
        _syncing = false;
        _syncResult =
            'Synced: ${data.steps} steps · ${data.caloriesBurned.toStringAsFixed(0)} kcal';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _syncResult = 'Sync failed. Please try again.';
      });
    }
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
            if (_serverSummary.isNotEmpty) ...[
              _HealthSummaryCard(days: _serverSummary)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),
            ],
            _SyncCard(
              syncing: _syncing,
              syncResult: _syncResult,
              onSync: _syncHealthData,
            ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
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
        heroTag: 'fab_log_activity',
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
  const _SyncCard({required this.syncing, required this.syncResult, required this.onSync});

  final bool syncing;
  final String? syncResult;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = Platform.isIOS ? 'Sync with Apple Health' : 'Sync with Google Fit';
    final icon = Platform.isIOS ? Icons.favorite_border : Icons.fitness_center;

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
              'Import today\'s steps and calories burned directly from your device.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (syncResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: syncResult!.startsWith('Synced')
                      ? colorScheme.primaryContainer
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  syncResult!,
                  style: textTheme.bodySmall?.copyWith(
                    color: syncResult!.startsWith('Synced')
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon),
              label: Text(syncing ? 'Syncing…' : label),
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

class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({required this.days});

  final List<HealthSummaryDay> days;

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
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.insights_outlined, size: 18, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text('7-Day Health Summary', style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: days.map((d) {
                final hasData = d.caloriesBurned > 0 || d.steps > 0;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasData
                              ? colorScheme.secondaryContainer
                              : colorScheme.surfaceContainerHighest,
                        ),
                        child: hasData
                            ? Icon(Icons.check, size: 14, color: colorScheme.onSecondaryContainer)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dayLabel(d.date),
                        style: textTheme.bodySmall?.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HealthStat(
                  icon: Icons.local_fire_department_outlined,
                  color: AppTheme.accent,
                  label: 'Avg burned',
                  value: _avgBurned(),
                ),
                _HealthStat(
                  icon: Icons.directions_walk,
                  color: colorScheme.primary,
                  label: 'Avg steps',
                  value: _avgSteps(),
                ),
                _HealthStat(
                  icon: Icons.timer_outlined,
                  color: AppTheme.secondary,
                  label: 'Avg active',
                  value: _avgActive(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[d.weekday - 1];
  }

  String _avgBurned() {
    final active = days.where((d) => d.caloriesBurned > 0).toList();
    if (active.isEmpty) return '0 kcal';
    final avg = active.map((d) => d.caloriesBurned).reduce((a, b) => a + b) / active.length;
    return '${avg.toStringAsFixed(0)} kcal';
  }

  String _avgSteps() {
    final active = days.where((d) => d.steps > 0).toList();
    if (active.isEmpty) return '0';
    final avg = active.map((d) => d.steps).reduce((a, b) => a + b) / active.length;
    return avg.toStringAsFixed(0);
  }

  String _avgActive() {
    final active = days.where((d) => d.activeMinutes > 0).toList();
    if (active.isEmpty) return '0 min';
    final avg = active.map((d) => d.activeMinutes).reduce((a, b) => a + b) / active.length;
    return '${avg.toStringAsFixed(0)} min';
  }
}

class _HealthStat extends StatelessWidget {
  const _HealthStat({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
