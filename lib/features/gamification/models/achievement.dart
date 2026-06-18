import 'package:flutter/material.dart';

enum AchievementType { mealCount, activityCount, streak, goalHit }

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementType type;
  final int target;
}
