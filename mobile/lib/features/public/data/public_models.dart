class DesktopAppInfo {
  final String name;
  final String syncInfo;
  final String platform;

  DesktopAppInfo({required this.name, required this.syncInfo, required this.platform});

  factory DesktopAppInfo.fromJson(Map<String, dynamic> json) {
    return DesktopAppInfo(
      name: json['name'] as String? ?? 'Desktop App',
      syncInfo: json['sync'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
    );
  }
}

class ProjectInfo {
  final String name;
  final String tagline;
  final String description;
  final List<String> features;
  final DesktopAppInfo? desktopApp;

  ProjectInfo({
    required this.name,
    required this.tagline,
    required this.description,
    required this.features,
    this.desktopApp,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      name: json['name'] as String? ?? 'AquaSense',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      desktopApp: json['desktopApp'] != null ? DesktopAppInfo.fromJson(json['desktopApp']) : null,
    );
  }
}

class Plan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String? interval;
  final List<String> features;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    this.interval,
    required this.features,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      interval: json['interval'] as String?,
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
