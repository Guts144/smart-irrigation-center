import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/public_models.dart';
import '../data/public_repository.dart';

final publicInfoProvider = FutureProvider<ProjectInfo>((ref) {
  return ref.watch(publicRepositoryProvider).getInfo();
});

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(publicInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AquaSense'),
        actions: [
          TextButton(
            onPressed: () => context.push('/pricing'),
            child: const Text('Pricing', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => context.push('/contact'),
            child: const Text('Contact', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Sign In',
            onPressed: () => context.push('/login'),
          ),
        ],
      ),
      body: infoAsync.when(
        data: (info) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.water_drop, size: 70, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              info.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              info.tagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  info.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Key Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...info.features.map(
              (f) => ListTile(
                leading: const Icon(Icons.check_circle, color: AppColors.primary),
                title: Text(f),
                dense: true,
              ),
            ),
            if (info.desktopApp != null) ...[
              const SizedBox(height: 20),
              Card(
                color: AppColors.surface,
                child: ListTile(
                  leading: const Icon(Icons.desktop_windows, color: AppColors.primaryDark),
                  title: Text(info.desktopApp!.name),
                  subtitle: Text('${info.desktopApp!.syncInfo}\nPlatform: ${info.desktopApp!.platform}'),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/contact'),
                    child: const Text('Contact Us'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/pricing'),
                    child: const Text('View Plans'),
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading info: $err'),
              ElevatedButton(
                onPressed: () => ref.invalidate(publicInfoProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
