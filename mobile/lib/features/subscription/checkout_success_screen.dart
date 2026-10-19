import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/application/auth_controller.dart';

class CheckoutSuccessScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const CheckoutSuccessScreen({super.key, this.sessionId});

  @override
  ConsumerState<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends ConsumerState<CheckoutSuccessScreen> {
  bool _isVerifying = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _completeSubscription();
  }

  Future<void> _completeSubscription() async {
    final sessionId = widget.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      setState(() {
        _isVerifying = false;
        _error = 'Missing session ID in return URL.';
      });
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/subscription/complete', queryParameters: {'session_id': sessionId});
      await ref.read(authControllerProvider.notifier).refreshUser();

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = 'Failed to verify subscription with server: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Status'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _isVerifying
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verifying your payment with AquaSense...'),
                  ],
                )
              : _error != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 70, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Subscription Issue',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go('/home'),
                          child: const Text('Return to Home'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 80, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          '🎉 Subscription Activated!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Welcome to AquaSense Pro! Live sensor monitoring, charts, remote valve control, and technician tracking are now unlocked.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: () => context.go('/home'),
                          child: const Text('Go to Live Dashboard'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
