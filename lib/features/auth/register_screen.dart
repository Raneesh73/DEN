import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/spacing_constants.dart';
import '../../widgets/glass_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty || password.isEmpty || name.isEmpty) return;

    await ref.read(authControllerProvider.notifier).signUp(email, name, password);
    if (mounted && !ref.read(authControllerProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Color(0xFF1A1A2E)],
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CREATE\nACCOUNT',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 40,
                      height: 1.2,
                    ),
                  ).animate().fade().slideX(begin: -0.2),
                  const SizedBox(height: 40),
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: Spacing.m),
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
                          onPressed: _register,
                          text: 'GET STARTED',
                          isLoading: state.isLoading,
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
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
