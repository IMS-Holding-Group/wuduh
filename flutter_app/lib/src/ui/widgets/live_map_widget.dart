import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/radar_snapshot.dart';
import '../../../themes/app_theme.dart';

class LiveMapWidget extends StatefulWidget {
  final RadarSnapshot snapshot;
  final List<Map<String, dynamic>>? routeWaypoints;
  final bool isLowAngle;

  const LiveMapWidget({
    super.key,
    required this.snapshot,
    this.routeWaypoints,
    this.isLowAngle = true,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  late AnimationController _fogController;
  Timer? _updateTimer;
  double _cameraTilt = 45.0; // زاوية منخفضة للخريطة
  double _cameraBearing = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Animation controller للنقاط النبضية
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Animation controller للضباب
    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    // تحديثات تلقائية كل ثانية
    _startAutoUpdate();
  }

  void _startAutoUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // تحديث الخريطة
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fogController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateCameraPosition();
  }

  void _updateCameraPosition() {
    if (_mapController == null) return;
    
    final centerLat = widget.snapshot.positionCenter['lat']?.toDouble() ?? 20.0129;
    final centerLon = widget.snapshot.positionCenter['lon']?.toDouble() ?? 41.4677;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(centerLat, centerLon),
          zoom: 15.0,
          tilt: widget.isLowAngle ? _cameraTilt : 0.0,
          bearing: _cameraBearing,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final centerLat = widget.snapshot.positionCenter['lat']?.toDouble() ?? 20.0129;
    final centerLon = widget.snapshot.positionCenter['lon']?.toDouble() ?? 41.4677;
    
    final markers = <Marker>{};
    
    // موقع المستخدم
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(centerLat, centerLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.5),
      ),
    );
    
    // العوائق كنقاط نبضية
    for (int i = 0; i < widget.snapshot.obstacles.length; i++) {
      final obstacle = widget.snapshot.obstacles[i];
      final lat = obstacle['lat']?.toDouble() ?? centerLat;
      final lon = obstacle['lon']?.toDouble() ?? centerLon;
      final severity = obstacle['severity'] ?? 'medium';
      
      double hue = BitmapDescriptor.hueYellow;
      if (severity == 'high') hue = BitmapDescriptor.hueRed;
      if (severity == 'low') hue = BitmapDescriptor.hueBlue;
      
      markers.add(
        Marker(
          markerId: MarkerId('obstacle_$i'),
          position: LatLng(lat, lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    
    // المركبات كنقاط نبضية
    for (int i = 0; i < widget.snapshot.vehicles.length; i++) {
      final vehicle = widget.snapshot.vehicles[i];
      final lat = vehicle['lat']?.toDouble() ?? centerLat;
      final lon = vehicle['lon']?.toDouble() ?? centerLon;
      
      markers.add(
        Marker(
          markerId: MarkerId('vehicle_$i'),
          position: LatLng(lat, lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          anchor: const Offset(0.5, 0.5),
          rotation: vehicle['heading']?.toDouble() ?? 0.0,
        ),
      );
    }
    
    return markers;
  }

  Set<Circle> _buildPulsatingCircles() {
    final centerLat = widget.snapshot.positionCenter['lat']?.toDouble() ?? 20.0129;
    final centerLon = widget.snapshot.positionCenter['lon']?.toDouble() ?? 41.4677;
    
    final circles = <Circle>{};
    final pulseValue = _pulseController.value;
    final baseRadius = 20.0;
    final pulseRadius = baseRadius + (pulseValue * 15.0);
    
    // دوائر نبضية للعوائق
    for (int i = 0; i < widget.snapshot.obstacles.length; i++) {
      final obstacle = widget.snapshot.obstacles[i];
      final lat = obstacle['lat']?.toDouble() ?? centerLat;
      final lon = obstacle['lon']?.toDouble() ?? centerLon;
      final severity = obstacle['severity'] ?? 'medium';
      
      Color circleColor = AppTheme.warningYellow;
      if (severity == 'high') circleColor = AppTheme.emergencyRed;
      if (severity == 'low') circleColor = AppTheme.foggyBlue;
      
      circles.add(
        Circle(
          circleId: CircleId('obstacle_pulse_$i'),
          center: LatLng(lat, lon),
          radius: pulseRadius,
          fillColor: circleColor.withOpacity(0.2 * (1 - pulseValue)),
          strokeColor: circleColor.withOpacity(0.8),
          strokeWidth: 2,
        ),
      );
    }
    
    // دوائر نبضية للمركبات
    for (int i = 0; i < widget.snapshot.vehicles.length; i++) {
      final vehicle = widget.snapshot.vehicles[i];
      final lat = vehicle['lat']?.toDouble() ?? centerLat;
      final lon = vehicle['lon']?.toDouble() ?? centerLon;
      
      circles.add(
        Circle(
          circleId: CircleId('vehicle_pulse_$i'),
          center: LatLng(lat, lon),
          radius: pulseRadius * 0.7,
          fillColor: AppTheme.radarTurquoise.withOpacity(0.15 * (1 - pulseValue)),
          strokeColor: AppTheme.radarTurquoise.withOpacity(0.6),
          strokeWidth: 2,
        ),
      );
    }
    
    return circles;
  }

  Set<Polyline> _buildRoutePolylines() {
    final polylines = <Polyline>{};
    
    if (widget.routeWaypoints != null && widget.routeWaypoints!.isNotEmpty) {
      final routePoints = widget.routeWaypoints!.map<LatLng>((wp) {
        return LatLng(
          wp['lat']?.toDouble() ?? 20.0129,
          wp['lon']?.toDouble() ?? 41.4677,
        );
      }).toList();
      
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: AppTheme.radarTurquoise,
          width: 6,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }
    
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final centerLat = widget.snapshot.positionCenter['lat']?.toDouble() ?? 20.0129;
    final centerLon = widget.snapshot.positionCenter['lon']?.toDouble() ?? 41.4677;
    final fogLevel = widget.snapshot.fogLevel / 100.0;
    final fogOpacity = (fogLevel * 0.7).clamp(0.0, 0.7);
    
    // تأثير الضباب المتغير
    final animatedFogOpacity = fogOpacity * (0.7 + (_fogController.value * 0.3));
    
    return Stack(
      children: [
        // Google Maps مع تظليل داكن
        AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _fogController]),
          builder: (context, child) {
            return GoogleMap(
              onMapCreated: (controller) {
                _onMapCreated(controller);
                controller.setMapStyle(_getDarkMapStyle());
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(centerLat, centerLon),
                zoom: 15.0,
                tilt: widget.isLowAngle ? _cameraTilt : 0.0,
                bearing: _cameraBearing,
              ),
              mapType: MapType.normal,
              markers: _buildMarkers(),
              circles: _buildPulsatingCircles(),
              polylines: _buildRoutePolylines(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onCameraMove: (position) {
                setState(() {
                  _cameraTilt = position.tilt;
                  _cameraBearing = position.bearing;
                });
              },
            );
          },
        ),
        
        // طبقة الضباب المتغيرة
        if (animatedFogOpacity > 0.1)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fogController,
              builder: (context, child) {
                return Container(
                  color: AppTheme.foggyBlue.withOpacity(animatedFogOpacity),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppTheme.foggyBlue.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud,
                            color: AppTheme.foggyBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مستوى الضباب: ${widget.snapshot.fogLevel.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'الرؤية: ${widget.snapshot.visibilityM.toStringAsFixed(0)} متر',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        
        // أزرار التحكم
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomIn());
                },
                backgroundColor: AppTheme.darkCard,
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomOut());
                },
                backgroundColor: AppTheme.darkCard,
                child: const Icon(Icons.remove, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'tilt_up',
                onPressed: () {
                  setState(() {
                    _cameraTilt = (_cameraTilt + 5).clamp(0.0, 60.0);
                  });
                  _updateCameraPosition();
                },
                backgroundColor: AppTheme.darkCard,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'tilt_down',
                onPressed: () {
                  setState(() {
                    _cameraTilt = (_cameraTilt - 5).clamp(0.0, 60.0);
                  });
                  _updateCameraPosition();
                },
                backgroundColor: AppTheme.darkCard,
                child: const Icon(Icons.arrow_downward, color: Colors.white),
              ),
            ],
          ),
        ),
        
        // مؤشر الرادار النبضي
        Positioned(
          bottom: 20,
          left: 20,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.radarTurquoise.withOpacity(
                      0.8 * (1 - _pulseController.value),
                    ),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.radarTurquoise,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getDarkMapStyle() {
    // نمط Google Maps داكن
    return '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#1d2c4d"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#1a3646"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#8a9195"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#17263c"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#304a7d"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#98a5be"}]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [{"color": "#283d6a"}]
      }
    ]
    ''';
  }
}

