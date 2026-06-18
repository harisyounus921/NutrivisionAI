import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/home/screens/main_shell.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/profile/screens/profile_setup_screen.dart';

Widget postAuthDestination(BuildContext context) {
  final hasProfile = context.read<ProfileProvider>().hasProfile;
  return hasProfile ? const MainShell() : const ProfileSetupScreen();
}
