import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/radar_snapshot.dart';
import '../widgets/simple_map_widget.dart';
import '../../../themes/app_theme.dart';

class LiveRouteScreen extends StatefulWidget {
  final int? routeId;
  
  const LiveRouteScreen({super.key, this.routeId});

  @override
  State<LiveRouteScreen> createState() => _LiveRouteScreenState();
}

class _LiveRouteScreenState extends State<LiveRouteScreen> {
  final ApiService _apiService = ApiService();
  RadarSnapshot? _currentSnapshot;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  int? _currentRouteId;
  List<Map<String, dynamic>>? _currentRouteWaypoints;

  @override
  void initState() {
    super.initState();
    _currentRouteId = widget.routeId;
    _loadData();
    _startPeriodicUpdate();
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await _apiService.getCurrentSimulation();
      
      // تحديث بيانات المسار إذا كان موجوداً
      List<Map<String, dynamic>>? routeWaypoints;
      if (_currentRouteId != null) {
        try {
          final routeData = await _apiService.getLiveRoute(_currentRouteId!);
          if (routeData['waypoints'] != null) {
            routeWaypoints = List<Map<String, dynamic>>.from(routeData['waypoints']);
          }
        } catch (e) {
          // تجاهل الأخطاء
        }
      }
      
      setState(() {
        _currentSnapshot = snapshot;
        _currentRouteWaypoints = routeWaypoints;
        _isLoading = false;
        
        // إضافة تنبيهات للعوائق القريبة
        for (final obstacle in snapshot.obstacles) {
          final distance = obstacle['distance_from_center']?.toDouble() ?? 9999;
          if (distance <= 100) {
            final confidence = (50 + (100 - distance) / 2).round();
            _addNotification(
              'عائق ${obstacle['type']} بعد ${distance.toStringAsFixed(0)}م',
              confidence: confidence,
            );
          }
        }
        
        if (snapshot.fogLevel > 70) {
          _addNotification('تحذير: مستوى ضباب عالي');
        }
      });
      
      // تحديث بيانات المسار المباشر
      if (_currentRouteId != null) {
        try {
          final routeData = await _apiService.getLiveRoute(_currentRouteId!);
          // يمكن استخدام routeData لتحديث عرض المسار
        } catch (e) {
          // تجاهل الأخطاء
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>>? _getRouteWaypoints() {
    return _currentRouteWaypoints;
  }

  void _addNotification(String message, {int? confidence}) {
    final key = message;
    if (!_notifications.any((n) => n['message'] == key)) {
      setState(() {
        _notifications.add({
          'message': message,
          'confidence': confidence,
          'timestamp': DateTime.now(),
        });
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _notifications.removeWhere((n) => n['message'] == key);
          });
        }
      });
    }
  }

  void _startPeriodicUpdate() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _loadData();
        _startPeriodicUpdate();
      }
    });
  }

  Future<void> _findAlternativeRoute() async {
    if (_currentSnapshot == null) return;
    
    try {
      final from = {
        'lat': _currentSnapshot!.positionCenter['lat'],
        'lon': _currentSnapshot!.positionCenter['lon']
      };
      final to = {
        'lat': _currentSnapshot!.positionCenter['lat']! + 0.01,
        'lon': _currentSnapshot!.positionCenter['lon']! + 0.01
      };
      
      final response = await _apiService.computeRoute(from: from, to: to);
      if (mounted && response['success'] == true) {
        final routes = response['routes'] as List;
        if (routes.length > 1) {
          setState(() {
            _currentRouteId = routes[1]['route_id'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم العثور على مسار بديل')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسار مباشر'),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentSnapshot != null
                  ? SizedBox.expand(
                      child: SimpleMapWidget(
                        snapshot: _currentSnapshot!,
                        routeWaypoints: _currentRouteWaypoints,
                      ),
                    )
                  : const Center(child: Text('لا توجد بيانات')),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: _notifications.map((notification) {
                return Card(
                  color: AppTheme.warningYellow.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.black87),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['message'],
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (notification['confidence'] != null)
                                Text(
                                  'دقة الكشف: ${notification['confidence']}%',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentSnapshot != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _InfoItem(
                                label: 'الضباب',
                                value: '${_currentSnapshot!.fogLevel.toStringAsFixed(1)}%',
                              ),
                              _InfoItem(
                                label: 'الرؤية',
                                value: '${_currentSnapshot!.visibilityM.toStringAsFixed(0)}م',
                              ),
                              _InfoItem(
                                label: 'الرياح',
                                value: '${_currentSnapshot!.windKph.toStringAsFixed(0)} كم/س',
                              ),
                              _InfoItem(
                                label: 'الحرارة',
                                value: '${_currentSnapshot!.temperatureC.toStringAsFixed(1)}°',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentSnapshot!.temperatureC <= 3 && _currentSnapshot!.fogLevel > 40
                                ? 'حالة الطريق: زلق'
                                : 'حالة الطريق: جاف',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _findAlternativeRoute,
                  icon: const Icon(Icons.route),
                  label: const Text('طريق بديل الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.radarTurquoise,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
