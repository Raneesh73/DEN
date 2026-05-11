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
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'SETTINGS',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Profile Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.name[0].toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ).animate().scale(),
                      const SizedBox(height: Spacing.m),
                      Text(
                        user?.name ?? 'Loading...',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
                    children: [
                      _buildSettingsTile(Icons.notifications_active_outlined, 'Notifications', 'Enabled'),
                      _buildSettingsTile(Icons.location_on_outlined, 'Location Sharing', 'Live'),
                      _buildSettingsTile(Icons.security, 'Privacy & Security', 'Protected'),
                      const SizedBox(height: 40),
                      GlassButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).signOut();
                          Navigator.pop(context);
                        },
                        text: 'LOGOUT',
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

  Widget _buildSettingsTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.m),
      child: GlassCard(
        padding: const EdgeInsets.all(Spacing.m),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: Spacing.m),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    ).animate().fade().slideX(begin: 0.1);
  }
}
