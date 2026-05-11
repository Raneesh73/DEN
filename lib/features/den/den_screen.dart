import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/den_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/spacing_constants.dart';
import '../../widgets/glass_widgets.dart';

class DenScreen extends ConsumerStatefulWidget {
  const DenScreen({super.key});

  @override
  ConsumerState<DenScreen> createState() => _DenScreenState();
}

class _DenScreenState extends ConsumerState<DenScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(denControllerProvider);
    final userDens = ref.watch(userDensProvider);
    final userProfile = ref.watch(userProfileProvider).value;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY CIRCLES',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Icon(Icons.group_work_outlined, color: AppColors.primary),
                    ],
                  ).animate().fade().slideY(begin: -0.2),
                  const SizedBox(height: Spacing.m),

                  // Active Dens List
                  userDens.when(
                    data: (dens) {
                      if (dens.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text('No circles joined yet.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        );
                      }
                      return Column(
                        children: dens.map((den) => _buildDenTile(den, userProfile)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),

                  const SizedBox(height: 40),
                  const Divider(color: AppColors.textSecondary, thickness: 0.2),
                  const SizedBox(height: 40),
                  
                  // Create Den Section
                  _buildSectionHeader('CREATE NEW'),
                  const SizedBox(height: Spacing.m),
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Circle Name',
                            prefixIcon: Icon(Icons.group_add_outlined),
                          ),
                        ),
                        const SizedBox(height: Spacing.m),
                        GlassButton(
                          onPressed: () {
                            ref.read(denControllerProvider.notifier).createDen(_nameController.text);
                            _nameController.clear();
                          },
                          text: 'CREATE CIRCLE',
                          isLoading: state.isLoading,
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 40),
                  
                  // Join Den Section
                  _buildSectionHeader('JOIN EXISTING'),
                  const SizedBox(height: Spacing.m),
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Invite Code',
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: Spacing.m),
                        GlassButton(
                          onPressed: () {
                            ref.read(denControllerProvider.notifier).joinDen(_codeController.text);
                            _codeController.clear();
                          },
                          text: 'JOIN CIRCLE',
                          isLoading: state.isLoading,
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 400.ms).slideX(begin: -0.1),
                  
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.m),
                      child: Text(
                        state.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ).animate().shake(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenTile(dynamic den, dynamic user) {
    final isActive = den.denId == user?.activeDenId;
    final isOwner = den.ownerId == user?.uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.m),
      child: GlassCard(
        padding: const EdgeInsets.all(Spacing.m),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isActive ? AppColors.primary : AppColors.textSecondary, width: 1),
              ),
              child: Icon(isActive ? Icons.check : Icons.group, color: isActive ? AppColors.primary : AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: Spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(den.denName, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? AppColors.primary : AppColors.textPrimary)),
                  Text('${den.members.length} members', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!isActive)
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
                onPressed: () => ref.read(denControllerProvider.notifier).switchDen(den.denId),
              ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
              itemBuilder: (context) => [
                if (isOwner)
                  const PopupMenuItem(value: 'delete', child: Text('Delete Circle', style: TextStyle(color: AppColors.error))),
                if (!isOwner)
                  const PopupMenuItem(value: 'leave', child: Text('Leave Circle')),
              ],
              onSelected: (val) {
                if (val == 'delete') _confirmDelete(den.denId);
                if (val == 'leave') _confirmLeave(den.denId);
              },
            ),
          ],
        ),
      ),
    ).animate().fade().slideX();
  }

  void _confirmDelete(String denId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('DELETE CIRCLE?'),
        content: const Text('This will permanently delete the circle for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(denControllerProvider.notifier).deleteDen(denId);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(String denId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('LEAVE CIRCLE?'),
        content: const Text('You will no longer be able to see members in this circle.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(denControllerProvider.notifier).leaveDen(denId);
              Navigator.pop(context);
            },
            child: const Text('LEAVE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.primary.withValues(alpha: 0.7),
        letterSpacing: 4,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
