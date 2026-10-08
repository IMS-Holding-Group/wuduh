import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themes/app_theme.dart';
import 'src/services/api_service.dart';
import 'src/ui/screens/home_screen.dart';
import 'src/ui/screens/login_screen.dart';
import 'src/ui/screens/register_screen.dart';
import 'src/ui/screens/route_setup_screen.dart';
import 'src/ui/screens/live_route_screen.dart';
import 'src/ui/screens/emergency_screen.dart';
import 'src/ui/screens/alerts_center_screen.dart';
import 'src/ui/screens/profile_screen.dart';
import 'src/ui/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Auto login للمستخدم test_driver1 (للتجربة فقط)
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('auth_token') == null) {
    // تسجيل دخول تلقائي للمستخدم الافتراضي
    try {
      final apiService = ApiService();
      final response = await apiService.login(username: 'test_driver1', password: '');
      if (response['success'] == true) {
        await prefs.setString('auth_token', response['token']);
        await prefs.setString('username', 'test_driver1');
        await prefs.setInt('user_id', response['user_id']);
      }
    } catch (e) {
      // تجاهل الأخطاء في التسجيل التلقائي
    }
  }
  
  // تطبيق الموقع الافتراضي المحفوظ عند بدء التطبيق
  final savedCity = prefs.getString('default_city');
  final savedNeighborhood = prefs.getString('default_neighborhood');
  final savedLat = prefs.getDouble('default_lat');
  final savedLon = prefs.getDouble('default_lon');
  
  if (savedCity != null && savedNeighborhood != null && savedLat != null && savedLon != null) {
    try {
      final apiService = ApiService();
      await apiService.setLocation(
        city: savedCity,
        neighborhood: savedNeighborhood,
        latitude: savedLat,
        longitude: savedLon,
      );
    } catch (e) {
      // تجاهل الأخطاء
    }
  } else {
    // تعيين الموقع الافتراضي (الباحة) إذا لم يكن محفوظاً
    try {
      final apiService = ApiService();
      await apiService.setLocation(
        city: 'الباحة',
        neighborhood: 'شارع المطار',
        latitude: 20.0129,
        longitude: 41.4677,
      );
      await prefs.setString('default_city', 'الباحة');
      await prefs.setString('default_neighborhood', 'شارع المطار');
      await prefs.setDouble('default_lat', 20.0129);
      await prefs.setDouble('default_lon', 41.4677);
    } catch (e) {
      // تجاهل الأخطاء
    }
  }
  
  runApp(const WuduhApp());
}

class WuduhApp extends StatelessWidget {
  const WuduhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وضوح',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ar', 'SA'),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/route-setup': (context) => const RouteSetupScreen(),
        '/live-route': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return LiveRouteScreen(routeId: args is int ? args : null);
        },
        '/emergency': (context) => const EmergencyScreen(),
        '/alerts': (context) => const AlertsCenterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RouteSetupScreen(),
    const EmergencyScreen(),
    const DashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'المسار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'طوارئ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'لوحة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'إعدادات',
          ),
        ],
      ),
    );
  }
}

