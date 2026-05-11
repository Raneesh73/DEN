import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/spacing_constants.dart';
import '../../widgets/glass_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    await ref.read(authControllerProvider.notifier).signIn(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Color(0xFF1A1A2E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Animated Background Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 4.seconds, curve: Curves.easeInOut)
             .blur(begin: const Offset(30, 30), end: const Offset(50, 50)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo & Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Spacing.m),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.location_on, size: 60, color: AppColors.primary),
                        ).animate().fade(duration: 800.ms).scale(delay: 200.ms),
                        const SizedBox(height: Spacing.m),
                        Text(
                          'DEN',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            letterSpacing: 8,
                            shadows: [
                              const Shadow(color: AppColors.primary, blurRadius: 10),
                            ],
                          ),
                        ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                        Text(
                          'PRIVATE CIRCLE',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            letterSpacing: 4,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                        ).animate().fade(delay: 600.ms),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Form
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: Spacing.m),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: Spacing.l),
                        GlassButton(
                          onPressed: _login,
                          text: 'LOGIN',
                          isLoading: state.isLoading,
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: Spacing.m),
                  
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: Text(
                      'CREATE AN ACCOUNT',
                      style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), letterSpacing: 2),
                    ),
                  ).animate().fade(delay: 1.seconds),
                  
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
}
