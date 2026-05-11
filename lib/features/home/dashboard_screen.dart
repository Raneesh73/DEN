import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/spacing_constants.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/den_provider.dart';
import '../../providers/map_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final members = ref.watch(denMembersProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0E14), Color(0xFF1A1F25)],
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME BACK,',
                                  style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user?.username.toUpperCase() ?? 'USER',
                                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const CircleAvatar(
                              radius: 25,
                              backgroundColor: AppColors.surface,
                              child: Icon(Icons.person_outline, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fade().slideY(begin: -0.2),
                  ),
                ),

                // Quick SOS Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                    child: GlassCard(
                      padding: const EdgeInsets.all(Spacing.l),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 30),
                          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                          const SizedBox(width: Spacing.m),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EMERGENCY SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Tap to alert your Den immediately', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmSOS(context, ref),
                            icon: const Icon(Icons.arrow_forward_ios, color: AppColors.error),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 100.ms).scale(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: Spacing.l)),

                // Stats Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'ACTIVE DEN',
                            ref.watch(activeDenProvider).when(
                              data: (den) => den?.denName ?? 'NONE',
                              loading: () => '...',
                              error: (_, _) => 'ERROR',
                            ),
                            Icons.group,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: Spacing.m),
                        Expanded(
                          child: _buildStatCard(
                            'MEMBERS',
                            members.when(
                              data: (m) => m.length.toString(),
                              loading: () => '...',
                              error: (_, _) => '0',
                            ),
                            Icons.person_pin_circle,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: Spacing.l)),

                // Recent Activity
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RECENT ACTIVITY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: Spacing.m),
                        members.when(
                          data: (memberList) {
                            if (memberList.isEmpty) {
                              return const Center(child: Text('No activity yet', style: TextStyle(color: AppColors.textSecondary)));
                            }
                            return Column(
                              children: memberList.take(3).map((m) => _buildActivityTile(m)).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(Spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: Spacing.s),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildActivityTile(dynamic member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.s),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.m, vertical: Spacing.s),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.surface,
              child: Text(member.username[0].toUpperCase(), style: const TextStyle(fontSize: 10)),
            ),
            const SizedBox(width: Spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Active now', style: TextStyle(color: AppColors.success.withValues(alpha: 0.7), fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.circle, color: AppColors.success, size: 8),
          ],
        ),
      ),
    ).animate().fade().slideX();
  }

  void _confirmSOS(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('SEND SOS?'),
        content: const Text('This will alert everyone in your circle with your live location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(mapControllerProvider.notifier).sendSOS();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS Alert Sent!'), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('SEND ALERT'),
          ),
        ],
      ),
    );
  }
}
