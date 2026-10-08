import sqlite3
import json
import time
import random
import math
from datetime import datetime, timedelta

class RoadNetwork:
    # شبكة طرق مبسطة للمنطقة
    def __init__(self, center_lat, center_lon, radius_km=2.0):
        self.center_lat = center_lat
        self.center_lon = center_lon
        self.radius_km = radius_km
        self.roads = []
        self.intersections = []
        self._generate_road_network()
    
    def _generate_road_network(self):
        # توليد شبكة طرق شعاعية وشبكية
        # طرق رئيسية شعاعية (8 طرق)
        num_main_roads = 8
        for i in range(num_main_roads):
            angle = (i * 360 / num_main_roads) * math.pi / 180
            road = {
                'id': f'main_{i}',
                'type': 'main',
                'waypoints': self._generate_radial_road(angle, self.radius_km),
                'length_m': self.radius_km * 1000
            }
            self.roads.append(road)
        
        # طرق فرعية دائرية (3 دوائر)
        for ring in range(1, 4):
            radius = (ring * self.radius_km / 4)
            road = {
                'id': f'ring_{ring}',
                'type': 'secondary',
                'waypoints': self._generate_ring_road(radius),
                'length_m': 2 * math.pi * radius * 1000
            }
            self.roads.append(road)
        
        # نقاط تقاطع
        self._generate_intersections()
    
    def _generate_radial_road(self, angle, length_km):
        # توليد طريق شعاعي
        waypoints = []
        num_points = 20
        for i in range(num_points + 1):
            dist = (i / num_points) * length_km
            lat = self.center_lat + (dist / 111.0) * math.cos(angle)
            lon = self.center_lon + (dist / (111.0 * math.cos(math.radians(self.center_lat)))) * math.sin(angle)
            waypoints.append({'lat': lat, 'lon': lon})
        return waypoints
    
    def _generate_ring_road(self, radius_km):
        # توليد طريق دائري
        waypoints = []
        num_points = 32
        for i in range(num_points):
            angle = (i / num_points) * 2 * math.pi
            lat = self.center_lat + (radius_km / 111.0) * math.cos(angle)
            lon = self.center_lon + (radius_km / (111.0 * math.cos(math.radians(self.center_lat)))) * math.sin(angle)
            waypoints.append({'lat': lat, 'lon': lon})
        return waypoints
    
    def _generate_intersections(self):
        # توليد نقاط تقاطع
        for road in self.roads:
            if road['type'] == 'main':
                for point in road['waypoints'][::5]:
                    self.intersections.append(point)
    
    def get_road_at_point(self, lat, lon):
        # الحصول على أقرب طريق لنقطة معينة
        min_dist = float('inf')
        closest_road = None
        for road in self.roads:
            for wp in road['waypoints']:
                dist = math.sqrt((lat - wp['lat'])**2 + (lon - wp['lon'])**2) * 111000
                if dist < min_dist:
                    min_dist = dist
                    closest_road = road
        return closest_road

class RadarSimulator:
    def __init__(self, db_path, location):
        self.db_path = db_path
        self.location = location
        self.running = False
        self.current_snapshot = None
        self.road_network = None
        self.fog_level = 30.0
        self.temperature = 25.0
        self.humidity = 60.0
        self.wind_speed = 15.0
        self.obstacles = []
        self.vehicles = []
        self.simulation_time = datetime.now()
        self._initialize_network()
        self._generate_initial_data()
    
    def _initialize_network(self):
        # تهيئة شبكة الطرق
        center_lat = self.location.get('latitude', 20.0129)
        center_lon = self.location.get('longitude', 41.4677)
        self.road_network = RoadNetwork(center_lat, center_lon)
    
    def _generate_initial_data(self):
        # توليد البيانات الأولية
        center_lat = self.location.get('latitude', 20.0129)
        center_lon = self.location.get('longitude', 41.4677)
        
        # توليد مركبات على الطرق
        num_vehicles = random.randint(30, 100)
        for i in range(num_vehicles):
            road = random.choice(self.road_network.roads)
            wp_index = random.randint(0, len(road['waypoints']) - 1)
            wp = road['waypoints'][wp_index]
            
            # حساب الاتجاه بناءً على الطريق
            if wp_index < len(road['waypoints']) - 1:
                next_wp = road['waypoints'][wp_index + 1]
                heading = math.atan2(
                    next_wp['lon'] - wp['lon'],
                    next_wp['lat'] - wp['lat']
                ) * 180 / math.pi
            else:
                heading = random.uniform(0, 360)
            
            self.vehicles.append({
                'id': i + 1,
                'latitude': wp['lat'] + random.uniform(-0.001, 0.001),
                'longitude': wp['lon'] + random.uniform(-0.001, 0.001),
                'speed': random.uniform(20, 100),
                'heading': heading,
                'road_id': road['id'],
                'waypoint_index': wp_index,
                'distance_from_center': self._calculate_distance(center_lat, center_lon, wp['lat'], wp['lon'])
            })
        
        # توليد عوائق أولية
        for i in range(3):
            road = random.choice(self.road_network.roads)
            wp = random.choice(road['waypoints'])
            self.obstacles.append({
                'id': i + 1,
                'latitude': wp['lat'],
                'longitude': wp['lon'],
                'type': random.choice(['construction', 'accident', 'debris', 'slow_vehicle']),
                'severity': random.choice(['low', 'medium', 'high']),
                'distance_from_center': self._calculate_distance(center_lat, center_lon, wp['lat'], wp['lon']),
                'created_at': datetime.now().isoformat(),
                'duration_seconds': random.randint(20, 120)
            })
    
    def _calculate_distance(self, lat1, lon1, lat2, lon2):
        # حساب المسافة بالأمتار
        R = 6371000
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c
    
    def update_location(self, location):
        # تحديث الموقع وإعادة تهيئة الشبكة
        self.location = location
        self._initialize_network()
        self._generate_initial_data()
    
    def _update_weather(self):
        # تحديث بيانات الطقس
        # الضباب: تدرج زمني مع ضوضاء
        time_factor = (self.simulation_time.hour + self.simulation_time.minute/60) / 24.0
        base_fog = 20 + 40 * math.sin(time_factor * 2 * math.pi)
        self.fog_level = max(0, min(100, base_fog + random.uniform(-5, 5)))
        
        # درجة الحرارة: تدرج يومي
        base_temp = 20 + 10 * math.sin(time_factor * 2 * math.pi)
        self.temperature = base_temp + random.uniform(-2, 2)
        
        # الرطوبة: مرتبطة عكسياً مع الحرارة
        self.humidity = max(30, min(90, 80 - (self.temperature - 20) * 2 + random.uniform(-5, 5)))
        
        # سرعة الرياح
        self.wind_speed = max(5, min(30, 15 + random.uniform(-5, 5)))
    
    def _update_vehicles(self):
        # تحديث مواقع المركبات
        center_lat = self.location.get('latitude', 20.0129)
        center_lon = self.location.get('longitude', 41.4677)
        
        for vehicle in self.vehicles:
            # العثور على الطريق الحالي
            road = next((r for r in self.road_network.roads if r['id'] == vehicle['road_id']), None)
            if not road:
                continue
            
            # تحديث الموقع على الطريق
            wp_index = vehicle.get('waypoint_index', 0)
            if wp_index < len(road['waypoints']) - 1:
                # التحرك للأمام على الطريق
                speed_mps = vehicle['speed'] / 3.6
                distance_moved = speed_mps * 1.0
                
                current_wp = road['waypoints'][wp_index]
                next_wp = road['waypoints'][wp_index + 1]
                
                wp_distance = self._calculate_distance(
                    current_wp['lat'], current_wp['lon'],
                    next_wp['lat'], next_wp['lon']
                )
                
                if distance_moved >= wp_distance:
                    # الانتقال للطريقة التالية
                    vehicle['waypoint_index'] = min(wp_index + 1, len(road['waypoints']) - 1)
                    if vehicle['waypoint_index'] == len(road['waypoints']) - 1:
                        # نهاية الطريق، اختيار طريق جديد
                        new_road = random.choice(self.road_network.roads)
                        vehicle['road_id'] = new_road['id']
                        vehicle['waypoint_index'] = 0
                
                # تحديث الموقع الفعلي
                current_wp = road['waypoints'][vehicle['waypoint_index']]
                if vehicle['waypoint_index'] < len(road['waypoints']) - 1:
                    next_wp = road['waypoints'][vehicle['waypoint_index'] + 1]
                    ratio = min(1.0, distance_moved / wp_distance if wp_distance > 0 else 1.0)
                    vehicle['latitude'] = current_wp['lat'] + (next_wp['lat'] - current_wp['lat']) * ratio
                    vehicle['longitude'] = current_wp['lon'] + (next_wp['lon'] - current_wp['lon']) * ratio
                    
                    # تحديث الاتجاه
                    vehicle['heading'] = math.atan2(
                        next_wp['lon'] - current_wp['lon'],
                        next_wp['lat'] - current_wp['lat']
                    ) * 180 / math.pi
                else:
                    vehicle['latitude'] = current_wp['lat']
                    vehicle['longitude'] = current_wp['lon']
                
                # تحديث السرعة (بعض المركبات بطيئة)
                if random.random() < 0.1:
                    vehicle['speed'] = max(20, vehicle['speed'] + random.uniform(-5, 5))
                
                vehicle['distance_from_center'] = self._calculate_distance(
                    center_lat, center_lon, vehicle['latitude'], vehicle['longitude']
                )
    
    def _update_obstacles(self):
        # تحديث العوائق
        current_time = datetime.now()
        
        # إزالة العوائق المنتهية
        self.obstacles = [obs for obs in self.obstacles if 
                         (current_time - datetime.fromisoformat(obs['created_at'])).total_seconds() < obs['duration_seconds']]
        
        # توليد عوائق جديدة (متوسط كل 60 ثانية)
        if random.random() < 1.0/60.0:
            road = random.choice(self.road_network.roads)
            wp = random.choice(road['waypoints'])
            center_lat = self.location.get('latitude', 20.0129)
            center_lon = self.location.get('longitude', 41.4677)
            
            self.obstacles.append({
                'id': len(self.obstacles) + 1,
                'latitude': wp['lat'],
                'longitude': wp['lon'],
                'type': random.choice(['construction', 'accident', 'debris', 'slow_vehicle']),
                'severity': random.choice(['low', 'medium', 'high']),
                'distance_from_center': self._calculate_distance(center_lat, center_lon, wp['lat'], wp['lon']),
                'created_at': current_time.isoformat(),
                'duration_seconds': random.randint(20, 120)
            })
    
    def _generate_forecast(self):
        # توليد توقعات الطقس للساعتين القادمة
        forecast = []
        current_time = self.simulation_time
        
        for i in range(4):  # كل 30 دقيقة
            forecast_time = current_time + timedelta(minutes=30 * (i + 1))
            time_factor = (forecast_time.hour + forecast_time.minute/60) / 24.0
            
            temp = 20 + 10 * math.sin(time_factor * 2 * math.pi) + random.uniform(-2, 2)
            humidity = max(30, min(90, 80 - (temp - 20) * 2 + random.uniform(-5, 5)))
            fog = max(0, min(100, 20 + 40 * math.sin(time_factor * 2 * math.pi) + random.uniform(-5, 5)))
            
            forecast.append({
                'time_offset_minutes': 30 * (i + 1),
                'temperature_c': round(temp, 1),
                'humidity_pct': round(humidity, 1),
                'fog_level': round(fog, 1)
            })
        
        return forecast
    
    def _update_simulation(self):
        # تحديث المحاكاة
        self.simulation_time = datetime.now()
        self._update_weather()
        self._update_vehicles()
        self._update_obstacles()
    
    def get_current_snapshot(self):
        # الحصول على اللقطة الحالية
        center_lat = self.location.get('latitude', 20.0129)
        center_lon = self.location.get('longitude', 41.4677)
        
        visibility_m = max(20, 1000 * (1 - self.fog_level / 100))
        
        return {
            'city': self.location.get('city', 'الباحة'),
            'neighborhood': self.location.get('neighborhood', 'شارع المطار'),
            'timestamp': self.simulation_time.isoformat(),
            'position_center': {
                'lat': center_lat,
                'lon': center_lon
            },
            'fog_level': round(self.fog_level, 1),
            'visibility_m': round(visibility_m, 1),
            'temperature_c': round(self.temperature, 1),
            'humidity_pct': round(self.humidity, 1),
            'wind_kph': round(self.wind_speed, 1),
            'forecast': self._generate_forecast(),
            'obstacles': [
                {
                    'id': obs['id'],
                    'lat': obs['latitude'],
                    'lon': obs['longitude'],
                    'type': obs['type'],
                    'severity': obs['severity'],
                    'distance_from_center': round(obs['distance_from_center'], 1)
                }
                for obs in self.obstacles[:20]
            ],
            'vehicles': [
                {
                    'id': v['id'],
                    'lat': v['latitude'],
                    'lon': v['longitude'],
                    'speed': round(v['speed'], 1),
                    'heading': round(v['heading'], 1),
                    'distance_from_center': round(v['distance_from_center'], 1)
                }
                for v in sorted(self.vehicles, key=lambda x: x['distance_from_center'])[:50]
            ],
            'radar_snapshot_id': int(time.time()),
            'road_network': {
                'roads': [
                    {
                        'id': road['id'],
                        'type': road['type'],
                        'waypoints': road['waypoints'][::3]  # تقليل النقاط للعرض
                    }
                    for road in self.road_network.roads
                ]
            }
        }
    
    def run(self):
        # تشغيل حلقة المحاكاة
        self.running = True
        snapshot_counter = 0
        
        while self.running:
            self._update_simulation()
            snapshot = self.get_current_snapshot()
            self.current_snapshot = snapshot
            snapshot_counter += 1
            
            try:
                conn = sqlite3.connect(self.db_path)
                cursor = conn.cursor()
                
                # حفظ اللقطة
                cursor.execute('''
                    INSERT INTO radar_snapshots (timestamp, data_json)
                    VALUES (?, ?)
                ''', (snapshot['timestamp'], json.dumps(snapshot)))
                
                # الحفاظ على آخر 60 لقطة فقط
                cursor.execute('''
                    DELETE FROM radar_snapshots 
                    WHERE id NOT IN (
                        SELECT id FROM radar_snapshots 
                        ORDER BY timestamp DESC LIMIT 60
                    )
                ''')
                
                conn.commit()
                conn.close()
            except Exception as e:
                print(f"Error saving snapshot: {e}")
            
            time.sleep(1)
