import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/local_db.dart';
import '../../../themes/app_theme.dart';

class RouteSetupScreen extends StatefulWidget {
  const RouteSetupScreen({super.key});

  @override
  State<RouteSetupScreen> createState() => _RouteSetupScreenState();
}

class _RouteSetupScreenState extends State<RouteSetupScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final ApiService _apiService = ApiService();
  final LocalDb _localDb = LocalDb();
  List<Map<String, dynamic>> _savedLocations = [];
  List<Map<String, dynamic>> _routes = [];
  bool _isComputing = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    final locations = await _localDb.getSavedLocations();
    setState(() {
      _savedLocations = locations;
    });
  }

  Future<void> _findSafeRoute() async {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الوجهة')),
      );
      return;
    }

    setState(() {
      _isComputing = true;
      _routes = [];
    });

    try {
      // الحصول على الموقع الحالي
      final currentSim = await _apiService.getCurrentSimulation();
      final from = {
        'lat': currentSim.positionCenter['lat'],
        'lon': currentSim.positionCenter['lon']
      };
      
      // استخدام موقع محفوظ أو موقع افتراضي
      final savedLoc = _savedLocations.firstWhere(
        (loc) => loc['name'] == _destinationController.text,
        orElse: () => {'latitude': 24.774265, 'longitude': 46.738586},
      );
      
      final to = {
        'lat': savedLoc['latitude']?.toDouble() ?? 24.774265,
        'lon': savedLoc['longitude']?.toDouble() ?? 46.738586
      };

      final response = await _apiService.computeRoute(from: from, to: to);
      
      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(response['routes'] ?? []);
          _isComputing = false;
        });
        
        if (_routes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على مسارات')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isComputing = false;
      });
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
        title: const Text('إعداد المسار'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'الوجهة',
                hintText: 'أدخل اسم المدينة أو العنوان',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'مواقع سريعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _destinationController.text = 'البيت';
                    },
                    icon: const Icon(Icons.home, size: 20),
                    label: const Text(
                      'البيت',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.foggyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _destinationController.text = 'العمل';
                    },
                    icon: const Icon(Icons.work, size: 20),
                    label: const Text(
                      'العمل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.foggyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isComputing ? null : _findSafeRoute,
              icon: _isComputing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.route, size: 24),
              label: Text(
                _isComputing ? 'جاري الحساب...' : 'أفضل طريق آمن',
                style: const TextStyle(
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
            if (_routes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'المسارات المقترحة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    final isBest = index == 0;
                    return Card(
                      color: isBest ? AppTheme.radarTurquoise.withOpacity(0.1) : null,
                      child: ListTile(
                        leading: Icon(
                          isBest ? Icons.star : Icons.route,
                          color: isBest ? AppTheme.radarTurquoise : null,
                        ),
                        title: Text('مسار ${route['route_id']} ${isBest ? '(الأفضل)' : ''}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ضباب: ${route['fog_avg']}%'),
                            Text('عوائق: ${route['obstacles_count']}'),
                            Text('وقت: ${route['eta_minutes']} دقيقة'),
                            Text('أمان: ${route['safety_score']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.pushNamed(context, '/live-route', arguments: route['route_id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (_savedLocations.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'المواقع المحفوظة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _savedLocations.length,
                  itemBuilder: (context, index) {
                    final location = _savedLocations[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: Text(location['name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _localDb.deleteLocation(location['id']);
                            _loadSavedLocations();
                          },
                        ),
                        onTap: () {
                          _destinationController.text = location['name'];
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }
}
