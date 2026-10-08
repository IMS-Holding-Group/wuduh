import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/radar_snapshot.dart';

class ApiService {
  static String? _cachedBaseUrl;
  static const String _prefsKey = 'https://wuduh-backend-3edefd64bcec.herokuapp.com';
  static const String _herokuUrl = 'https://wuduh-backend-3edefd64bcec.herokuapp.com';

  // قائمة العناوين المحتملة للـ backend (الشائعة فقط)
  static List<String> get _commonUrls {
    // للويب، استخدم رابط Heroku مباشرة
    if (kIsWeb) {
      return [
        _herokuUrl, // Heroku (الأولوية الأولى للإنتاج)
        'http://127.0.0.1:5000', 
        'http://localhost:5000'
      ];
    }
    
    // للجوال (Android/iOS)
    try {
      // استيراد Platform فقط للجوال
      if (const bool.fromEnvironment('dart.library.io')) {
        // هذا الكود يعمل فقط على الجوال
        return [
          _herokuUrl,
          'http://10.0.2.2:5000', // Android Emulator
          'http://127.0.0.1:5000',
          'http://192.168.1.100:5000',
          'http://192.168.0.100:5000',
        ];
      }
    } catch (e) {
      // إذا فشل، استخدم القائمة الافتراضية
    }
    
    // القائمة الافتراضية
    return [
      _herokuUrl,
      'http://127.0.0.1:5000', 
      'http://localhost:5000'
    ];
  }

  static Future<String> getBaseUrl() async {
    // إذا كان هناك عنوان محفوظ، استخدمه أولاً
    if (_cachedBaseUrl != null) {
      if (await _testConnection(_cachedBaseUrl!)) {
        return _cachedBaseUrl!;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_prefsKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      if (await _testConnection(savedUrl)) {
        _cachedBaseUrl = savedUrl;
        return savedUrl;
      }
    }

    // جرب العناوين الشائعة أولاً (أسرع)
    for (final url in _commonUrls) {
      if (await _testConnection(url)) {
        _cachedBaseUrl = url;
        await prefs.setString(_prefsKey, url);
        return url;
      }
    }

    // إذا فشل كل شيء، استخدم العنوان الافتراضي
    if (kIsWeb) {
      return _herokuUrl; // للويب، استخدم Heroku مباشرة
    }
    return 'http://127.0.0.1:5000'; // للجوال
  }

  static Future<bool> _testConnection(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/api/v1/status'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url/api/v1/status'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get status');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<RadarSnapshot> getCurrentSimulation() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url/api/v1/sim/current'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RadarSnapshot.fromJson(data);
      }
      throw Exception('Failed to get current simulation');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<RadarSnapshot>> getSimulationHistory({int seconds = 10}) async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/api/v1/sim/history?seconds=$seconds'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data['history'] as List;
        return history.map((item) => RadarSnapshot.fromJson(item)).toList();
      }
      throw Exception('Failed to get simulation history');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> reportObstacle({
    required double latitude,
    required double longitude,
    String? description,
    String? reportedBy,
  }) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/report/obstacle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'description': description ?? 'عائق غير محدد',
          'reported_by': reportedBy ?? 'user',
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to report obstacle');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> callEmergency({
    required double latitude,
    required double longitude,
    required int fogLevel,
    String? userId,
  }) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/emergency/call'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'fog_level': fogLevel,
          'user_id': userId,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to call emergency');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> setLocation({
    required String city,
    String? neighborhood,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/config/location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'city': city,
          'neighborhood': neighborhood,
          'center_lat': latitude,
          'center_lon': longitude,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to set location');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> computeRoute({
    required Map<String, dynamic> from,
    required Map<String, dynamic> to,
  }) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/route/compute'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'from': from, 'to': to}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to compute route');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getLiveRoute(int routeId) async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/api/v1/route/live/$routeId'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get live route');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAlerts({String? severity}) async {
    try {
      final url = await getBaseUrl();
      final uri = Uri.parse('$url/api/v1/alerts').replace(
        queryParameters: severity != null ? {'severity': severity} : null,
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['alerts'] ?? []);
      }
      throw Exception('Failed to get alerts');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? fullName,
    String? email,
    String? phone,
  }) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'full_name': fullName,
          'email': email,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          throw Exception('خطأ في قراءة الاستجابة من الخادم');
        }
      }

      // محاولة قراءة رسالة الخطأ
      try {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'فشل التسجيل');
      } catch (e) {
        if (response.statusCode == 404) {
          throw Exception(
            'الخادم غير متاح. تأكد من تشغيل Backend على http://127.0.0.1:5000',
          );
        } else if (response.statusCode == 500) {
          throw Exception('خطأ في الخادم');
        } else {
          throw Exception('فشل التسجيل (رمز الخطأ: ${response.statusCode})');
        }
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        throw Exception(
          'لا يمكن الاتصال بالخادم. تأكد من تشغيل Backend على http://127.0.0.1:5000',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          throw Exception('خطأ في قراءة الاستجابة من الخادم');
        }
      }

      // محاولة قراءة رسالة الخطأ
      try {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'فشل تسجيل الدخول');
      } catch (e) {
        if (response.statusCode == 404) {
          throw Exception(
            'الخادم غير متاح. تأكد من تشغيل Backend على http://127.0.0.1:5000',
          );
        } else if (response.statusCode == 401) {
          throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
        } else {
          throw Exception(
            'فشل تسجيل الدخول (رمز الخطأ: ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        throw Exception(
          'لا يمكن الاتصال بالخادم. تأكد من تشغيل Backend على http://127.0.0.1:5000',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserMe(String token) async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/api/v1/user/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get user info');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> addSavedLocation({
    required String token,
    required String name,
    required double lat,
    required double lon,
    String? city,
    String? neighborhood,
  }) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/user/saved_location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'lat': lat,
          'lon': lon,
          'city': city,
          'neighborhood': neighborhood,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to add saved location');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // دالة لإعادة اكتشاف العنوان (مفيدة عند تغيير الشبكة)
  static Future<void> resetBaseUrl() async {
    _cachedBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  // IoT Endpoints
  Future<Map<String, dynamic>> updateIoTDistance(double distanceCm) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/api/v1/iot/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'distance_cm': distanceCm}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to update IoT data');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getLatestIoT() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/api/v1/iot/latest'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'success': false, 'distance_cm': null};
      }
      throw Exception('Failed to get IoT data');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}