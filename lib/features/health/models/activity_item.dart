/// An activity and its estimated calorie burn/step count for one typical
/// session, used as a quick-add seed list until Google Fit/Apple Health
/// sync is wired up.
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
