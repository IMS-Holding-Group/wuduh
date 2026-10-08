import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/local_db.dart';
import '../../../themes/app_theme.dart';

class AlertsCenterScreen extends StatefulWidget {
  const AlertsCenterScreen({super.key});

  @override
  State<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends State<AlertsCenterScreen> {
  final ApiService _apiService = ApiService();
  final LocalDb _localDb = LocalDb();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _selectedSeverity;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _apiService.getAlerts(severity: _selectedSeverity);
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to local DB
      final localAlerts = await _localDb.getAlerts();
      setState(() {
        _alerts = localAlerts;
        _isLoading = false;
      });
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.emergencyRed;
      case 'medium':
        return AppTheme.warningYellow;
      default:
        return AppTheme.foggyBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز التنبيهات'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedSeverity = value == 'all' ? null : value;
                _isLoading = true;
              });
              _loadAlerts();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('الكل')),
              const PopupMenuItem(value: 'high', child: Text('عالي')),
              const PopupMenuItem(value: 'medium', child: Text('متوسط')),
              const PopupMenuItem(value: 'low', child: Text('منخفض')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? const Center(
                  child: Text('لا توجد تنبيهات'),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.builder(
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      final meta = alert['meta_json'] ?? {};
                      final distance = meta['distance_m'];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getSeverityColor(
                              alert['severity'] ?? 'low',
                            ),
                            child: const Icon(Icons.notifications, color: Colors.white),
                          ),
                          title: Text(alert['message'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${alert['type']} - ${alert['timestamp']}'),
                              if (distance != null)
                                Text('المسافة: ${distance.toString()}م'),
                              if (meta['confidence'] != null)
                                Text('دقة الكشف: ${meta['confidence']}%'),
                            ],
                          ),
                          trailing: Icon(
                            alert['severity'] == 'high'
                                ? Icons.priority_high
                                : Icons.info_outline,
                            color: _getSeverityColor(alert['severity'] ?? 'low'),
                          ),
                          onTap: () {
                            if (alert['latitude'] != null && alert['longitude'] != null) {
                              // يمكن عرض التنبيه على الخريطة
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('موقع التنبيه: ${alert['latitude']}, ${alert['longitude']}')),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

