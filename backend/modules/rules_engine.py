import math

class RulesEngine:
    def __init__(self):
        self.rules = [
            {
                'condition': lambda f, v, o, ve, t=None: f >= 80 or v <= 30,
                'severity': 'high',
                'level': 'critical',
                'recommendations': ['توقف فوراً', 'استخدم الأضواء التحذيرية', 'اتصل بالطوارئ إذا لزم الأمر'],
                'alert_message': 'ضباب كثيف جداً - الرؤية خطيرة'
            },
            {
                'condition': lambda f, v, o, ve, t=None: f > 60 and v < 50,
                'severity': 'medium',
                'level': 'warning',
                'recommendations': ['قلل السرعة', 'استخدم الأضواء الأمامية', 'احذر من العوائق'],
                'alert_message': 'ضباب متوسط - انتبه للقيادة'
            },
            {
                'condition': lambda f, v, o, ve, t=None: len([obs for obs in o if obs.get('severity') == 'high' and obs.get('distance_from_center', 9999) <= 100]) > 0,
                'severity': 'high',
                'level': 'warning',
                'recommendations': ['تجنب المنطقة', 'ابحث عن مسار بديل', 'كن حذراً'],
                'alert_message': 'عائق خطير قريب'
            },
            {
                'condition': lambda f, v, o, ve, t=None: len([v for v in ve if v.get('speed', 0) > 100 and v.get('distance_from_center', 9999) <= 200]) > 3,
                'severity': 'medium',
                'level': 'caution',
                'recommendations': ['احذر من المركبات السريعة', 'حافظ على مسافة آمنة'],
                'alert_message': 'مركبات سريعة قريبة'
            },
            {
                'condition': lambda f, v, o, ve, t=None: t is not None and t <= 3 and f > 40,
                'severity': 'high',
                'level': 'warning',
                'recommendations': ['انتبه للانزلاق', 'الطريق زلق', 'قلل السرعة'],
                'alert_message': 'ظروف انزلاق محتملة'
            },
            {
                'condition': lambda f, v, o, ve, t=None: f < 30 and v > 100,
                'severity': 'low',
                'level': 'normal',
                'recommendations': ['الظروف جيدة', 'استمر بحذر'],
                'alert_message': 'الظروف طبيعية'
            }
        ]
    
    def evaluate_risk(self, fog_level, visibility, obstacles, vehicles, temperature=None):
        # تقييم مستوى الخطر
        for rule in self.rules:
            try:
                if rule['condition'](fog_level, visibility, obstacles, vehicles, temperature):
                    return {
                        'level': rule['level'],
                        'severity': rule['severity'],
                        'recommendations': rule['recommendations'],
                        'alert_message': rule.get('alert_message', 'تنبيه')
                    }
            except Exception as e:
                continue
        
        return {
            'level': 'normal',
            'severity': 'low',
            'recommendations': ['الظروف طبيعية', 'استمر بحذر'],
            'alert_message': 'لا توجد تنبيهات'
        }
    
    def generate_alert(self, snapshot, user_position):
        # توليد تنبيه بناءً على القواعد
        fog_level = snapshot.get('fog_level', 0)
        visibility = snapshot.get('visibility_m', 200)
        obstacles = snapshot.get('obstacles', [])
        vehicles = snapshot.get('vehicles', [])
        temperature = snapshot.get('temperature_c')
        
        user_lat = user_position.get('lat', 0)
        user_lon = user_position.get('lon', 0)
        
        # تقييم الخطر
        risk = self.evaluate_risk(fog_level, visibility, obstacles, vehicles, temperature)
        
        # البحث عن عوائق قريبة
        nearby_obstacles = []
        for obs in obstacles:
            dist = self._calculate_distance(
                user_lat, user_lon,
                obs.get('lat', 0), obs.get('lon', 0)
            )
            if dist <= 200:  # ضمن 200 متر
                nearby_obstacles.append({
                    'obstacle': obs,
                    'distance': dist,
                    'confidence': min(100, 50 + (200 - dist) / 2)
                })
        
        alerts = []
        
        # تنبيه عام
        if risk['severity'] != 'low':
            alerts.append({
                'type': 'general',
                'severity': risk['severity'],
                'message': risk['alert_message'],
                'recommendations': risk['recommendations'],
                'latitude': user_lat,
                'longitude': user_lon,
                'meta_json': {
                    'fog_level': fog_level,
                    'visibility': visibility,
                    'risk_level': risk['level']
                }
            })
        
        # تنبيهات العوائق القريبة
        for nearby in nearby_obstacles:
            obs = nearby['obstacle']
            alerts.append({
                'type': 'obstacle',
                'severity': obs.get('severity', 'medium'),
                'message': f"عائق {obs.get('type', 'غير محدد')} بعد {int(nearby['distance'])}م",
                'latitude': obs.get('lat', user_lat),
                'longitude': obs.get('lon', user_lon),
                'meta_json': {
                    'obstacle_id': obs.get('id'),
                    'distance_m': int(nearby['distance']),
                    'confidence': nearby['confidence'],
                    'type': obs.get('type')
                }
            })
        
        return alerts
    
    def _calculate_distance(self, lat1, lon1, lat2, lon2):
        # حساب المسافة بالأمتار
        R = 6371000
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c
