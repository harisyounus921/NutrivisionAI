class ActivityItem {
  const ActivityItem({
    required this.name,
    required this.durationDescription,
    required this.caloriesBurned,
    required this.steps,
  });

  final String name;
  final String durationDescription;
  final double caloriesBurned;
  final int steps;
}
