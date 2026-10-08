import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/radar_snapshot.dart';
import '../widgets/simple_map_widget.dart';
import '../widgets/weather_card.dart';
import '../widgets/radar_summary_card.dart';
import '../../../themes/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  RadarSnapshot? _currentSnapshot;
  bool _isLoading = true;
  String _currentCity = 'الباحة';
  String _currentNeighborhood = 'شارع المطار';
  double? _iotDistanceCm;
  String? _iotTimestamp;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _loadData();
    _startPeriodicUpdate();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('default_city');
    final savedNeighborhood = prefs.getString('default_neighborhood');
    final savedLat = prefs.getDouble('default_lat');
    final savedLon = prefs.getDouble('default_lon');
    
    if (savedCity != null && savedNeighborhood != null && savedLat != null && savedLon != null) {
      // تطبيق الموقع المحفوظ
      try {
        await _apiService.setLocation(
          city: savedCity,
          neighborhood: savedNeighborhood,
          latitude: savedLat,
          longitude: savedLon,
        );
        setState(() {
          _currentCity = savedCity;
          _currentNeighborhood = savedNeighborhood;
        });
      } catch (e) {
        // تجاهل الأخطاء
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await _apiService.getCurrentSimulation();
      
      // قراءة بيانات IoT
      try {
        final iotData = await _apiService.getLatestIoT();
        if (iotData['success'] == true && iotData['distance_cm'] != null) {
          setState(() {
            _iotDistanceCm = iotData['distance_cm']?.toDouble();
            _iotTimestamp = iotData['timestamp'];
          });
        }
      } catch (e) {
        // تجاهل أخطاء IoT إذا لم تكن البيانات متاحة
      }
      
      setState(() {
        _currentSnapshot = snapshot;
        _currentCity = snapshot.location['city'] ?? 'الباحة';
        _currentNeighborhood = snapshot.location['neighborhood'] ?? 'شارع المطار';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاتصال: $e')),
        );
      }
    }
  }

  void _startPeriodicUpdate() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadData();
        _startPeriodicUpdate();
      }
    });
  }

  Future<void> _showLocationSelector() async {
    final locations = [
      {'name': 'شارع المطار', 'city': 'الباحة', 'lat': 20.0129, 'lon': 41.4677},
      {'name': 'وسط الباحة', 'city': 'الباحة', 'lat': 20.0129, 'lon': 41.4677},
      {'name': 'حي الصفا', 'city': 'الباحة', 'lat': 20.0200, 'lon': 41.4700},
      {'name': 'حي العقيق', 'city': 'الباحة', 'lat': 20.0100, 'lon': 41.4600},
      {'name': 'الرياض', 'city': 'الرياض', 'lat': 24.7136, 'lon': 46.6753},
    ];
    
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر الموقع',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...locations.map((loc) => ListTile(
              leading: const Icon(Icons.location_on, color: AppTheme.radarTurquoise),
              title: Text(
                loc['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(loc['city'] as String),
              onTap: () => Navigator.pop(context, loc),
            )),
          ],
        ),
      ),
    );
    
    if (selected != null) {
      try {
        await _apiService.setLocation(
          city: selected['city'] as String,
          neighborhood: selected['name'] as String,
          latitude: selected['lat'] as double,
          longitude: selected['lon'] as double,
        );
        setState(() {
          _currentCity = selected['city'] as String;
          _currentNeighborhood = selected['name'] as String;
        });
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في تغيير الموقع: $e')),
          );
        }
      }
    }
  }

  Future<void> _checkRouteBeforeDeparture() async {
    if (_currentSnapshot == null) return;
    
    try {
      final currentLat = _currentSnapshot!.positionCenter['lat']?.toDouble() ?? 20.0129;
      final currentLon = _currentSnapshot!.positionCenter['lon']?.toDouble() ?? 41.4677;
      
      final from = {
        'lat': currentLat,
        'lon': currentLon
      };
      // نقطة الوجهة على بعد كيلومتر تقريباً
      final to = {
        'lat': currentLat + 0.009,  // حوالي 1 كم شمالاً
        'lon': currentLon + 0.009   // حوالي 1 كم شرقاً
      };
      
      final response = await _apiService.computeRoute(from: from, to: to);
      if (mounted && response['success'] == true) {
        final routes = response['routes'] as List;
        if (routes.isNotEmpty) {
          final bestRoute = routes[0];
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('تحليل المسار'),
              content: Text(
                'أفضل مسار آمن:\n'
                'مستوى الضباب: ${bestRoute['fog_avg']}%\n'
                'عدد العوائق: ${bestRoute['obstacles_count']}\n'
                'وقت الوصول: ${bestRoute['eta_minutes']} دقيقة\n'
                'نقاط الأمان: ${bestRoute['safety_score']}'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
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

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inSeconds < 60) {
        return 'منذ ${diff.inSeconds} ثانية';
      } else if (diff.inMinutes < 60) {
        return 'منذ ${diff.inMinutes} دقيقة';
      } else {
        return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وضوح'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: InkWell(
                        onTap: _showLocationSelector,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.radarTurquoise, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentCity,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentNeighborhood,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AppTheme.radarTurquoise),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // بطاقة بيانات IoT
                    if (_iotDistanceCm != null)
                      Card(
                        color: AppTheme.radarTurquoise.withOpacity(0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sensors,
                                color: AppTheme.radarTurquoise,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'قراءة الحساس',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_iotDistanceCm!.toStringAsFixed(1)} سم',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.radarTurquoise,
                                      ),
                                    ),
                                    if (_iotTimestamp != null)
                                      Text(
                                        'آخر تحديث: ${_formatTimestamp(_iotTimestamp!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_iotDistanceCm != null) const SizedBox(height: 16),
                    if (_currentSnapshot != null) ...[
                      SimpleMapWidget(snapshot: _currentSnapshot!),
                      const SizedBox(height: 16),
                      WeatherCard(snapshot: _currentSnapshot!),
                      const SizedBox(height: 16),
                      RadarSummaryCard(snapshot: _currentSnapshot!),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _checkRouteBeforeDeparture,
                        icon: const Icon(Icons.route, size: 24),
                        label: const Text(
                          'افحص الطريق قبل الانطلاق',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.radarTurquoise,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
