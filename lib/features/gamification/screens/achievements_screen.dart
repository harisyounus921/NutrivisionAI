import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/gamification_provider.dart';
import '../services/gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GamificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GamificationProvider>();
    final streak = provider.streak;
    final badges = provider.badges;
    final weekly = provider.weeklySummary;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final earnedCount = badges.where((b) => b.earned).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<GamificationProvider>().load(),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakCard(
              currentStreak: streak?.current ?? 0,
              longestStreak: streak?.longest ?? 0,
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            if (weekly != null) ...[
              _WeeklyCard(weekly: weekly)
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Text('Badges', style: textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$earnedCount/${badges.length}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 120.ms, duration: 350.ms),
            const SizedBox(height: 8),
            if (badges.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Start logging meals to earn badges!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms),
            ...badges.asMap().entries.map(
              (e) => _BadgeCard(badge: e.value)
                  .animate()
                  .fadeIn(delay: (150 + e.key * 40).ms, duration: 300.ms)
                  .slideX(begin: 0.06, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.currentStreak, required this.longestStreak});

  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasStreak = currentStreak > 0;

    final flameIcon = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.local_fire_department,
        color: Colors.white,
        size: 30,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.secondary, AppTheme.accent],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        children: [
          hasStreak
              ? flameIcon
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      begin: 1.0,
                      end: 1.12,
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    )
              : flameIcon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStreak == 0
                      ? 'No active streak'
                      : '$currentStreak day${currentStreak == 1 ? '' : 's'} streak',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStreak == 0
                      ? 'Log a meal today to start a new streak.'
                      : 'Keep logging daily to extend your streak.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (longestStreak > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Longest streak: $longestStreak day${longestStreak == 1 ? '' : 's'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.weekly});

  final WeeklySummary weekly;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final days = weekly.days;
    final daysOnGoal = days.where((d) => d.withinGoal == true).length;
    final totalDays = days.where((d) => d.calories > 0).length;

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
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text('This Week', style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _WeekStat(label: 'Days logged', value: '$totalDays / 7'),
                const SizedBox(width: 16),
                _WeekStat(label: 'On goal', value: '$daysOnGoal / $totalDays'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: days.map((d) {
                final active = d.calories > 0;
                final onGoal = d.withinGoal == true;
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? (onGoal
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.4))
                            : colorScheme.surfaceContainerHighest,
                      ),
                      child: active
                          ? Icon(
                              onGoal ? Icons.check : Icons.circle,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dayLabel(d.date),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
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
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final BadgeData badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final earned = badge.earned;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: earned
                  ? AppTheme.accent.withValues(alpha: 0.18)
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                earned ? Icons.military_tech_rounded : Icons.lock_outline,
                color: earned ? AppTheme.accent : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (badge.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badge.description!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (badge.earnedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Earned ${_formatDate(badge.earnedAt!)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (earned) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppTheme.accent),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
