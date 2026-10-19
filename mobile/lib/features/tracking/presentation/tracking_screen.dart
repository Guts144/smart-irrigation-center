import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../websocket/stomp_service.dart';
import '../data/tracking_models.dart';
import '../data/tracking_repository.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  TrackingInfoResponse? _trackingInfo;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _trackingSub;

  @override
  void initState() {
    super.initState();
    _loadActiveTracking();
  }

  Future<void> _loadActiveTracking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final info = await ref.read(trackingRepositoryProvider).getActiveSession();
      if (mounted) {
        setState(() {
          _trackingInfo = info;
          _isLoading = false;
        });
        if (info != null) {
          _subscribeLive(info.sessionId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeLive(int sessionId) {
    _trackingSub?.cancel();
    final stomp = ref.read(stompServiceProvider);
    _trackingSub = stomp.subscribeTracking(sessionId).listen((update) {
      if (mounted) {
        setState(() => _trackingInfo = update);
      }
    });
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Live Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveTracking,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActiveTracking,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                ),
              ),
            if (_trackingInfo == null) ...[
              const SizedBox(height: 40),
              const Icon(Icons.location_off, size: 80, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'No Active Technician Visit',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'When an AquaSense technician is dispatched to your location, live GPS tracking will appear here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ] else ...[
              _buildTrackingCard(context, _trackingInfo!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, TrackingInfoResponse info) {
    final isArrived = info.isArrived;
    final distanceKm = (info.distanceRemaining != null) ? (info.distanceRemaining! / 1000.0).toStringAsFixed(1) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: isArrived ? Colors.green.shade50 : AppColors.primaryDark,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Technician: ${info.technicianName}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isArrived ? Colors.green.shade900 : Colors.white,
                      ),
                    ),
                    Chip(
                      label: Text(
                        info.status,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: isArrived ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                if (isArrived) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '🎉 Technician has arrived at your location!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Live ETA & Distance Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      icon: Icons.alt_route,
                      title: 'Distance Left',
                      value: distanceKm != null ? '$distanceKm km' : '--',
                    ),
                    Container(height: 40, width: 1, color: Colors.grey.shade300),
                    _MetricColumn(
                      icon: Icons.timer,
                      title: 'Estimated Arrival',
                      value: info.estimatedArrival != null
                          ? '${info.estimatedArrival!.toLocal().hour.toString().padLeft(2, '0')}:${info.estimatedArrival!.toLocal().minute.toString().padLeft(2, '0')}'
                          : '--',
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      icon: Icons.speed,
                      title: 'Speed',
                      value: info.currentSpeed != null ? '${(info.currentSpeed! * 3.6).toStringAsFixed(0)} km/h' : '--',
                    ),
                    Container(height: 40, width: 1, color: Colors.grey.shade300),
                    _MetricColumn(
                      icon: Icons.update,
                      title: 'Last Location Fix',
                      value: info.lastUpdate != null
                          ? '${info.lastUpdate!.toLocal().hour.toString().padLeft(2, '0')}:${info.lastUpdate!.toLocal().minute.toString().padLeft(2, '0')}'
                          : '--',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricColumn({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
