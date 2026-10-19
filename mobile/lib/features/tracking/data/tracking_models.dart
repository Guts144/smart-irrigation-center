class TrackingInfoResponse {
  final int sessionId;
  final String technicianName;
  final String status;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? currentSpeed;
  final double? distanceRemaining;
  final DateTime? lastUpdate;
  final DateTime? estimatedArrival;

  TrackingInfoResponse({
    required this.sessionId,
    required this.technicianName,
    required this.status,
    this.currentLatitude,
    this.currentLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.currentSpeed,
    this.distanceRemaining,
    this.lastUpdate,
    this.estimatedArrival,
  });

  factory TrackingInfoResponse.fromJson(Map<String, dynamic> json) {
    return TrackingInfoResponse(
      sessionId: json['sessionId'] as int? ?? 0,
      technicianName: json['technicianName'] as String? ?? 'Technician',
      status: json['status'] as String? ?? 'ACTIVE',
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      destinationLatitude: (json['destinationLatitude'] as num?)?.toDouble(),
      destinationLongitude: (json['destinationLongitude'] as num?)?.toDouble(),
      currentSpeed: (json['currentSpeed'] as num?)?.toDouble(),
      distanceRemaining: (json['distanceRemaining'] as num?)?.toDouble(),
      lastUpdate: json['lastUpdate'] != null ? DateTime.parse(json['lastUpdate'] as String) : null,
      estimatedArrival:
          json['estimatedArrival'] != null ? DateTime.parse(json['estimatedArrival'] as String) : null,
    );
  }

  bool get isArrived => status == 'ARRIVED';
}

class StartTrackingRequest {
  final int customerId;
  final String technicianName;
  final double destinationLatitude;
  final double destinationLongitude;

  StartTrackingRequest({
    required this.customerId,
    required this.technicianName,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'technicianName': technicianName,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
      };
}

class StartTrackingResponse {
  final int sessionId;
  final String trackingToken;

  StartTrackingResponse({
    required this.sessionId,
    required this.trackingToken,
  });

  factory StartTrackingResponse.fromJson(Map<String, dynamic> json) {
    return StartTrackingResponse(
      sessionId: json['sessionId'] as int? ?? 0,
      trackingToken: json['trackingToken'] as String? ?? '',
    );
  }
}

class LocationUpdateRequest {
  final String trackingToken;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final DateTime? timestamp;

  LocationUpdateRequest({
    required this.trackingToken,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'trackingToken': trackingToken,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      };
}
