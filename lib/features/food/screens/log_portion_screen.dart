import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/food_item.dart';
import '../models/meal_log.dart';
import '../providers/meal_log_provider.dart';

class LogPortionScreen extends StatefulWidget {
  const LogPortionScreen({super.key, required this.foodItem});

  final FoodItem foodItem;

  @override
  State<LogPortionScreen> createState() => _LogPortionScreenState();
}

class _LogPortionScreenState extends State<LogPortionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servingsController = TextEditingController(text: '1');

  double _servings = 1;

  @override
  void dispose() {
    _servingsController.dispose();
    super.dispose();
  }

  void _onServingsChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() => _servings = parsed);
    }
  }

  void _adjustServings(double delta) {
    final updated = (_servings + delta).clamp(0.5, 99.0);
    setState(() {
      _servings = updated;
      _servingsController.text = updated == updated.roundToDouble()
          ? updated.toStringAsFixed(0)
          : updated.toStringAsFixed(1);
    });
  }

  bool _isSaving = false;

  Future<void> _logMeal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final food = widget.foodItem;
    final log = MealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: food.name,
      servingDescription: food.servingDescription,
      servings: _servings,
      calories: food.calories * _servings,
      proteinG: food.proteinG * _servings,
      carbsG: food.carbsG * _servings,
      fatG: food.fatG * _servings,
      loggedAt: DateTime.now(),
      source: MealSource.manual,
    );

    try {
      await context.read<MealLogProvider>().addLog(log, foodItemId: food.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700),
      );
      setState(() => _isSaving = false);
      return;
    }

    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.foodItem;
    final totalCalories = food.calories * _servings;
    final totalProtein = food.proteinG * _servings;
    final totalCarbs = food.carbsG * _servings;
    final totalFat = food.fatG * _servings;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(food.name)),
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
                          'Per serving (${food.servingDescription})',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _NutritionRow(
                          icon: Icons.local_fire_department_outlined,
                          color: AppTheme.accent,
                          label: 'Calories',
                          value: '${food.calories.toStringAsFixed(0)} kcal',
                        ),
                        _NutritionRow(
                          icon: Icons.egg_outlined,
                          color: AppTheme.proteinColor,
                          label: 'Protein',
                          value: '${food.proteinG.toStringAsFixed(1)} g',
                        ),
                        _NutritionRow(
                          icon: Icons.rice_bowl_outlined,
                          color: AppTheme.carbsColor,
                          label: 'Carbs',
                          value: '${food.carbsG.toStringAsFixed(1)} g',
                        ),
                        _NutritionRow(
                          icon: Icons.water_drop_outlined,
                          color: AppTheme.fatColor,
                          label: 'Fat',
                          value: '${food.fatG.toStringAsFixed(1)} g',
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Servings', style: textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _adjustServings(-0.5),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: colorScheme.primary,
                    ),
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        controller: _servingsController,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _onServingsChanged,
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => _adjustServings(0.5),
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
                        '${totalCalories.toStringAsFixed(0)} kcal',
                        style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 4),
                      _TotalRow(label: 'Protein', value: '${totalProtein.toStringAsFixed(1)} g'),
                      _TotalRow(label: 'Carbs', value: '${totalCarbs.toStringAsFixed(1)} g'),
                      _TotalRow(label: 'Fat', value: '${totalFat.toStringAsFixed(1)} g'),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _logMeal,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Log Meal'),
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.label, required this.value, required this.icon, required this.color});

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
