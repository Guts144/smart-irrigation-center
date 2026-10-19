import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/pro_repository.dart';

class ValveScreen extends ConsumerStatefulWidget {
  const ValveScreen({super.key});

  @override
  ConsumerState<ValveScreen> createState() => _ValveScreenState();
}

class _ValveScreenState extends ConsumerState<ValveScreen> {
  bool _isSending = false;
  bool _mqttConnected = true;
  String? _lastAction;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final conn = await ref.read(proRepositoryProvider).getConnectionStatus();
      if (mounted) {
        setState(() => _mqttConnected = conn.mqttConnected);
      }
    } catch (_) {}
  }

  Future<void> _sendAction(String action) async {
    if (action == 'OPEN') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Open Valve'),
          content: const Text('Are you sure you want to open the irrigation valve now?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Valve')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(proRepositoryProvider).sendValveCommand(action);
      if (mounted) {
        setState(() => _lastAction = action);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Valve $action command sent successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation Valve Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnection,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _lastAction == 'OPEN' ? Icons.water : Icons.water_drop_outlined,
              size: 100,
              color: _lastAction == 'OPEN' ? Colors.blue : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Remote Valve Control',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _mqttConnected
                  ? 'Send live commands directly to your ESP32 irrigation controller over MQTT.'
                  : 'MQTT Broker is offline. Remote valve control is currently disabled.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mqttConnected ? AppColors.textMuted : Colors.red,
                fontWeight: _mqttConnected ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            if (_lastAction != null) ...[
              const SizedBox(height: 16),
              Chip(
                avatar: Icon(
                  _lastAction == 'OPEN' ? Icons.check_circle : Icons.stop_circle,
                  color: Colors.white,
                ),
                label: Text(
                  'Last Command: $_lastAction',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _lastAction == 'OPEN' ? Colors.green : Colors.grey.shade700,
              ),
            ],
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: (_isSending || !_mqttConnected) ? null : () => _sendAction('OPEN'),
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text('OPEN VALVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: (_isSending || !_mqttConnected) ? null : () => _sendAction('CLOSE'),
                      icon: const Icon(Icons.stop, size: 28),
                      label: const Text('CLOSE VALVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            if (_isSending) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
