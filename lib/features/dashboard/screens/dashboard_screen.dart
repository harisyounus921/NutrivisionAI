import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../services/dashboard_service.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
              onPressed: () => context.read<DashboardProvider>().load(),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CaloriesCard(daily: provider.daily)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            _MacroBreakdownCard(daily: provider.daily)
                .animate()
                .fadeIn(delay: 100.ms, duration: 350.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
            _WeeklyTrendCard(range: provider.range, goalCalories: provider.daily?.calorieGoal)
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
  const _CaloriesCard({required this.daily});

  final DailyData? daily;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final consumed = daily?.calories ?? 0;
    final goal = daily?.calorieGoal;
    final burned = daily?.caloriesBurned ?? 0;
    final progress = (goal == null || goal == 0) ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
    final remaining = goal == null ? null : goal - consumed;
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
                      ? '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal '
                          '(${remaining.toStringAsFixed(0)} remaining)'
                      : '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal '
                          '(${(-remaining).toStringAsFixed(0)} over)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isOver ? colorScheme.error : colorScheme.onSurfaceVariant,
                    fontWeight: isOver ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
            if (burned > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Burned: ${burned.toStringAsFixed(0)} kcal  •  Net: ${(consumed - burned).toStringAsFixed(0)} kcal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroBreakdownCard extends StatelessWidget {
  const _MacroBreakdownCard({required this.daily});

  final DailyData? daily;

  @override
  Widget build(BuildContext context) {
    final protein = daily?.protein ?? 0;
    final carbs = daily?.carbs ?? 0;
    final fat = daily?.fat ?? 0;
    final proteinGoal = daily?.proteinGoal;
    final carbsGoal = daily?.carbsGoal;
    final fatGoal = daily?.fatGoal;

    final proteinCals = protein * 4;
    final carbsCals = carbs * 4;
    final fatCals = fat * 9;
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
              _MacroRow(color: AppTheme.proteinColor, label: 'Protein', value: protein, goal: proteinGoal),
              _MacroRow(color: AppTheme.carbsColor, label: 'Carbs', value: carbs, goal: carbsGoal),
              _MacroRow(color: AppTheme.fatColor, label: 'Fat', value: fat, goal: fatGoal),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.color, required this.label, required this.value, this.goal});

  final Color color;
  final String label;
  final double value;
  final double? goal;

  @override
  Widget build(BuildContext context) {
    final text = goal != null
        ? '${value.toStringAsFixed(1)} / ${goal!.toStringAsFixed(0)} g'
        : '${value.toStringAsFixed(1)} g';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.range, this.goalCalories});

  final List<RangeDayData> range;
  final double? goalCalories;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (range.isEmpty) {
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
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'No data yet — start logging meals!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    final maxCalories = range.fold<double>(0, (m, d) => d.calories > m ? d.calories : m);
    final maxY = [maxCalories, goalCalories ?? 0, 100.0].reduce((a, b) => a > b ? a : b) * 1.15;
    final today = DateTime.now();

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
                          final i = value.toInt();
                          if (i < 0 || i >= range.length) return const SizedBox.shrink();
                          final d = range[i].date;
                          final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              isToday ? 'Today' : _weekdayLabels[d.weekday - 1],
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
                  extraLinesData: goalCalories == null
                      ? null
                      : ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: goalCalories!,
                              color: AppTheme.accent,
                              strokeWidth: 2,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),
                  barGroups: [
                    for (var i = 0; i < range.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: range[i].calories,
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: range[i].date.day == today.day
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
            if (goalCalories != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 16, height: 2, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Daily goal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
