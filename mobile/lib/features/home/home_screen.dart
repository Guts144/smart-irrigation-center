import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../auth/application/auth_controller.dart';
import '../auth/data/user.dart';

/// Temporary landing screen after sign-in. The Pro tabs (dashboard, charts,
/// valve, tracking) replace this in the next phases of MOBILE_APP_TASKS.md.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).refreshUser();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to view your irrigation data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    if (state is! Authenticated) return const SizedBox.shrink();
    final user = state.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AquaSense'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome, ${user.fullName}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _AccountCard(user: user),
            const SizedBox(height: 16),
            _PlanCard(user: user),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(leading: const Icon(Icons.person), title: const Text('Name'), subtitle: Text(user.fullName)),
          ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(user.email)),
          ListTile(leading: const Icon(Icons.badge), title: const Text('Role'), subtitle: Text(user.role)),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final pro = user.hasProAccess;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              pro ? Icons.workspace_premium : Icons.lock_outline,
              color: pro ? AppColors.primary : AppColors.textMuted,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pro ? 'Pro access active' : 'Free plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pro
                        ? 'Live sensors, charts, valve control and tracking are unlocked.'
                        : 'Upgrade to Pro to unlock live sensor data and valve control.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text('Subscription: ${user.subscriptionStatus}')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
