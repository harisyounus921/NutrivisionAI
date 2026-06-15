import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/activity_item.dart';
import '../models/activity_log.dart';
import '../providers/activity_log_provider.dart';

class LogActivityPortionScreen extends StatefulWidget {
  const LogActivityPortionScreen({super.key, required this.activityItem});

  final ActivityItem activityItem;

  @override
  State<LogActivityPortionScreen> createState() => _LogActivityPortionScreenState();
}

class _LogActivityPortionScreenState extends State<LogActivityPortionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionsController = TextEditingController(text: '1');

  double _sessions = 1;

  @override
  void dispose() {
    _sessionsController.dispose();
    super.dispose();
  }

  void _onSessionsChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() => _sessions = parsed);
    }
  }

  void _adjustSessions(double delta) {
    final updated = (_sessions + delta).clamp(0.5, 99.0);
    setState(() {
      _sessions = updated;
      _sessionsController.text = updated == updated.roundToDouble()
          ? updated.toStringAsFixed(0)
          : updated.toStringAsFixed(1);
    });
  }

  void _logActivity() {
    if (!_formKey.currentState!.validate()) return;

    final activity = widget.activityItem;
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityName: activity.name,
      caloriesBurned: activity.caloriesBurned * _sessions,
      steps: (activity.steps * _sessions).round(),
      loggedAt: DateTime.now(),
      source: ActivitySource.manual,
    );

    context.read<ActivityLogProvider>().addLog(log);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activityItem;
    final totalCalories = activity.caloriesBurned * _sessions;
    final totalSteps = (activity.steps * _sessions).round();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(activity.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Per session (${activity.durationDescription})',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          icon: Icons.local_fire_department_outlined,
                          color: AppTheme.accent,
                          label: 'Calories burned',
                          value: '${activity.caloriesBurned.toStringAsFixed(0)} kcal',
                        ),
                        if (activity.steps > 0)
                          _StatRow(
                            icon: Icons.directions_walk,
                            color: AppTheme.secondary,
                            label: 'Steps',
                            value: '${activity.steps}',
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Sessions', style: textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _adjustSessions(-0.5),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: colorScheme.primary,
                    ),
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        controller: _sessionsController,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _onSessionsChanged,
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => _adjustSessions(0.5),
                      icon: const Icon(Icons.add_circle_outline),
                      color: colorScheme.primary,
                    ),
                  ],
                ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Total',
                        style: textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalCalories.toStringAsFixed(0)} kcal burned',
                        style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      if (totalSteps > 0) ...[
                        const SizedBox(height: 12),
                        Divider(color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 4),
                        _TotalRow(label: 'Steps', value: '$totalSteps'),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _logActivity,
                  child: const Text('Log Activity'),
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
