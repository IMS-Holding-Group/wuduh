import math
from modules.rules_engine import RulesEngine

class RouteAnalyzer:
    def __init__(self, road_network, obstacles, fog_level):
        self.road_network = road_network
        self.obstacles = obstacles
        self.fog_level = fog_level
        self.rules_engine = RulesEngine()
    
    def calculate_distance(self, lat1, lon1, lat2, lon2):
        # حساب المسافة بالأمتار
        R = 6371000
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c
    
    def find_nearest_waypoint(self, lat, lon, road):
        # العثور على أقرب نقطة على الطريق
        min_dist = float('inf')
        nearest_index = 0
        for i, wp in enumerate(road['waypoints']):
            dist = self.calculate_distance(lat, lon, wp['lat'], wp['lon'])
            if dist < min_dist:
                min_dist = dist
                nearest_index = i
        return nearest_index
    
    def calculate_route_cost(self, waypoints, from_lat, from_lon, to_lat, to_lon):
        # حساب تكلفة المسار (للخوارزمية)
        total_length = 0
        fog_sum = 0
        obstacles_count = 0
        
        # إضافة نقطة البداية
        full_waypoints = [{'lat': from_lat, 'lon': from_lon}] + waypoints + [{'lat': to_lat, 'lon': to_lon}]
        
        for i in range(len(full_waypoints) - 1):
            wp1 = full_waypoints[i]
            wp2 = full_waypoints[i + 1]
            
            # طول القطعة
            segment_length = self.calculate_distance(wp1['lat'], wp1['lon'], wp2['lat'], wp2['lon'])
            total_length += segment_length
            
            # متوسط الضباب على القطعة (مبسط)
            fog_sum += self.fog_level
            
            # عدد العوائق على القطعة
            mid_lat = (wp1['lat'] + wp2['lat']) / 2
            mid_lon = (wp1['lon'] + wp2['lon']) / 2
            
            for obs in self.obstacles:
                dist = self.calculate_distance(mid_lat, mid_lon, obs['latitude'], obs['longitude'])
                if dist < 100:  # عائق ضمن 100 متر
                    obstacles_count += 1
        
        avg_fog = fog_sum / len(full_waypoints) if full_waypoints else self.fog_level
        
        return {
            'length_m': total_length,
            'avg_fog': avg_fog,
            'obstacles_count': obstacles_count
        }
    
    def compute_routes(self, from_lat, from_lon, to_lat, to_lon):
        # حساب عدة مسارات من نقطة إلى أخرى
        routes = []
        
        # التحقق من أن road_network موجود وله طرق
        if not self.road_network or not hasattr(self.road_network, 'roads') or not self.road_network.roads:
            return routes
        
        # التحقق من أن النقاط مختلفة
        distance_between_points = self.calculate_distance(from_lat, from_lon, to_lat, to_lon)
        if distance_between_points < 10:  # أقل من 10 متر
            return routes
        
        # العثور على أقرب طرق لنقطة البداية والنهاية
        start_road = None
        end_road = None
        start_min_dist = float('inf')
        end_min_dist = float('inf')
        
        for road in self.road_network.roads:
            if not road.get('waypoints'):
                continue
            # نقطة البداية
            for wp in road['waypoints']:
                dist = self.calculate_distance(from_lat, from_lon, wp['lat'], wp['lon'])
                if dist < start_min_dist:
                    start_min_dist = dist
                    start_road = road
            
            # نقطة النهاية
            for wp in road['waypoints']:
                dist = self.calculate_distance(to_lat, to_lon, wp['lat'], wp['lon'])
                if dist < end_min_dist:
                    end_min_dist = dist
                    end_road = road
        
        if not start_road or not end_road:
            return routes
        
        # توليد عدة مسارات مختلفة
        # المسار 1: مباشر عبر الطرق الرئيسية
        route1 = self._generate_direct_route(start_road, end_road, from_lat, from_lon, to_lat, to_lon)
        if route1:
            routes.append(route1)
        
        # المسار 2: عبر الطرق الفرعية (أطول لكن قد يكون أكثر أماناً)
        route2 = self._generate_secondary_route(start_road, end_road, from_lat, from_lon, to_lat, to_lon)
        if route2:
            routes.append(route2)
        
        # المسار 3: مختلط
        route3 = self._generate_mixed_route(start_road, end_road, from_lat, from_lon, to_lat, to_lon)
        if route3:
            routes.append(route3)
        
        # حساب safety_score لكل مسار
        for route in routes:
            cost = self.calculate_route_cost(route['waypoints'], from_lat, from_lon, to_lat, to_lon)
            
            # حساب ETA (افتراض سرعة متوسطة 50 كم/س)
            avg_speed_kmh = 50
            if cost['avg_fog'] > 70:
                avg_speed_kmh = 30  # تقليل السرعة في الضباب
            elif cost['avg_fog'] > 50:
                avg_speed_kmh = 40
            
            eta_minutes = (cost['length_m'] / 1000) / (avg_speed_kmh / 60)
            
            # حساب safety_score
            w1, w2, w3 = 0.5, 0.3, 0.2  # أوزان
            fog_score = (100 - cost['avg_fog']) * w1
            obstacles_penalty = max(0, (10 - cost['obstacles_count']) / 10 * 100) * w2
            eta_score = max(0, 100 - eta_minutes * 2) * w3
            
            safety_score = fog_score + obstacles_penalty + eta_score
            
            route.update({
                'fog_avg': round(cost['avg_fog'], 1),
                'obstacles_count': cost['obstacles_count'],
                'eta_minutes': round(eta_minutes, 1),
                'safety_score': round(safety_score, 1),
                'length_m': round(cost['length_m'], 1)
            })
        
        # ترتيب حسب safety_score
        routes.sort(key=lambda x: x['safety_score'], reverse=True)
        
        # إضافة route_id
        for i, route in enumerate(routes):
            route['route_id'] = i + 1
        
        return routes
    
    def _generate_direct_route(self, start_road, end_road, from_lat, from_lon, to_lat, to_lon):
        # توليد مسار مباشر
        waypoints = []
        
        # إضافة نقاط من start_road
        start_idx = self.find_nearest_waypoint(from_lat, from_lon, start_road)
        waypoints.extend(start_road['waypoints'][start_idx:])
        
        # إضافة نقاط من end_road
        end_idx = self.find_nearest_waypoint(to_lat, to_lon, end_road)
        waypoints.extend(end_road['waypoints'][:end_idx+1])
        
        return {'waypoints': waypoints} if waypoints else None
    
    def _generate_secondary_route(self, start_road, end_road, from_lat, from_lon, to_lat, to_lon):
        # توليد مسار عبر الطرق الفرعية
        secondary_roads = [r for r in self.road_network.roads if r['type'] == 'secondary']
        if not secondary_roads:
            return None
        
        waypoints = []
        waypoints.extend(start_road['waypoints'][:len(start_road['waypoints'])//2])
        
        # إضافة طريق فرعي
        if secondary_roads:
            waypoints.extend(secondary_roads[0]['waypoints'][::2])
        
        waypoints.extend(end_road['waypoints'][len(end_road['waypoints'])//2:])
        
        return {'waypoints': waypoints} if waypoints else None
    
    def _generate_mixed_route(self, start_road, end_road, from_lat, from_lon, to_lat, to_lon):
        # توليد مسار مختلط
        waypoints = []
        
        # جزء من start_road
        start_idx = self.find_nearest_waypoint(from_lat, from_lon, start_road)
        waypoints.extend(start_road['waypoints'][start_idx:start_idx+len(start_road['waypoints'])//2])
        
        # طريق آخر كجسر
        other_roads = [r for r in self.road_network.roads if r['id'] != start_road['id'] and r['id'] != end_road['id']]
        if other_roads:
            bridge_road = other_roads[0]
            waypoints.extend(bridge_road['waypoints'][::3])
        
        # جزء من end_road
        end_idx = self.find_nearest_waypoint(to_lat, to_lon, end_road)
        waypoints.extend(end_road['waypoints'][end_idx//2:end_idx+1])
        
        return {'waypoints': waypoints} if waypoints else None

class Analyzer:
    def __init__(self):
        self.rules_engine = RulesEngine()
    
    def analyze_situation(self, snapshot):
        # تحليل الوضع الحالي
        fog_level = snapshot.get('fog_level', 0)
        visibility = snapshot.get('visibility_m', 200)
        obstacles = snapshot.get('obstacles', [])
        vehicles = snapshot.get('vehicles', [])
        
        risk_level = self.rules_engine.evaluate_risk(fog_level, visibility, obstacles, vehicles)
        
        return {
            'risk_level': risk_level['level'],
            'severity': risk_level['severity'],
            'recommendations': risk_level['recommendations'],
            'analysis_timestamp': snapshot.get('timestamp')
        }
