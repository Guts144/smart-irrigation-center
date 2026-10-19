import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../core/config/app_config.dart';
import '../pro/data/sensor_models.dart';
import '../tracking/data/tracking_models.dart';

final stompServiceProvider = Provider<StompService>((ref) {
  final service = StompService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sensorStreamProvider = StreamProvider.autoDispose<SensorReading>((ref) {
  final stomp = ref.watch(stompServiceProvider);
  return stomp.sensorStream;
});

final connectionStatusStreamProvider = StreamProvider.autoDispose<bool>((ref) {
  final stomp = ref.watch(stompServiceProvider);
  return stomp.connectionStream;
});

class StompService {
  StompClient? _client;
  bool _isConnected = false;

  final _sensorController = StreamController<SensorReading>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _trackingControllers = <int, StreamController<TrackingInfoResponse>>{};

  Stream<SensorReading> get sensorStream => _sensorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  StompService() {
    _init();
  }

  void _init() {
    // AppConfig.wsUrl = ws://10.0.2.2:8081/ws/websocket
    final url = AppConfig.wsUrl.endsWith('/websocket') ? AppConfig.wsUrl : '${AppConfig.wsUrl}/websocket';

    _client = StompClient(
      config: StompConfig(
        url: url,
        onConnect: _onConnect,
        onWebSocketError: (error) {
          if (kDebugMode) print('WS Error: $error');
          _isConnected = false;
          _connectionController.add(false);
        },
        onDisconnect: (frame) {
          _isConnected = false;
          _connectionController.add(false);
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client?.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _connectionController.add(true);

    _client?.subscribe(
      destination: '/topic/sensors',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            _sensorController.add(SensorReading.fromJson(json));
          } catch (e) {
            if (kDebugMode) print('Error parsing sensor frame: $e');
          }
        }
      },
    );

    _client?.subscribe(
      destination: '/topic/connection',
      callback: (frame) {
        if (frame.body != null) {
          final isConnected = frame.body == 'true' || frame.body == '1';
          _connectionController.add(isConnected);
        }
      },
    );
  }

  Stream<TrackingInfoResponse> subscribeTracking(int sessionId) {
    if (!_trackingControllers.containsKey(sessionId)) {
      final controller = StreamController<TrackingInfoResponse>.broadcast();
      _trackingControllers[sessionId] = controller;

      _client?.subscribe(
        destination: '/topic/tracking/$sessionId',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              controller.add(TrackingInfoResponse.fromJson(json));
            } catch (e) {
              if (kDebugMode) print('Error parsing tracking frame: $e');
            }
          }
        },
      );
    }
    return _trackingControllers[sessionId]!.stream;
  }

  void dispose() {
    _client?.deactivate();
    _sensorController.close();
    _connectionController.close();
    for (final controller in _trackingControllers.values) {
      controller.close();
    }
  }
}
