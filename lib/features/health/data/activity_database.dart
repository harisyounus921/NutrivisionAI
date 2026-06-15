import '../models/activity_item.dart';

/// Local seed activity database used for manual activity logging until
/// Google Fit/Apple Health sync is integrated.
const List<ActivityItem> activityDatabase = [
  ActivityItem(name: 'Walking', durationDescription: '30 min', caloriesBurned: 120, steps: 3000),
  ActivityItem(name: 'Running', durationDescription: '30 min', caloriesBurned: 300, steps: 4500),
  ActivityItem(name: 'Cycling', durationDescription: '30 min', caloriesBurned: 250, steps: 0),
  ActivityItem(name: 'Swimming', durationDescription: '30 min', caloriesBurned: 220, steps: 0),
  ActivityItem(name: 'Yoga', durationDescription: '30 min', caloriesBurned: 90, steps: 0),
  ActivityItem(name: 'Weight Training', durationDescription: '30 min', caloriesBurned: 130, steps: 0),
  ActivityItem(name: 'Hiking', durationDescription: '30 min', caloriesBurned: 200, steps: 3500),
  ActivityItem(name: 'Household Chores', durationDescription: '30 min', caloriesBurned: 100, steps: 1500),
];
