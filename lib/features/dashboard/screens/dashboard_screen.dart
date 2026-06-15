import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../profile/providers/profile_provider.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final mealLogProvider = context.watch<MealLogProvider>();
    final goal = profile?.dailyCalorieGoal;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CaloriesCard(consumed: mealLogProvider.todayCalories, goal: goal)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            _MacroBreakdownCard(mealLogProvider: mealLogProvider)
                .animate()
                .fadeIn(delay: 100.ms, duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            _WeeklyTrendCard(mealLogProvider: mealLogProvider, goal: goal)
                .animate()
                .fadeIn(delay: 200.ms, duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.color, required this.title});

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.consumed, required this.goal});

  final double consumed;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (goal == null || goal == 0) ? 0.0 : (consumed / goal!).clamp(0.0, 1.0);
    final remaining = goal == null ? null : goal! - consumed;
    final isOver = remaining != null && remaining < 0;
    final barColor = isOver ? colorScheme.error : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHeader(
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.accent,
              title: "Today's Calories",
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goal == null
                  ? '${consumed.toStringAsFixed(0)} kcal consumed'
                  : remaining! >= 0
                      ? '${consumed.toStringAsFixed(0)} / $goal kcal '
                          '(${remaining.toStringAsFixed(0)} remaining)'
                      : '${consumed.toStringAsFixed(0)} / $goal kcal '
                          '(${(-remaining).toStringAsFixed(0)} over)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isOver ? colorScheme.error : colorScheme.onSurfaceVariant,
                    fontWeight: isOver ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBreakdownCard extends StatelessWidget {
  const _MacroBreakdownCard({required this.mealLogProvider});

  final MealLogProvider mealLogProvider;

  @override
  Widget build(BuildContext context) {
    final proteinCals = mealLogProvider.todayProtein * 4;
    final carbsCals = mealLogProvider.todayCarbs * 4;
    final fatCals = mealLogProvider.todayFat * 9;
    final total = proteinCals + carbsCals + fatCals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(
              icon: Icons.pie_chart_outline_rounded,
              color: AppTheme.seed,
              title: 'Macro Breakdown',
            ),
            const SizedBox(height: 12),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Log a meal to see your macro breakdown.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else ...[
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: [
                      PieChartSectionData(
                        value: proteinCals,
                        color: AppTheme.proteinColor,
                        title: '${(proteinCals / total * 100).toStringAsFixed(0)}%',
                        radius: 56,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      PieChartSectionData(
                        value: carbsCals,
                        color: AppTheme.carbsColor,
                        title: '${(carbsCals / total * 100).toStringAsFixed(0)}%',
                        radius: 56,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      PieChartSectionData(
                        value: fatCals,
                        color: AppTheme.fatColor,
                        title: '${(fatCals / total * 100).toStringAsFixed(0)}%',
                        radius: 56,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms).scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 12),
              _LegendRow(
                color: AppTheme.proteinColor,
                label: 'Protein',
                value: '${mealLogProvider.todayProtein.toStringAsFixed(1)} g',
              ),
              _LegendRow(
                color: AppTheme.carbsColor,
                label: 'Carbs',
                value: '${mealLogProvider.todayCarbs.toStringAsFixed(1)} g',
              ),
              _LegendRow(
                color: AppTheme.fatColor,
                label: 'Fat',
                value: '${mealLogProvider.todayFat.toStringAsFixed(1)} g',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.mealLogProvider, required this.goal});

  final MealLogProvider mealLogProvider;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final days = mealLogProvider.last7DaysCalories;
    final maxCalories = days.fold<double>(0, (max, day) => day.$2 > max ? day.$2 : max);
    final maxY = [maxCalories, (goal ?? 0).toDouble(), 100.0].reduce((a, b) => a > b ? a : b) * 1.15;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(
              icon: Icons.bar_chart_rounded,
              color: AppTheme.secondary,
              title: 'Last 7 Days',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) return const SizedBox.shrink();
                          final isToday = index == days.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              isToday ? 'Today' : _weekdayLabels[days[index].$1.weekday - 1],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                    color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: goal == null
                      ? null
                      : ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: goal!.toDouble(),
                              color: AppTheme.accent,
                              strokeWidth: 2,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: days[i].$2,
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: i == days.length - 1
                                  ? [AppTheme.secondary, AppTheme.seed]
                                  : [
                                      colorScheme.primary.withValues(alpha: 0.55),
                                      colorScheme.primary.withValues(alpha: 0.85),
                                    ],
                            ),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            if (goal != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 16, height: 2, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Daily goal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
