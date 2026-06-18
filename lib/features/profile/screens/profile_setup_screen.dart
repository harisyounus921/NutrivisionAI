import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/main_shell.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.existingProfile});

  final UserProfile? existingProfile;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _allergiesController;

  late Gender _gender;
  late ActivityLevel _activityLevel;
  late DietGoal _goal;
  late DietaryPreference _dietaryPreference;

  bool get _isEditing => widget.existingProfile != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProfile;
    _ageController = TextEditingController(text: existing?.age.toString() ?? '');
    _heightController = TextEditingController(text: existing?.heightCm.toString() ?? '');
    _weightController = TextEditingController(text: existing?.weightKg.toString() ?? '');
    _allergiesController = TextEditingController(text: existing?.allergies.join(', ') ?? '');
    _gender = existing?.gender ?? Gender.male;
    _activityLevel = existing?.activityLevel ?? ActivityLevel.moderate;
    _goal = existing?.goal ?? DietGoal.maintain;
    _dietaryPreference = existing?.dietaryPreference ?? DietaryPreference.none;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final allergies = _allergiesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final profile = UserProfile(
      age: int.parse(_ageController.text),
      gender: _gender,
      heightCm: double.parse(_heightController.text),
      weightKg: double.parse(_weightController.text),
      activityLevel: _activityLevel,
      goal: _goal,
      dietaryPreference: _dietaryPreference,
      allergies: allergies,
    );

    await context.read<ProfileProvider>().saveProfile(profile);

    if (!mounted) return;
    if (_isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Profile' : 'Set Up Your Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tell us about yourself so we can personalize your daily goals.',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 16),
                ],
                _SectionCard(
                  icon: Icons.person_outline,
                  title: 'About you',
                  children: [
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age (years)'),
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                        return null;
                      },
                    ),
                    DropdownButtonFormField<Gender>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: Gender.values
                          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender.label)))
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
                  ],
                ).animate().fadeIn(delay: 50.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.straighten,
                  title: 'Body metrics',
                  children: [
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                      validator: (value) {
                        final height = double.tryParse(value ?? '');
                        if (height == null || height < 50 || height > 250) return 'Enter a valid height';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      validator: (value) {
                        final weight = double.tryParse(value ?? '');
                        if (weight == null || weight < 20 || weight > 300) return 'Enter a valid weight';
                        return null;
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.flag_outlined,
                  title: 'Lifestyle & goals',
                  children: [
                    DropdownButtonFormField<ActivityLevel>(
                      isExpanded: true,
                      initialValue: _activityLevel,
                      decoration: const InputDecoration(labelText: 'Activity Level'),
                      items: ActivityLevel.values
                          .map((level) => DropdownMenuItem(value: level, child: Text(level.label, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) => setState(() => _activityLevel = value!),
                    ),
                    DropdownButtonFormField<DietGoal>(
                      isExpanded: true,
                      initialValue: _goal,
                      decoration: const InputDecoration(labelText: 'Goal'),
                      items: DietGoal.values
                          .map((goal) => DropdownMenuItem(value: goal, child: Text(goal.label, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) => setState(() => _goal = value!),
                    ),
                    DropdownButtonFormField<DietaryPreference>(
                      isExpanded: true,
                      initialValue: _dietaryPreference,
                      decoration: const InputDecoration(labelText: 'Dietary Preference'),
                      items: DietaryPreference.values
                          .map((pref) => DropdownMenuItem(value: pref, child: Text(pref.label, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) => setState(() => _dietaryPreference = value!),
                    ),
                    TextFormField(
                      controller: _allergiesController,
                      decoration: const InputDecoration(
                        labelText: 'Allergies / restrictions (comma-separated)',
                        hintText: 'e.g. peanuts, lactose',
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Continue'),
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(icon, size: 18, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
