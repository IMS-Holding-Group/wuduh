import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/radar_snapshot.dart';
import '../../../themes/app_theme.dart';

// رسام خطوط الرادار
class RadarPainter extends CustomPainter {
  final double pulseValue;

  RadarPainter(this.pulseValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.radarTurquoise.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // خطوط رادار متحركة
    for (int i = 0; i < 4; i++) {
      final angle = (pulseValue * 2 * math.pi) + (i * math.pi / 2);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimpleMapWidget extends StatefulWidget {
  final RadarSnapshot snapshot;
  final List<Map<String, dynamic>>? routeWaypoints;

  const SimpleMapWidget({
    super.key,
    required this.snapshot,
    this.routeWaypoints,
  });

  @override
  State<SimpleMapWidget> createState() => _SimpleMapWidgetState();
}

class _SimpleMapWidgetState extends State<SimpleMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _tiltAngle = 0.4; // زاوية الميل للخريطة ثلاثية الأبعاد
  bool _is3DMode = true; // تفعيل الوضع ثلاثي الأبعاد
  late AnimationController _pulseController;
  late AnimationController _fogController;
  Timer? _updateTimer;

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

  @override
  Widget build(BuildContext context) {
    final centerLat = widget.snapshot.positionCenter['lat']?.toDouble() ?? 20.0129;
    final centerLon = widget.snapshot.positionCenter['lon']?.toDouble() ?? 41.4677;
    final centerPoint = LatLng(centerLat, centerLon);

    final fogLevel = widget.snapshot.fogLevel / 100.0;
    final fogOpacity = (fogLevel * 0.6).clamp(0.0, 0.6);

    // رسم شبكة الطرق من البيانات
    List<Polyline> roadPolylines = [];
    if (widget.snapshot.roadNetwork != null) {
      final roads = widget.snapshot.roadNetwork!['roads'] as List?;
      if (roads != null) {
        for (final road in roads) {
          final waypoints = road['waypoints'] as List?;
          if (waypoints != null && waypoints.isNotEmpty) {
            final points = waypoints.map<LatLng>((wp) {
              return LatLng(
                wp['lat']?.toDouble() ?? centerLat,
                wp['lon']?.toDouble() ?? centerLon,
              );
            }).toList();
            
            // طرق أكثر واقعية مع تأثيرات ثلاثية الأبعاد
            roadPolylines.add(Polyline(
              points: points,
              strokeWidth: road['type'] == 'main' ? 8.0 : 4.0,
              color: road['type'] == 'main' 
                  ? const Color(0xFF5A6578) // لون أفتح للطرق الرئيسية (3D effect)
                  : const Color(0xFF3D4858).withOpacity(0.8),
              borderStrokeWidth: road['type'] == 'main' ? 3.0 : 1.5,
              borderColor: road['type'] == 'main'
                  ? const Color(0xFF8A9BA8).withOpacity(0.6) // حدود أفتح للعمق
                  : const Color(0xFF5A6578).withOpacity(0.4),
            ));
          }
        }
      }
    }

    // رسم المسار المحدد
    List<Polyline> routePolylines = [];
    if (widget.routeWaypoints != null && widget.routeWaypoints!.isNotEmpty) {
      final routePoints = widget.routeWaypoints!.map<LatLng>((wp) {
        return LatLng(
          wp['lat']?.toDouble() ?? centerLat,
          wp['lon']?.toDouble() ?? centerLon,
        );
      }).toList();
      
      // مسار أكثر واقعية مع خط منقط وتأثير ثلاثي الأبعاد
      routePolylines.add(Polyline(
        points: routePoints,
        strokeWidth: 12.0,
        color: AppTheme.radarTurquoise,
        borderStrokeWidth: 5.0,
        borderColor: Colors.white.withOpacity(0.9),
        // pattern: StrokePattern.dashed(segments: const [15.0, 8.0]), // تم إزالة النمط مؤقتاً
      ));
    }

    // تأثير ثلاثي الأبعاد للخريطة
    Widget mapContent = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centerPoint,
        initialZoom: 15.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
            // طبقة الخريطة الأساسية - استخدام خريطة داكنة أكثر واقعية
            Builder(
              builder: (context) => TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.trsi.wuduh',
                maxZoom: 19,
                retinaMode: RetinaMode.isHighDensity(context),
                tileProvider: NetworkTileProvider(),
              ),
            ),
            // طبقة إضافية للطرق (اختيارية)
            Opacity(
              opacity: 0.3, // شفافية للطبقة
              child: TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trsi.wuduh',
                maxZoom: 19,
              ),
            ),
            // رسم شبكة الطرق بتأثير ثلاثي الأبعاد
            if (roadPolylines.isNotEmpty)
              PolylineLayer(
                polylines: roadPolylines.map((polyline) {
                  // إضافة تأثير ارتفاع للطرق الرئيسية
                  if (polyline.strokeWidth == 4.0) {
                    return Polyline(
                      points: polyline.points,
                      strokeWidth: polyline.strokeWidth,
                      color: polyline.color,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.black.withOpacity(0.3),
                    );
                  }
                  return polyline;
                }).toList(),
              ),
            // رسم المسار المحدد
            if (routePolylines.isNotEmpty)
              PolylineLayer(
                polylines: routePolylines,
              ),
            MarkerLayer(
              markers: [
                // موقع المستخدم أكثر واقعية
                Marker(
                  point: centerPoint,
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // دائرة نبضية خارجية
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulseValue = _pulseController.value;
                          final pulseSize = 60.0 + (pulseValue * 20.0);
                          return Container(
                            width: pulseSize,
                            height: pulseSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.emergencyRed.withOpacity(0.2 * (1 - pulseValue)),
                              border: Border.all(
                                color: AppTheme.emergencyRed.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      // المؤشر الرئيسي بتأثير ثلاثي الأبعاد
                      Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(_tiltAngle * 0.3),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.emergencyRed,
                                AppTheme.emergencyRed.withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emergencyRed.withOpacity(0.9),
                                blurRadius: 25,
                                spreadRadius: 10,
                                offset: Offset(0, 5 * _tiltAngle),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: Offset(0, 3 * _tiltAngle),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // سهم يشير للأسفل
                      Positioned(
                        bottom: -8,
                        child: Icon(
                          Icons.location_on,
                          color: AppTheme.emergencyRed,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                // العوائق كنقاط نبضية
                ...widget.snapshot.obstacles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final obstacle = entry.value;
                  final lat = obstacle['lat']?.toDouble() ?? centerLat;
                  final lon = obstacle['lon']?.toDouble() ?? centerLon;
                  final severity = obstacle['severity'] ?? 'medium';
                  Color obstacleColor = AppTheme.warningYellow;
                  if (severity == 'high') obstacleColor = AppTheme.emergencyRed;
                  if (severity == 'low') obstacleColor = AppTheme.foggyBlue;
                  
                  final pulseValue = _pulseController.value;
                  final pulseSize = 35.0 + (pulseValue * 12.0);
                  
                  return Marker(
                    point: LatLng(lat, lon),
                    width: pulseSize,
                    height: pulseSize,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // دوائر نبضية متعددة للعمق
                            for (int i = 0; i < 3; i++)
                              Container(
                                width: pulseSize - (i * 8.0),
                                height: pulseSize - (i * 8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: obstacleColor.withOpacity(
                                    (0.3 - (i * 0.1)) * (1 - pulseValue),
                                  ),
                                  border: Border.all(
                                    color: obstacleColor.withOpacity(0.9 - (i * 0.2)),
                                    width: 2.0 - (i * 0.5),
                                  ),
                                ),
                              ),
                            // النقطة المركزية مع أيقونة واقعية ثلاثية الأبعاد
                            Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateX(_tiltAngle * 0.2),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      obstacleColor,
                                      obstacleColor.withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: obstacleColor.withOpacity(0.9),
                                      blurRadius: 20,
                                      spreadRadius: 6,
                                      offset: Offset(0, 4 * _tiltAngle),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: Offset(0, 2 * _tiltAngle),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  severity == 'high' 
                                      ? Icons.dangerous 
                                      : Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }),
                // المركبات كنقاط نبضية
                ...widget.snapshot.vehicles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final vehicle = entry.value;
                  final lat = vehicle['lat']?.toDouble() ?? centerLat;
                  final lon = vehicle['lon']?.toDouble() ?? centerLon;
                  final heading = (vehicle['heading'] ?? 0) * 3.14159 / 180;
                  
                  final pulseValue = _pulseController.value;
                  final pulseSize = 25.0 + (pulseValue * 8.0);
                  
                  return Marker(
                    point: LatLng(lat, lon),
                    width: pulseSize,
                    height: pulseSize,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // دوائر نبضية متعددة
                            for (int i = 0; i < 2; i++)
                              Container(
                                width: pulseSize - (i * 6.0),
                                height: pulseSize - (i * 6.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.radarTurquoise.withOpacity(
                                    (0.2 - (i * 0.1)) * (1 - pulseValue),
                                  ),
                                  border: Border.all(
                                    color: AppTheme.radarTurquoise.withOpacity(0.7 - (i * 0.2)),
                                    width: 1.5 - (i * 0.5),
                                  ),
                                ),
                              ),
                            // المركبة المركزية بتأثير ثلاثي الأبعاد واقعي
                            Transform(
                              transform: Matrix4.identity()
                                ..rotateZ(heading)
                                ..setEntry(3, 2, 0.001)
                                ..rotateX(_tiltAngle * 0.2),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.radarTurquoise,
                                      AppTheme.radarTurquoise.withOpacity(0.7),
                                      AppTheme.radarTurquoise.withOpacity(0.5),
                                    ],
                                  ),
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.radarTurquoise.withOpacity(0.8),
                                      blurRadius: 15,
                                      spreadRadius: 4,
                                      offset: Offset(0, 3 * _tiltAngle),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: Offset(0, 2 * _tiltAngle),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ],
        );

    // تطبيق تأثير ثلاثي الأبعاد واقعي
    if (_is3DMode) {
      mapContent = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002) // Perspective أقوى
          ..rotateX(_tiltAngle * 0.5) // ميل أقوى للخريطة
          ..scale(1.0 - (_tiltAngle * 0.1)), // تقليل الحجم عند الميل
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
                offset: Offset(0, 10 * _tiltAngle),
              ),
            ],
          ),
          child: mapContent,
        ),
      );
    }

    final mapWidget = Stack(
      children: [
        // طبقة خلفية للظلال ثلاثية الأبعاد
        if (_is3DMode)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1 * _tiltAngle),
                  ],
                ),
              ),
            ),
          ),
        mapContent,
        // طبقة الضباب المتغيرة
        AnimatedBuilder(
          animation: _fogController,
          builder: (context, child) {
            final animatedFogOpacity = fogOpacity * (0.7 + (_fogController.value * 0.3));
            if (animatedFogOpacity > 0.1) {
              return Positioned.fill(
                child: Container(
                  color: AppTheme.foggyBlue.withOpacity(animatedFogOpacity),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                ),
              );
            }
            return const SizedBox.shrink();
          },
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
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                },
                backgroundColor: AppTheme.darkCard,
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                },
                backgroundColor: AppTheme.darkCard,
                child: const Icon(Icons.remove, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: '3d_toggle',
                onPressed: () {
                  setState(() {
                    _is3DMode = !_is3DMode;
                    if (_is3DMode) {
                      _tiltAngle = 0.5; // تفعيل الميل بقوة أكبر
                    } else {
                      _tiltAngle = 0.0; // إلغاء الميل
                    }
                  });
                },
                backgroundColor: _is3DMode ? AppTheme.radarTurquoise : AppTheme.darkCard,
                child: Icon(
                  _is3DMode ? Icons.view_in_ar : Icons.view_in_ar_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (_is3DMode)
                FloatingActionButton.small(
                  heroTag: 'tilt_up',
                  onPressed: () {
                    setState(() {
                      _tiltAngle = (_tiltAngle + 0.1).clamp(0.0, 0.8);
                    });
                  },
                  backgroundColor: AppTheme.darkCard,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              if (_is3DMode) const SizedBox(height: 8),
              if (_is3DMode)
                FloatingActionButton.small(
                  heroTag: 'tilt_down',
                  onPressed: () {
                    setState(() {
                      _tiltAngle = (_tiltAngle - 0.1).clamp(0.0, 0.8);
                    });
                  },
                  backgroundColor: AppTheme.darkCard,
                  child: const Icon(Icons.arrow_downward, color: Colors.white),
                ),
            ],
          ),
        ),
        // مؤشر الرادار النبضي أكثر واقعية
        Positioned(
          bottom: 20,
          left: 20,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = _pulseController.value;
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6),
                  border: Border.all(
                    color: AppTheme.radarTurquoise.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // دوائر نبضية متعددة
                    for (int i = 0; i < 3; i++)
                      Container(
                        width: 80 - (i * 15.0) + (pulseValue * 20.0),
                        height: 80 - (i * 15.0) + (pulseValue * 20.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.radarTurquoise.withOpacity(
                              0.8 * (1 - pulseValue) * (1 - i * 0.3),
                            ),
                            width: 2 - (i * 0.5),
                          ),
                        ),
                      ),
                    // النقطة المركزية
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.radarTurquoise,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.radarTurquoise.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    // خطوط الرادار
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: RadarPainter(pulseValue),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    if (MediaQuery.of(context).size.height > 400) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 400,
            child: mapWidget,
          ),
        ),
      );
    } else {
      return SizedBox.expand(child: mapWidget);
    }
  }
}

