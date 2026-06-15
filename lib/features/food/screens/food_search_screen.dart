import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/navigation/app_page_route.dart';
import '../data/food_database.dart';
import '../models/food_item.dart';
import 'log_portion_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();
  List<FoodItem> _results = foodDatabase;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _results = normalized.isEmpty
          ? foodDatabase
          : foodDatabase
              .where((food) => food.name.toLowerCase().contains(normalized))
              .toList();
    });
  }

  void _selectFood(FoodItem food) {
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => LogPortionScreen(foodItem: food)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Food')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search for a food...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.06, end: 0),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text('No foods found', style: textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search term.',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final food = _results[index];
                        return Card(
                          child: ListTile(
                            shape: const RoundedRectangleBorder(),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(Icons.restaurant, color: colorScheme.onPrimaryContainer),
                            ),
                            title: Text(
                              food.name,
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(food.servingDescription),
                            trailing: Text(
                              '${food.calories.toStringAsFixed(0)} kcal',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () => _selectFood(food),
                          ),
                        ).animate().fadeIn(delay: (index * 30).ms, duration: 250.ms).slideX(begin: 0.04, end: 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
