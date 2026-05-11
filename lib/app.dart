import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/main_navigation_screen.dart';
import 'core/app_theme.dart';
import 'core/app_colors.dart';

class DenApp extends ConsumerWidget {
  const DenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userProfile = ref.watch(userProfileProvider);

    return MaterialApp(
      title: 'DEN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.premiumDarkTheme,
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginScreen();
          
          return userProfile.when(
            data: (profile) {
              if (profile == null) {
                return Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 24),
                        const Text('Setting up your profile...', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                          child: const Text('Sign Out (If stuck)', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (profile.activeDenId == null) {
                return const MainNavigationScreen(); // It will show dashboard, which might prompt to join a den
              }
              return const MainNavigationScreen();
            },
            loading: () => const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: Text('Profile Error:\n$e', style: TextStyle(color: AppColors.error))),
            ),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: Text('Auth Error:\n$e', style: TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }
}
