import 'package:flutter/material.dart';

/// What kind of running total an [Achievement]'s [Achievement.target] is
/// measured against.
enum AchievementType { mealCount, activityCount, streak, goalHit }

/// A badge definition: unlocked once the user's progress for [type] reaches
/// [target].
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
