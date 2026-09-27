import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/auth_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.water_drop, size: 72, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'AquaSense',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primaryDarker,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 32),
                if (state is AuthRestoreFailed) ...[
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: controller.restore,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                  TextButton(onPressed: controller.logout, child: const Text('Sign in with another account')),
                ] else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
