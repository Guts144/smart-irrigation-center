import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../data/public_models.dart';
import '../data/public_repository.dart';

final publicPricingProvider = FutureProvider<List<Plan>>((ref) {
  return ref.watch(publicRepositoryProvider).getPricing();
});

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _isLoadingCheckout = false;

  Future<void> _startCheckout(BuildContext context) async {
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) {
      context.push('/login');
      return;
    }

    setState(() => _isLoadingCheckout = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>('/api/subscription/checkout?platform=mobile');
      final checkoutUrl = response.data?['checkoutUrl'] as String?;
      if (checkoutUrl != null) {
        final url = Uri.parse(checkoutUrl);
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open checkout URL: $checkoutUrl')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricingAsync = ref.watch(publicPricingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing & Plans'),
      ),
      body: pricingAsync.when(
        data: (plans) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Simple, Transparent Pricing',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the plan that fits your irrigation needs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ...plans.map((plan) => _buildPlanCard(context, plan)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Failed to load plans: $err'),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan plan) {
    final isPro = plan.id.toLowerCase().contains('pro') || plan.price > 0;

    return Card(
      elevation: isPro ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPro ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPro ? AppColors.primaryDark : Colors.black,
                      ),
                ),
                if (isPro)
                  const Chip(
                    label: Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${plan.currency == "EUR" ? "€" : "\$"}${plan.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                if (plan.interval != null)
                  Text(
                    ' / ${plan.interval}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
              ],
            ),
            const Divider(height: 24),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: isPro
                  ? FilledButton(
                      onPressed: _isLoadingCheckout ? null : () => _startCheckout(context),
                      child: _isLoadingCheckout
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Upgrade to Pro'),
                    )
                  : OutlinedButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Get Started Free'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
