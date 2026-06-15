import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/navigation/app_page_route.dart';
import '../data/activity_database.dart';
import '../models/activity_item.dart';
import 'log_activity_portion_screen.dart';

class ActivitySearchScreen extends StatefulWidget {
  const ActivitySearchScreen({super.key});

  @override
  State<ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<ActivitySearchScreen> {
  final _searchController = TextEditingController();
  List<ActivityItem> _results = activityDatabase;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _results = normalized.isEmpty
          ? activityDatabase
          : activityDatabase
              .where((activity) => activity.name.toLowerCase().contains(normalized))
              .toList();
    });
  }

  void _selectActivity(ActivityItem activity) {
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => LogActivityPortionScreen(activityItem: activity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Activity')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search for an activity...',
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
                          Text('No activities found', style: textTheme.titleSmall),
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
                        final activity = _results[index];
                        return Card(
                          child: ListTile(
                            shape: const RoundedRectangleBorder(),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.secondaryContainer,
                              child: Icon(Icons.directions_run, color: colorScheme.onSecondaryContainer),
                            ),
                            title: Text(
                              activity.name,
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(activity.durationDescription),
                            trailing: Text(
                              '${activity.caloriesBurned.toStringAsFixed(0)} kcal',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () => _selectActivity(activity),
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
