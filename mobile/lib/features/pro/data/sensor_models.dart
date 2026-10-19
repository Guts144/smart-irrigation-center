class SensorReading {
  final LongId? id;
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final DateTime recordedAt;

  SensorReading({
    this.id,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.recordedAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'] != null ? LongId(json['id'].toString()) : null,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      soilMoisture: (json['soilMoisture'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id.toString(),
        'temperature': temperature,
        'humidity': humidity,
        'soilMoisture': soilMoisture,
        'recordedAt': recordedAt.toIso8601String(),
      };

  String get soilMoistureStatus {
    if (soilMoisture < 30) return 'Dry';
    if (soilMoisture > 70) return 'Wet';
    return 'Optimal';
  }
}

class LongId {
  final String value;
  LongId(this.value);
  @override
  String toString() => value;
}

class ConnectionStatus {
  final bool mqttConnected;

  ConnectionStatus({required this.mqttConnected});

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionStatus(
      mqttConnected: json['mqttConnected'] as bool? ?? false,
    );
  }
}

class SensorPage {
  final List<SensorReading> content;
  final int totalPages;
  final int totalElements;
  final int number;

  SensorPage({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
  });

  factory SensorPage.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List<dynamic>? ?? [];
    return SensorPage(
      content: list.map((e) => SensorReading.fromJson(e as Map<String, dynamic>)).toList(),
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? list.length,
      number: json['number'] as int? ?? 0,
    );
  }
}
