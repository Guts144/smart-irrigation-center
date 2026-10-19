import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../websocket/stomp_service.dart';
import '../data/pro_repository.dart';
import '../data/sensor_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  SensorReading? _latestReading;
  bool _mqttConnected = false;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _sensorSub;
  StreamSubscription? _connSub;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenWebSocket();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(proRepositoryProvider);
      final sensorPage = await repo.getSensors(page: 0, size: 1);
      final conn = await repo.getConnectionStatus();

      if (mounted) {
        setState(() {
          if (sensorPage.content.isNotEmpty) {
            _latestReading = sensorPage.content.first;
          }
          _mqttConnected = conn.mqttConnected;
          _isLoading = false;
        });
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

  void _listenWebSocket() {
    final stomp = ref.read(stompServiceProvider);
    _sensorSub = stomp.sensorStream.listen((reading) {
      if (mounted) {
        setState(() => _latestReading = reading);
      }
    });

    _connSub = stomp.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() => _mqttConnected = isConnected);
      }
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading dashboard: $_error'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadInitialData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final reading = _latestReading;
    final stomp = ref.watch(stompServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Badges Header
            Row(
              children: [
                _StatusBadge(
                  label: _mqttConnected ? 'IoT Online' : 'IoT Offline',
                  isOnline: _mqttConnected,
                  icon: Icons.sensors,
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: stomp.isConnected ? 'Live WS' : 'Disconnected',
                  isOnline: stomp.isConnected,
                  icon: Icons.wifi,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (reading == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No sensor data received yet.')),
                ),
              )
            else ...[
              _SensorTile(
                title: 'Soil Moisture',
                value: '${reading.soilMoisture.toStringAsFixed(1)}%',
                icon: Icons.water_drop,
                color: _getSoilColor(reading.soilMoisture),
                subtitle: 'Status: ${reading.soilMoistureStatus}',
              ),
              const SizedBox(height: 12),
              _SensorTile(
                title: 'Temperature',
                value: '${reading.temperature.toStringAsFixed(1)} °C',
                icon: Icons.thermostat,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _SensorTile(
                title: 'Humidity',
                value: '${reading.humidity.toStringAsFixed(1)}%',
                icon: Icons.cloud,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Last updated: ${reading.recordedAt.toLocal().toString().split('.').first}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSoilColor(double moisture) {
    if (moisture < 30) return Colors.red;
    if (moisture > 70) return Colors.blue;
    return AppColors.primary;
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isOnline;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.isOnline,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnline ? Colors.green : Colors.red),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isOnline ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOnline ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SensorTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
