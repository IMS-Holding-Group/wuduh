class RadarSnapshot {
  final String city;
  final String neighborhood;
  final Map<String, dynamic> positionCenter;
  final double fogLevel;
  final double visibilityM;
  final double temperatureC;
  final double humidityPct;
  final double windKph;
  final List<Map<String, dynamic>> forecast;
  final List<Map<String, dynamic>> obstacles;
  final List<Map<String, dynamic>> vehicles;
  final int radarSnapshotId;
  final String timestamp;
  final Map<String, dynamic>? roadNetwork;

  RadarSnapshot({
    required this.city,
    required this.neighborhood,
    required this.positionCenter,
    required this.fogLevel,
    required this.visibilityM,
    required this.temperatureC,
    required this.humidityPct,
    required this.windKph,
    required this.forecast,
    required this.obstacles,
    required this.vehicles,
    required this.radarSnapshotId,
    required this.timestamp,
    this.roadNetwork,
  });

  factory RadarSnapshot.fromJson(Map<String, dynamic> json) {
    return RadarSnapshot(
      city: json['city'] ?? 'الباحة',
      neighborhood: json['neighborhood'] ?? 'شارع المطار',
      positionCenter: Map<String, dynamic>.from(json['position_center'] ?? {'lat': 20.0129, 'lon': 41.4677}),
      fogLevel: (json['fog_level'] ?? 0).toDouble(),
      visibilityM: (json['visibility_m'] ?? 200).toDouble(),
      temperatureC: (json['temperature_c'] ?? 25).toDouble(),
      humidityPct: (json['humidity_pct'] ?? 60).toDouble(),
      windKph: (json['wind_kph'] ?? 15).toDouble(),
      forecast: List<Map<String, dynamic>>.from(json['forecast'] ?? []),
      obstacles: List<Map<String, dynamic>>.from(json['obstacles'] ?? []),
      vehicles: List<Map<String, dynamic>>.from(json['vehicles'] ?? []),
      radarSnapshotId: json['radar_snapshot_id'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      roadNetwork: json['road_network'] != null ? Map<String, dynamic>.from(json['road_network']) : null,
    );
  }

  // للتوافق مع الكود القديم
  Map<String, dynamic> get location => {
    'city': city,
    'neighborhood': neighborhood,
    'latitude': positionCenter['lat'],
    'longitude': positionCenter['lon'],
  };

  int get fogLevelInt => fogLevel.round();
  int get visibility => visibilityM.round();
  List<Map<String, dynamic>> get nearbyVehicles => vehicles;

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'neighborhood': neighborhood,
      'position_center': positionCenter,
      'fog_level': fogLevel,
      'visibility_m': visibilityM,
      'temperature_c': temperatureC,
      'humidity_pct': humidityPct,
      'wind_kph': windKph,
      'forecast': forecast,
      'obstacles': obstacles,
      'vehicles': vehicles,
      'radar_snapshot_id': radarSnapshotId,
      'timestamp': timestamp,
      'road_network': roadNetwork,
    };
  }
}

