enum ActivitySource { manual, googleFit, appleHealth }

extension ActivitySourceLabel on ActivitySource {
  String get label => switch (this) {
        ActivitySource.manual => 'Manual',
        ActivitySource.googleFit => 'Google Fit',
        ActivitySource.appleHealth => 'Apple Health',
      };
}

/// A single logged activity entry, with totals already scaled by [sessions].
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.activityName,
    required this.caloriesBurned,
    required this.steps,
    required this.loggedAt,
    required this.source,
  });

  final String id;
  final String activityName;
  final double caloriesBurned;
  final int steps;
  final DateTime loggedAt;
  final ActivitySource source;

  Map<String, dynamic> toJson() => {
        'id': id,
        'activityName': activityName,
        'caloriesBurned': caloriesBurned,
        'steps': steps,
        'loggedAt': loggedAt.toIso8601String(),
        'source': source.name,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'] as String,
        activityName: json['activityName'] as String,
        caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
        steps: json['steps'] as int,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        source: ActivitySource.values.byName(json['source'] as String),
      );
}
