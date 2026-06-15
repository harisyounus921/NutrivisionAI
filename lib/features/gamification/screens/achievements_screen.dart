import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../health/providers/activity_log_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../services/achievement_service.dart';

/// Achievements tab: streaks and badges based on logging activity (FR-14, UC-10).
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mealLogs = context.watch<MealLogProvider>().logs;
    final activityLogs = context.watch<ActivityLogProvider>().logs;
    final profile = context.watch<ProfileProvider>().profile;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final summary = AchievementService().evaluate(
      mealLogs: mealLogs,
      activityLogs: activityLogs,
      profile: profile,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakCard(currentStreak: summary.currentStreak, longestStreak: summary.longestStreak)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Badges', style: textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${summary.unlockedCount}/${summary.achievements.length}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
            const SizedBox(height: 8),
            ...summary.achievements.asMap().entries.map(
                  (entry) => _AchievementCard(progress: entry.value)
                      .animate()
                      .fadeIn(delay: (100 + entry.key * 50).ms, duration: 300.ms)
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
      child: const Icon(Icons.local_fire_department, color: Colors.white, size: 30),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, Color(0xFFFF8A50)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        children: [
          hasStreak
              ? flameIcon
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.12, duration: 900.ms, curve: Curves.easeInOut)
              : flameIcon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStreak == 0 ? 'No active streak' : '$currentStreak day${currentStreak == 1 ? '' : 's'} streak',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStreak == 0
                      ? 'Log a meal today to start a new streak.'
                      : 'Keep logging daily to extend your streak.',
                  style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
                if (longestStreak > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Longest streak: $longestStreak day${longestStreak == 1 ? '' : 's'}',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
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

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final achievement = progress.achievement;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = progress.isUnlocked;
    final ratio = (progress.progress / achievement.target).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: unlocked ? AppTheme.accent.withValues(alpha: 0.18) : colorScheme.surfaceContainerHighest,
              child: Icon(achievement.icon, color: unlocked ? AppTheme.accent : colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(unlocked ? AppTheme.accent : colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.progress} / ${achievement.target}',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (unlocked) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}
