import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/spacing_constants.dart';
import '../../widgets/glass_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Color(0xFF0F2027)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.m),
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(
                        'PROFILE SETTINGS',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Profile Section
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showEditProfile(context, ref, user),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                user?.username[0].toUpperCase() ?? '?',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(),
                      const SizedBox(height: Spacing.m),
                      Text(
                        user?.username ?? 'Loading...',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      if (user?.bio != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            user!.bio!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
                    children: [
                      _buildSettingsTile(context, Icons.notifications_active_outlined, 'Notifications', 'Enabled'),
                      _buildSettingsTile(context, Icons.location_on_outlined, 'Location Precision', 'High'),
                      _buildSettingsTile(context, Icons.security, 'Privacy Mode', 'Standard'),
                      
                      const SizedBox(height: 40),
                      
                      GlassButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).signOut();
                        },
                        text: 'LOGOUT',
                      ),
                      
                      const SizedBox(height: Spacing.m),
                      
                      TextButton(
                        onPressed: () => _confirmEmergencyReset(context, ref),
                        child: const Text('EMERGENCY RESET', style: TextStyle(color: AppColors.error, fontSize: 12, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.m),
      child: GlassCard(
        padding: const EdgeInsets.all(Spacing.m),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: Spacing.m),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    ).animate().fade().slideX(begin: 0.1);
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, dynamic user) {
    final nameController = TextEditingController(text: user?.username);
    final bioController = TextEditingController(text: user?.bio);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GlassCard(
          padding: const EdgeInsets.all(Spacing.l),
          borderRadius: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('EDIT PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: Spacing.l),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: Spacing.m),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio (optional)'),
                maxLength: 50,
              ),
              const SizedBox(height: Spacing.l),
              GlassButton(
                onPressed: () {
                  ref.read(firestoreServiceProvider).updateProfile(user!.uid, {
                    'username': nameController.text,
                    'bio': bioController.text,
                  });
                  Navigator.pop(context);
                },
                text: 'SAVE CHANGES',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmEmergencyReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('EMERGENCY RESET?'),
        content: const Text('This will sign you out and clear local cached states. Use if the app feels stuck.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.pop(context);
            },
            child: const Text('RESET', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
