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
                        'YOUR CIRCLE',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ],
                  ).animate().fade().slideY(begin: -0.2),
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
                          onPressed: () => ref.read(denControllerProvider.notifier).createDen(_nameController.text),
                          text: 'CREATE CIRCLE',
                          isLoading: state.isLoading,
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 40),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.textSecondary, thickness: 0.2)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Spacing.m),
                        child: Text('OR', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: AppColors.textSecondary, thickness: 0.2)),
                    ],
                  ),
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
                          onPressed: () => ref.read(denControllerProvider.notifier).joinDen(_codeController.text),
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
                ],
              ),
            ),
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
