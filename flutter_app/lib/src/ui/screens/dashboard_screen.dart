import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/radar_snapshot.dart';
import '../../../themes/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  RadarSnapshot? _currentSnapshot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await _apiService.getCurrentSimulation();
      setState(() {
        _currentSnapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المعلومات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentSnapshot == null
              ? const Center(child: Text('لا توجد بيانات'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'مستوى الضباب',
                                value: '${_currentSnapshot!.fogLevel.toStringAsFixed(1)}%',
                                icon: Icons.cloud,
                                color: AppTheme.foggyBlue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'الرؤية',
                                value: '${_currentSnapshot!.visibilityM.toStringAsFixed(0)}م',
                                icon: Icons.visibility,
                                color: AppTheme.radarTurquoise,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'العوائق',
                                value: '${_currentSnapshot!.obstacles.length}',
                                icon: Icons.warning,
                                color: AppTheme.warningYellow,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'المركبات',
                                value: '${_currentSnapshot!.vehicles.length}',
                                icon: Icons.directions_car,
                                color: AppTheme.radarTurquoise,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'الحرارة',
                                value: '${_currentSnapshot!.temperatureC.toStringAsFixed(1)}°',
                                icon: Icons.thermostat,
                                color: AppTheme.warningYellow,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'الرياح',
                                value: '${_currentSnapshot!.windKph.toStringAsFixed(0)} كم/س',
                                icon: Icons.air,
                                color: AppTheme.radarTurquoise,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

