import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../../themes/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _customCityController = TextEditingController();
  final TextEditingController _customNeighborhoodController = TextEditingController();
  bool _autoEmergency = false;
  bool _darkMode = true;
  String _defaultCity = 'الباحة';
  String _defaultNeighborhood = 'شارع المطار';
  Map<String, dynamic>? _userInfo;
  List<Map<String, dynamic>> _savedLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    setState(() {
      _autoEmergency = prefs.getBool('auto_emergency') ?? false;
      _darkMode = prefs.getBool('dark_mode') ?? true;
      _defaultCity = prefs.getString('default_city') ?? 'الباحة';
      _defaultNeighborhood = prefs.getString('default_neighborhood') ?? 'شارع المطار';
    });

    if (token != null) {
      try {
        final userData = await _apiService.getUserMe(token);
        setState(() {
          _userInfo = userData;
          _savedLocations = List<Map<String, dynamic>>.from(userData['saved_locations'] ?? []);
          if (userData['driver'] != null) {
            _vehiclePlateController.text = userData['driver']['vehicle_plate'] ?? '';
            if (userData['driver']['preferences'] != null) {
              _autoEmergency = userData['driver']['preferences']['auto_emergency'] ?? false;
            }
          }
        });
      } catch (e) {
        // تجاهل الأخطاء
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _saveVehiclePlate(String plate) async {
    if (_userInfo == null) return;
    try {
      // يمكن إضافة API call هنا لتحديث لوحة المركبة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vehicle_plate', plate);
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  Future<void> _showCustomLocationDialog() async {
    _customCityController.text = _defaultCity;
    _customNeighborhoodController.text = _defaultNeighborhood;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال موقع مخصص'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customCityController,
                decoration: const InputDecoration(
                  labelText: 'المدينة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customNeighborhoodController,
                decoration: const InputDecoration(
                  labelText: 'الحي / الشارع',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.streetview),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_customCityController.text.isNotEmpty && 
                  _customNeighborhoodController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'city': _customCityController.text,
                  'neighborhood': _customNeighborhoodController.text,
                  'lat': 20.0129, // إحداثيات افتراضية للباحة
                  'lon': 41.4677,
                });
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      await _applyLocation(result);
    }
  }

  Future<void> _showLocationSelector() async {
    final locations = [
      {'name': 'شارع المطار', 'city': 'الباحة', 'lat': 20.0129, 'lon': 41.4677},
      {'name': 'وسط الباحة', 'city': 'الباحة', 'lat': 20.0129, 'lon': 41.4677},
      {'name': 'حي الصفا', 'city': 'الباحة', 'lat': 20.0200, 'lon': 41.4700},
      {'name': 'حي العقيق', 'city': 'الباحة', 'lat': 20.0100, 'lon': 41.4600},
      {'name': 'الرياض - العليا', 'city': 'الرياض', 'lat': 24.7136, 'lon': 46.6753},
      {'name': 'الرياض - الملك فهد', 'city': 'الرياض', 'lat': 24.774265, 'lon': 46.738586},
      {'name': 'الخرج', 'city': 'الخرج', 'lat': 24.1556, 'lon': 47.3000},
    ];
    
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر الموقع الافتراضي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: AppTheme.radarTurquoise),
                    title: Text(
                      loc['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(loc['city'] as String),
                    onTap: () => Navigator.pop(context, loc),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    if (selected != null) {
      await _applyLocation(selected);
    }
  }

  Future<void> _applyLocation(Map<String, dynamic> location) async {
    try {
      final city = location['city'] as String;
      final neighborhood = location['neighborhood'] ?? location['name'] ?? '';
      final lat = location['lat'] as double;
      final lon = location['lon'] as double;
      
      // تحديث الموقع في الخادم
      await _apiService.setLocation(
        city: city,
        neighborhood: neighborhood,
        latitude: lat,
        longitude: lon,
      );
      
      // حفظ الموقع محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_city', city);
      await prefs.setString('default_neighborhood', neighborhood);
      await prefs.setDouble('default_lat', lat);
      await prefs.setDouble('default_lon', lon);
      
      setState(() {
        _defaultCity = city;
        _defaultNeighborhood = neighborhood;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث الموقع إلى $city - $neighborhood'),
            backgroundColor: AppTheme.radarTurquoise,
            action: SnackBarAction(
              label: 'تحديث الآن',
              textColor: Colors.white,
              onPressed: () {
                // إعادة تحميل التطبيق بالموقع الجديد
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديث الموقع: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _vehiclePlateController.dispose();
    _customCityController.dispose();
    _customNeighborhoodController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('user_id');
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_userInfo != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معلومات المستخدم',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(_userInfo!['user']['full_name'] ?? ''),
                            subtitle: Text(_userInfo!['user']['username'] ?? ''),
                          ),
                          if (_userInfo!['driver'] != null) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.directions_car),
                              title: Text('${_userInfo!['driver']['vehicle_make']} ${_userInfo!['driver']['vehicle_model']}'),
                              subtitle: Text('لوحة: ${_userInfo!['driver']['vehicle_plate'] ?? 'غير محدد'}'),
                            ),
                          ],
                        const SizedBox(height: 16),
                        const Text(
                          'لوحة المركبة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _vehiclePlateController,
                          decoration: const InputDecoration(
                            labelText: 'رقم اللوحة',
                            hintText: 'مثال: أ ب ج 1234',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.confirmation_number),
                          ),
                          onChanged: (value) {
                            _saveVehiclePlate(value);
                          },
                        ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إعدادات الطوارئ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('تفعيل الطوارئ التلقائي'),
                          subtitle: const Text('إرسال تنبيه تلقائي عند الخطر'),
                          value: _autoEmergency,
                          onChanged: (value) {
                            setState(() {
                              _autoEmergency = value;
                            });
                            _saveSetting('auto_emergency', value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الموقع الافتراضي',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _showLocationSelector,
                              icon: const Icon(Icons.edit_location, size: 20),
                              label: const Text('تغيير الموقع'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.radarTurquoise, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _defaultCity,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _defaultNeighborhood,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showCustomLocationDialog,
                          icon: const Icon(Icons.edit_location_alt),
                          label: const Text('إدخال موقع مخصص'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.foggyBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'المواقع المحفوظة',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                // يمكن إضافة شاشة لإضافة موقع جديد
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ميزة قريباً')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_savedLocations.isEmpty)
                          const Text('لا توجد مواقع محفوظة')
                        else
                          ..._savedLocations.map((loc) => ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text(loc['name'] ?? ''),
                            subtitle: Text('${loc['city'] ?? ''} - ${loc['neighborhood'] ?? ''}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                // يمكن إضافة حذف الموقع
                              },
                            ),
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emergencyRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }
}

