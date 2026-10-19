import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../websocket/stomp_service.dart';
import '../data/pro_repository.dart';
import '../data/sensor_models.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  List<SensorReading> _readings = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _sensorSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _listenLive();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await ref.read(proRepositoryProvider).getSensors(page: 0, size: 50);
      if (mounted) {
        setState(() {
          // Newest first from API, reverse for line charts (oldest -> newest)
          _readings = page.content.reversed.toList();
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

  void _listenLive() {
    final stomp = ref.read(stompServiceProvider);
    _sensorSub = stomp.sensorStream.listen((newReading) {
      if (mounted) {
        setState(() {
          _readings.add(newReading);
          if (_readings.length > 50) _readings.removeAt(0);
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  void _exportCsv() {
    if (_readings.isEmpty) return;
    final csvBuf = StringBuffer();
    csvBuf.writeln('RecordedAt,Temperature,Humidity,SoilMoisture');
    for (final r in _readings) {
      csvBuf.writeln('${r.recordedAt.toIso8601String()},${r.temperature},${r.humidity},${r.soilMoisture}');
    }
    Share.share(csvBuf.toString(), subject: 'AquaSense_Sensor_Data.csv');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Charts & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export CSV',
            onPressed: _readings.isEmpty ? null : _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _readings.isEmpty
                  ? const Center(child: Text('No sensor data available.'))
                  : DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Analytics Chart', icon: Icon(Icons.show_chart)),
                              Tab(text: 'Readings History', icon: Icon(Icons.list)),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildChartView(),
                                _buildHistoryList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildChartView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChartCard(
          title: 'Soil Moisture (%)',
          color: AppColors.primary,
          spots: _readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.soilMoisture)).toList(),
          minY: 0,
          maxY: 100,
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Temperature (°C)',
          color: Colors.orange,
          spots: _readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList(),
          minY: -10,
          maxY: 60,
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Humidity (%)',
          color: Colors.blue,
          spots: _readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.humidity)).toList(),
          minY: 0,
          maxY: 100,
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    final reversedReadings = _readings.reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reversedReadings.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final r = reversedReadings[index];
        return ListTile(
          leading: const Icon(Icons.sensors, color: AppColors.primary),
          title: Text(
            'Moisture: ${r.soilMoisture.toStringAsFixed(1)}% | Temp: ${r.temperature.toStringAsFixed(1)}°C | Humidity: ${r.humidity.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text(r.recordedAt.toLocal().toString().split('.').first),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<FlSpot> spots;
  final double minY;
  final double maxY;

  const _ChartCard({
    required this.title,
    required this.color,
    required this.spots,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
