import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../coach/screens/coach_chat_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/screens/achievements_screen.dart';
import '../../health/providers/activity_log_provider.dart';
import '../../health/screens/health_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    HomeScreen(),
    DashboardScreen(),
    CoachChatScreen(),
    HealthScreen(),
    AchievementsScreen(),
  ];

  static const _items = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Stats',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    _NavItem(
      label: 'Coach',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome_rounded,
    ),
    _NavItem(
      label: 'Health',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    _NavItem(
      label: 'Awards',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: _MealNudgeNavBar(
        selectedIndex: _selectedIndex,
        items: _items,
        onSelected: _selectTab,
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    _refreshTabData(index);
  }

  void _refreshTabData(int index) {
    switch (index) {
      case 1:
        final dashboard = context.read<DashboardProvider>();
        if (!dashboard.isLoading) {
          dashboard.load();
        }
      case 3:
        final activityLog = context.read<ActivityLogProvider>();
        if (!activityLog.isLoading) {
          activityLog.loadLogs();
        }
        final dashboard = context.read<DashboardProvider>();
        if (!dashboard.isLoading) {
          dashboard.load();
        }
      case 4:
        final gamification = context.read<GamificationProvider>();
        if (!gamification.isLoading) {
          gamification.load();
        }
    }
  }
}

class _MealNudgeNavBar extends StatelessWidget {
  const _MealNudgeNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                flex: selectedIndex == index ? 2 : 1,
                child: _NavPill(
                  item: items[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.heroGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: selected ? 22 : 21,
                      color: selected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                    ClipRect(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        widthFactor: selected ? 1 : 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: selected ? 1 : 0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 7),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
