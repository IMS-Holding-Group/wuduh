import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/radar_snapshot.dart';
import '../../../themes/app_theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final ApiService _apiService = ApiService();
  List<RadarSnapshot> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _apiService.getSimulationHistory(seconds: 10);
      setState(() {
        _history = history;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _callEmergency() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // الحصول على الموقع الحالي
      final currentSim = await _apiService.getCurrentSimulation();
      final response = await _apiService.callEmergency(
        latitude: currentSim.positionCenter['lat']?.toDouble() ?? 20.0129,
        longitude: currentSim.positionCenter['lon']?.toDouble() ?? 41.4677,
        fogLevel: currentSim.fogLevel.round(),
      );

      if (mounted) {
        // تحديث التاريخ من الاستجابة
        if (response['radar_snapshots'] != null) {
          final snapshots = response['radar_snapshots'] as List;
          setState(() {
            _history = snapshots.map((s) => RadarSnapshot.fromJson(s)).toList();
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال نداء الطوارئ'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطوارئ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppTheme.emergencyRed,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emergency,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'طلب مساعدة طارئة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _callEmergency,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.emergencyRed,
                              ),
                            )
                          : const Icon(Icons.emergency, size: 28),
                      label: Text(
                        _isLoading ? 'جاري الإرسال...' : 'اتصل بالطوارئ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.emergencyRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        minimumSize: const Size(double.infinity, 64),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'آخر 10 ثوانٍ من بيانات الرادار',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('لا توجد بيانات متاحة'),
                ),
              )
            else
              ..._history.asMap().entries.map((entry) {
                final index = entry.key;
                final snapshot = entry.value;
                final timeOffset = _history.length - index - 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.emergencyRed.withOpacity(0.2),
                      child: Text('${timeOffset}s'),
                    ),
                    title: Text('مستوى الضباب: ${snapshot.fogLevel.toStringAsFixed(1)}%'),
                    subtitle: Text(
                      'الرؤية: ${snapshot.visibilityM.toStringAsFixed(0)}م | العوائق: ${snapshot.obstacles.length} | المركبات: ${snapshot.vehicles.length}',
                    ),
                    trailing: Text(
                      snapshot.timestamp.split('T')[1].split('.')[0],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

