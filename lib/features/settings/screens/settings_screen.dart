import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../coach/providers/chat_provider.dart';
import '../../food/providers/meal_log_provider.dart';
import '../../health/providers/activity_log_provider.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/profile_setup_screen.dart';
import '../providers/settings_provider.dart';
import '../services/data_management_service.dart';

/// Settings tab content (UC-11): account, notification preferences, and
/// data export/deletion (FR-15, UC-12).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsProvider>().loadSettings();
    });
  }

  void _showNotificationPermissionDialog() {
    final isAndroid = Platform.isAndroid;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifications blocked'),
        content: Text(
          isAndroid
              ? 'Notifications are disabled for Nutrivision AI.\n\n'
                  'To enable them:\n'
                  '1. Open Android Settings\n'
                  '2. Apps → Nutrivision AI\n'
                  '3. Notifications → Allow'
              : 'Notifications are disabled for Nutrivision AI.\n\n'
                  'To enable them:\n'
                  '1. Open iPhone Settings\n'
                  '2. Nutrivision → Notifications\n'
                  '3. Allow Notifications → On',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile() async {
    final profile = context.read<ProfileProvider>().profile;
    await Navigator.of(context).push(
      AppPageRoute(builder: (_) => ProfileSetupScreen(existingProfile: profile)),
    );
  }

  Future<void> _exportData() async {
    final data = await DataManagementService().exportAll();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export My Data'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(json)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This permanently erases your profile, meal logs, activity logs, '
          'and coach chat history from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DataManagementService().deleteAll();

    if (!mounted) return;
    await context.read<ProfileProvider>().clearProfile();

    if (!mounted) return;
    await context.read<MealLogProvider>().loadLogs();

    if (!mounted) return;
    await context.read<ActivityLogProvider>().loadLogs();

    if (!mounted) return;
    await context.read<ChatProvider>().loadMessages();

    if (!mounted) return;
    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profile = context.watch<ProfileProvider>().profile;
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : 'Account',
                          style: textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.06, end: 0),
            const SizedBox(height: 20),
            _SettingsSection(
              title: 'Profile',
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit profile'),
                  subtitle: Text(profile == null ? 'Set up your profile' : 'Goal: ${profile.goal.label}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editProfile,
                ),
              ],
            ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'Preferences',
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Daily meal reminders'),
                  subtitle: Text(
                    settings.mealRemindersEnabled
                        ? 'Reminders at 8:00 AM, 1:00 PM and 7:00 PM'
                        : 'Tap to enable breakfast, lunch & dinner reminders',
                  ),
                  value: settings.mealRemindersEnabled,
                  onChanged: (value) async {
                    try {
                      final applied = await context.read<SettingsProvider>().setMealRemindersEnabled(value);
                      if (!applied && value && mounted) {
                        _showNotificationPermissionDialog();
                      }
                    } catch (_) {
                      if (value && mounted) _showNotificationPermissionDialog();
                    }
                  },
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'Data',
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export my data'),
                  subtitle: const Text('View and copy your profile, logs, and chat history as JSON'),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                  title: Text('Delete all data', style: TextStyle(color: colorScheme.error)),
                  subtitle: const Text('Erase all locally stored data and log out'),
                  onTap: _deleteAllData,
                ),
              ],
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'Session',
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out'),
                  onTap: _logout,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Nutrivision AI v1.0.0',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[i],
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
