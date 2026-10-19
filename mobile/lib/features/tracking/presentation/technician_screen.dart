import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/tracking_models.dart';
import '../data/tracking_repository.dart';

class TechnicianScreen extends ConsumerStatefulWidget {
  const TechnicianScreen({super.key});

  @override
  ConsumerState<TechnicianScreen> createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends ConsumerState<TechnicianScreen> {
  final _customerIdController = TextEditingController();
  final _techNameController = TextEditingController();
  final _destLatController = TextEditingController(text: '36.8065');
  final _destLngController = TextEditingController(text: '10.1815');

  String? _activeToken;
  int? _activeSessionId;
  bool _isStarting = false;
  bool _isUpdating = false;

  @override
  void dispose() {
    _customerIdController.dispose();
    _techNameController.dispose();
    _destLatController.dispose();
    _destLngController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final customerId = int.tryParse(_customerIdController.text.trim());
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid Customer ID')));
      return;
    }

    setState(() => _isStarting = true);
    try {
      final req = StartTrackingRequest(
        customerId: customerId,
        technicianName: _techNameController.text.trim().isEmpty ? 'Tech John' : _techNameController.text.trim(),
        destinationLatitude: double.tryParse(_destLatController.text) ?? 36.8065,
        destinationLongitude: double.tryParse(_destLngController.text) ?? 10.1815,
      );
      final res = await ref.read(trackingRepositoryProvider).startTracking(req);
      if (mounted) {
        setState(() {
          _activeSessionId = res.sessionId;
          _activeToken = res.trackingToken;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session #${res.sessionId} started successfully!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _sendSampleLocation() async {
    if (_activeToken == null) return;
    setState(() => _isUpdating = true);
    try {
      final req = LocationUpdateRequest(
        trackingToken: _activeToken!,
        latitude: 36.8000 + (DateTime.now().second * 0.0001),
        longitude: 10.1800 + (DateTime.now().second * 0.0001),
        speed: 12.5, // ~45 km/h
        accuracy: 5.0,
      );
      await ref.read(trackingRepositoryProvider).sendLocationUpdate(req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location update transmitted!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _markArrived() async {
    if (_activeSessionId == null) return;
    try {
      await ref.read(trackingRepositoryProvider).markArrived(_activeSessionId!, token: _activeToken);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status marked as ARRIVED!')),
        );
        setState(() {
          _activeSessionId = null;
          _activeToken = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician GPS Dispatch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Technician Dispatch Mode',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a tracking session and transmit GPS location updates to the customer in real-time.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            if (_activeToken == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start New Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customerIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Customer User ID'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _techNameController,
                        decoration: const InputDecoration(labelText: 'Technician Name'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _destLatController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Dest Lat'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _destLngController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Dest Lng'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isStarting ? null : _startSession,
                          child: _isStarting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Start Dispatch Session'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Session #$_activeSessionId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      SelectableText('Token: $_activeToken', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUpdating ? null : _sendSampleLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Send GPS Fix'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: _markArrived,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Mark Arrived'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
