import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/application/auth_controller.dart';
import '../pro/presentation/charts_screen.dart';
import '../pro/presentation/dashboard_screen.dart';
import '../pro/presentation/valve_screen.dart';
import '../tracking/presentation/tracking_screen.dart';
import 'home_screen.dart';

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen({super.key});

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int _currentIndex = 0;
  bool _initializedIndex = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isPro = user?.hasProAccess ?? false;

    if (!_initializedIndex) {
      _initializedIndex = true;
      if (!isPro) {
        _currentIndex = 4; // Default to Account tab for Free users
      }
    }

    Widget body;
    switch (_currentIndex) {
      case 0:
        body = isPro ? const DashboardScreen() : _buildUpgradeCTA('Live Sensor Dashboard');
        break;
      case 1:
        body = isPro ? const ChartsScreen() : _buildUpgradeCTA('Sensor Analytics & Charts');
        break;
      case 2:
        body = isPro ? const ValveScreen() : _buildUpgradeCTA('Remote Valve Control');
        break;
      case 3:
        body = isPro ? const TrackingScreen() : _buildUpgradeCTA('Technician Live Tracking');
        break;
      case 4:
      default:
        body = const HomeScreen();
        break;
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Charts'),
          BottomNavigationBarItem(icon: Icon(Icons.water), label: 'Valve'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Tracking'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildUpgradeCTA(String featureName) {
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Pro Subscription Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$featureName is exclusive to AquaSense Pro members. Upgrade your subscription to unlock real-time sensor monitoring, valve control, and live technician tracking.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/pricing'),
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to AquaSense Pro'),
            ),
          ],
        ),
      ),
    );
  }
}
