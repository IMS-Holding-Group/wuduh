from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import sqlite3
from datetime import datetime, timedelta
import json
import threading
import time
import re
from werkzeug.security import generate_password_hash, check_password_hash
from itsdangerous import URLSafeTimedSerializer

from modules.radar_simulator import RadarSimulator
from modules.analyzer import Analyzer
from modules.rules_engine import RulesEngine

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = 'wuduh-secret-key-change-in-production'
token_serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])

DB_PATH = os.path.join(os.path.dirname(__file__), 'db', 'wuduh.sqlite')
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

radar_simulator = None
simulator_thread = None
current_location = {
    "city": "الباحة",
    "neighborhood": "شارع المطار",
    "latitude": 20.0129,
    "longitude": 41.4677
}

# Rate limiting بسيط للتسجيل
registration_attempts = {}
MAX_ATTEMPTS_PER_HOUR = 5

# تخزين بيانات IoT
iot_data = {
    'distance_cm': None,
    'timestamp': None
}

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            full_name TEXT,
            email TEXT,
            phone TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Drivers table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS drivers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER REFERENCES users(id),
            vehicle_make TEXT,
            vehicle_model TEXT,
            vehicle_plate TEXT,
            preferences_json TEXT
        )
    ''')
    
    # Saved locations
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS saved_locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER REFERENCES users(id),
            name TEXT,
            latitude REAL,
            longitude REAL,
            city TEXT,
            neighborhood TEXT
        )
    ''')
    
    # Alerts
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            type TEXT NOT NULL,
            severity TEXT NOT NULL,
            message TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            meta_json TEXT
        )
    ''')
    
    # Emergencies
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS emergencies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            user_id INTEGER,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            fog_level INTEGER NOT NULL,
            radar_snapshot_ref INTEGER
        )
    ''')
    
    # Obstacles
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS obstacles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            description TEXT,
            reported_by TEXT
        )
    ''')
    
    # Radar snapshots
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS radar_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TIMESTAMP,
            data_json TEXT NOT NULL
        )
    ''')
    
    # Insert dummy data if users table is empty
    cursor.execute('SELECT COUNT(*) FROM users')
    if cursor.fetchone()[0] == 0:
        # Insert test users
        users_data = [
            ('test_driver1', generate_password_hash('pass123'), 'محمد السائق', 'm1@example.com', '+966500000001'),
            ('test_driver2', generate_password_hash('pass123'), 'سارة السائق', 's2@example.com', '+966500000002'),
            ('test_driver3', generate_password_hash('pass123'), 'عبدالعزيز السائق', 'a3@example.com', '+966500000003'),
        ]
        cursor.executemany('''
            INSERT INTO users (username, password_hash, full_name, email, phone)
            VALUES (?, ?, ?, ?, ?)
        ''', users_data)
        
        # Insert drivers
        drivers_data = [
            (1, 'Toyota', 'Corolla', 'H12345', '{"auto_emergency":true,"alert_level":2}'),
            (2, 'Nissan', 'X-Trail', 'H54321', '{"auto_emergency":false,"alert_level":1}'),
            (3, 'Hyundai', 'Elantra', 'H98765', '{"auto_emergency":true,"alert_level":3}'),
        ]
        cursor.executemany('''
            INSERT INTO drivers (user_id, vehicle_make, vehicle_model, vehicle_plate, preferences_json)
            VALUES (?, ?, ?, ?, ?)
        ''', drivers_data)
        
        # Insert saved locations
        locations_data = [
            (1, 'البيت', 20.0129, 41.4677, 'الباحة', 'شارع المطار'),
            (1, 'العمل', 20.0200, 41.4700, 'الباحة', 'وسط الباحة'),
        ]
        cursor.executemany('''
            INSERT INTO saved_locations (user_id, name, latitude, longitude, city, neighborhood)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', locations_data)
    
    conn.commit()
    conn.close()

def start_simulator():
    global radar_simulator, simulator_thread
    if radar_simulator is None:
        radar_simulator = RadarSimulator(DB_PATH, current_location)
        simulator_thread = threading.Thread(target=radar_simulator.run, daemon=True)
        simulator_thread.start()

def verify_token(token):
    # التحقق من صحة التوكن
    try:
        data = token_serializer.loads(token, max_age=86400)
        return data.get('user_id')
    except:
        return None

def get_user_from_request():
    # الحصول على المستخدم من الطلب
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return None
    token = auth_header.split(' ')[1]
    user_id = verify_token(token)
    return user_id

@app.route('/api/v1/status', methods=['GET'])
def get_status():
    return jsonify({
        'status': 'running',
        'simulation_time': datetime.now().isoformat(),
        'location': current_location
    })

@app.route('/api/v1/sim/current', methods=['GET'])
def get_current_sim():
    if radar_simulator is None:
        start_simulator()
    
    snapshot = radar_simulator.get_current_snapshot()
    return jsonify(snapshot)

@app.route('/api/v1/sim/history', methods=['GET'])
def get_sim_history():
    seconds = request.args.get('seconds', 10, type=int)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT data_json FROM radar_snapshots 
        ORDER BY timestamp DESC LIMIT ?
    ''', (seconds,))
    
    rows = cursor.fetchall()
    conn.close()
    
    history = [json.loads(row[0]) for row in rows]
    return jsonify({'history': history})

@app.route('/api/v1/report/obstacle', methods=['POST'])
def report_obstacle():
    data = request.json
    timestamp = datetime.now().isoformat()
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO obstacles (timestamp, latitude, longitude, description, reported_by)
        VALUES (?, ?, ?, ?, ?)
    ''', (timestamp, data.get('latitude'), data.get('longitude'), 
          data.get('description', ''), data.get('reported_by', 'user')))
    
    obstacle_id = cursor.lastrowid
    
    alert_message = f"تم الإبلاغ عن عائق في الموقع: {data.get('description', 'عائق غير محدد')}"
    cursor.execute('''
        INSERT INTO alerts (timestamp, type, severity, message, latitude, longitude)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (timestamp, 'obstacle', 'medium', alert_message, 
          data.get('latitude'), data.get('longitude')))
    
    conn.commit()
    conn.close()
    
    return jsonify({
        'success': True,
        'obstacle_id': obstacle_id,
        'message': 'تم الإبلاغ عن العائق بنجاح'
    })

@app.route('/api/v1/route/compute', methods=['POST'])
def compute_route():
    data = request.json
    from_point = data.get('from', {})
    to_point = data.get('to', {})
    
    if not radar_simulator:
        start_simulator()
    
    from_lat = from_point.get('lat', current_location['latitude'])
    from_lon = from_point.get('lon', current_location['longitude'])
    to_lat = to_point.get('lat', current_location['latitude'])
    to_lon = to_point.get('lon', current_location['longitude'])
    
    snapshot = radar_simulator.get_current_snapshot()
    obstacles = snapshot.get('obstacles', [])
    fog_level = snapshot.get('fog_level', 0)
    
    from modules.analyzer import RouteAnalyzer
    analyzer = RouteAnalyzer(radar_simulator.road_network, obstacles, fog_level)
    routes = analyzer.compute_routes(from_lat, from_lon, to_lat, to_lon)
    
    return jsonify({
        'success': True,
        'routes': routes
    })

@app.route('/api/v1/route/live/<int:route_id>', methods=['GET'])
def get_live_route(route_id):
    if not radar_simulator:
        start_simulator()
    
    snapshot = radar_simulator.get_current_snapshot()
    
    # محاكاة موقع المركبة على المسار (مبسط)
    return jsonify({
        'route_id': route_id,
        'current_position': {
            'lat': current_location['latitude'],
            'lon': current_location['longitude']
        },
        'fog_updates': {
            'current_level': snapshot.get('fog_level', 0),
            'visibility': snapshot.get('visibility_m', 200)
        },
        'obstacles_on_route': [
            obs for obs in snapshot.get('obstacles', [])
            if obs.get('distance_from_center', 9999) < 500
        ],
        'recommendation': 'استمر في المسار' if snapshot.get('fog_level', 0) < 70 else 'فكر في تغيير المسار'
    })

@app.route('/api/v1/emergency/call', methods=['POST'])
def emergency_call():
    data = request.json
    timestamp = datetime.now().isoformat()
    user_id = data.get('user_id')
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # الحصول على آخر 10 ثوانٍ من radar_snapshots
    cursor.execute('''
        SELECT data_json FROM radar_snapshots 
        ORDER BY timestamp DESC LIMIT 10
    ''')
    snapshots = [json.loads(row[0]) for row in cursor.fetchall()]
    
    snapshot_ref = None
    if radar_simulator:
        current_snap = radar_simulator.get_current_snapshot()
        if current_snap:
            cursor.execute('''
                INSERT INTO radar_snapshots (timestamp, data_json)
                VALUES (?, ?)
            ''', (timestamp, json.dumps(current_snap)))
            snapshot_ref = cursor.lastrowid
    
    cursor.execute('''
        INSERT INTO emergencies (timestamp, user_id, latitude, longitude, fog_level, radar_snapshot_ref)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (timestamp, user_id, data.get('lat', data.get('latitude')), 
          data.get('lon', data.get('longitude')), data.get('fog_level', 0), snapshot_ref))
    
    emergency_id = cursor.lastrowid
    
    cursor.execute('''
        INSERT INTO alerts (timestamp, type, severity, message, latitude, longitude)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (timestamp, 'emergency', 'high', 'نداء طوارئ', 
          data.get('lat', data.get('latitude')), data.get('lon', data.get('longitude'))))
    
    conn.commit()
    conn.close()
    
    return jsonify({
        'success': True,
        'emergency_id': emergency_id,
        'message': 'تم استقبال نداء الطوارئ',
        'radar_snapshots': snapshots
    })

@app.route('/api/v1/alerts', methods=['GET'])
def get_alerts():
    severity_filter = request.args.get('severity', None)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    if severity_filter:
        cursor.execute('''
            SELECT id, timestamp, type, severity, message, latitude, longitude, meta_json
            FROM alerts
            WHERE severity = ?
            ORDER BY timestamp DESC
            LIMIT 50
        ''', (severity_filter,))
    else:
        cursor.execute('''
            SELECT id, timestamp, type, severity, message, latitude, longitude, meta_json
            FROM alerts
            ORDER BY timestamp DESC
            LIMIT 50
        ''')
    
    alerts = []
    for row in cursor.fetchall():
        alerts.append({
            'id': row[0],
            'timestamp': row[1],
            'type': row[2],
            'severity': row[3],
            'message': row[4],
            'latitude': row[5],
            'longitude': row[6],
            'meta_json': json.loads(row[7]) if row[7] else {}
        })
    
    conn.close()
    
    return jsonify({'alerts': alerts})

# Authentication endpoints
def validate_username(username):
    # التحقق من اسم المستخدم: 3-20 حرف، أحرف وأرقام فقط
    if not username or len(username) < 3 or len(username) > 20:
        return False, 'اسم المستخدم يجب أن يكون بين 3 و 20 حرف'
    if not re.match(r'^[a-zA-Z0-9_]+$', username):
        return False, 'اسم المستخدم يمكن أن يحتوي على أحرف إنجليزية وأرقام و _ فقط'
    return True, None

def validate_password(password):
    # التحقق من كلمة المرور: 6 أحرف على الأقل
    if not password or len(password) < 6:
        return False, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
    if len(password) > 100:
        return False, 'كلمة المرور طويلة جداً'
    return True, None

def validate_email(email):
    # التحقق من البريد الإلكتروني
    if email and len(email) > 0:
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, email):
            return False, 'البريد الإلكتروني غير صحيح'
    return True, None

def check_rate_limit(ip_address):
    # Rate limiting بسيط
    now = datetime.now()
    if ip_address in registration_attempts:
        attempts = [t for t in registration_attempts[ip_address] if (now - t).total_seconds() < 3600]
        if len(attempts) >= MAX_ATTEMPTS_PER_HOUR:
            return False
        registration_attempts[ip_address] = attempts
    else:
        registration_attempts[ip_address] = []
    registration_attempts[ip_address].append(now)
    return True

@app.route('/api/v1/auth/register', methods=['POST'])
def register():
    try:
        # Rate limiting
        client_ip = request.remote_addr
        if not check_rate_limit(client_ip):
            return jsonify({'success': False, 'error': 'تم تجاوز عدد المحاولات المسموح به. حاول مرة أخرى لاحقاً'}), 429
        
        if not request.is_json:
            return jsonify({'success': False, 'error': 'يجب إرسال البيانات بصيغة JSON'}), 400
        
        data = request.json
        if not data:
            return jsonify({'success': False, 'error': 'لا توجد بيانات'}), 400
        
        username = data.get('username', '').strip()
        password = data.get('password', '')
        email = data.get('email', '').strip() if data.get('email') else ''
        
        # التحقق من اسم المستخدم
        valid, error = validate_username(username)
        if not valid:
            return jsonify({'success': False, 'error': error}), 400
        
        # التحقق من كلمة المرور
        valid, error = validate_password(password)
        if not valid:
            return jsonify({'success': False, 'error': error}), 400
        
        # التحقق من البريد الإلكتروني
        if email:
            valid, error = validate_email(email)
            if not valid:
                return jsonify({'success': False, 'error': error}), 400
        
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        try:
            password_hash = generate_password_hash(password)
            cursor.execute('''
                INSERT INTO users (username, password_hash, full_name, email, phone)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                username,
                password_hash,
                data.get('full_name', '').strip() if data.get('full_name') else '',
                email,
                data.get('phone', '').strip() if data.get('phone') else ''
            ))
            user_id = cursor.lastrowid
            
            # إنشاء سجل سائق افتراضي
            cursor.execute('''
                INSERT INTO drivers (user_id, vehicle_make, vehicle_model, vehicle_plate, preferences_json)
                VALUES (?, ?, ?, ?, ?)
            ''', (user_id, '', '', '', '{"auto_emergency":false,"alert_level":1}'))
            
            conn.commit()
            token = token_serializer.dumps({'user_id': user_id})
            
            return jsonify({
                'success': True,
                'user_id': user_id,
                'token': token
            })
        except sqlite3.IntegrityError:
            conn.rollback()
            return jsonify({'success': False, 'error': 'اسم المستخدم موجود بالفعل'}), 400
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'error': f'خطأ في قاعدة البيانات: {str(e)}'}), 500
        finally:
            conn.close()
    except Exception as e:
        return jsonify({'success': False, 'error': f'خطأ في الخادم: {str(e)}'}), 500

@app.route('/api/v1/auth/login', methods=['POST'])
def login():
    try:
        if not request.is_json:
            return jsonify({'success': False, 'error': 'يجب إرسال البيانات بصيغة JSON'}), 400
        
        data = request.json
        if not data:
            return jsonify({'success': False, 'error': 'لا توجد بيانات'}), 400
        
        if not data.get('username') or not data.get('password'):
            return jsonify({'success': False, 'error': 'اسم المستخدم وكلمة المرور مطلوبان'}), 400
        
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('SELECT id, password_hash FROM users WHERE username = ?', (data.get('username'),))
        user = cursor.fetchone()
        conn.close()
        
        if user and check_password_hash(user[1], data.get('password', '')):
            token = token_serializer.dumps({'user_id': user[0]})
            return jsonify({
                'success': True,
                'user_id': user[0],
                'token': token
            })
        else:
            return jsonify({'success': False, 'error': 'اسم المستخدم أو كلمة المرور غير صحيحة'}), 401
    except Exception as e:
        return jsonify({'success': False, 'error': f'خطأ في الخادم: {str(e)}'}), 500

@app.route('/api/v1/user/me', methods=['GET'])
def get_user_me():
    user_id = get_user_from_request()
    if not user_id:
        return jsonify({'error': 'غير مصرح'}), 401
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('SELECT id, username, full_name, email, phone FROM users WHERE id = ?', (user_id,))
    user = cursor.fetchone()
    
    cursor.execute('SELECT vehicle_make, vehicle_model, vehicle_plate, preferences_json FROM drivers WHERE user_id = ?', (user_id,))
    driver = cursor.fetchone()
    
    cursor.execute('SELECT id, name, latitude, longitude, city, neighborhood FROM saved_locations WHERE user_id = ?', (user_id,))
    locations = cursor.fetchall()
    
    conn.close()
    
    if not user:
        return jsonify({'error': 'المستخدم غير موجود'}), 404
    
    return jsonify({
        'user': {
            'id': user[0],
            'username': user[1],
            'full_name': user[2],
            'email': user[3],
            'phone': user[4]
        },
        'driver': {
            'vehicle_make': driver[0] if driver else '',
            'vehicle_model': driver[1] if driver else '',
            'vehicle_plate': driver[2] if driver else '',
            'preferences': json.loads(driver[3]) if driver and driver[3] else {}
        },
        'saved_locations': [
            {
                'id': loc[0],
                'name': loc[1],
                'latitude': loc[2],
                'longitude': loc[3],
                'city': loc[4],
                'neighborhood': loc[5]
            }
            for loc in locations
        ]
    })

@app.route('/api/v1/user/saved_location', methods=['POST'])
def add_saved_location():
    user_id = get_user_from_request()
    if not user_id:
        return jsonify({'error': 'غير مصرح'}), 401
    
    data = request.json
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO saved_locations (user_id, name, latitude, longitude, city, neighborhood)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (
        user_id,
        data.get('name'),
        data.get('lat'),
        data.get('lon'),
        data.get('city', ''),
        data.get('neighborhood', '')
    ))
    
    conn.commit()
    conn.close()
    
    return jsonify({'success': True, 'location_id': cursor.lastrowid})

@app.route('/api/v1/config/location', methods=['POST'])
def set_location():
    global current_location, radar_simulator
    data = request.json
    
    current_location = {
        'city': data.get('city', 'الباحة'),
        'neighborhood': data.get('neighborhood', 'شارع المطار'),
        'latitude': data.get('center_lat', data.get('latitude', 20.0129)),
        'longitude': data.get('center_lon', data.get('longitude', 41.4677))
    }
    
    if radar_simulator:
        radar_simulator.update_location(current_location)
    
    return jsonify({
        'success': True,
        'location': current_location
    })

@app.route('/api/v1/routes', methods=['GET'])
def list_routes():
    # قائمة بجميع الـ routes المتاحة (للتطوير فقط)
    routes = []
    for rule in app.url_map.iter_rules():
        routes.append({
            'endpoint': rule.endpoint,
            'methods': list(rule.methods),
            'path': str(rule)
        })
    return jsonify({'routes': routes})

# IoT Endpoints
@app.route('/api/v1/iot/update', methods=['POST'])
def iot_update():
    # استقبال بيانات المسافة من الحساس
    try:
        if not request.is_json:
            return jsonify({'success': False, 'error': 'يجب إرسال البيانات بصيغة JSON'}), 400
        
        data = request.json
        if not data:
            return jsonify({'success': False, 'error': 'لا توجد بيانات'}), 400
        
        distance_cm = data.get('distance_cm')
        if distance_cm is None:
            return jsonify({'success': False, 'error': 'distance_cm مطلوب'}), 400
        
        # التحقق من أن distance_cm رقم
        try:
            distance_cm = float(distance_cm)
            if distance_cm < 0:
                return jsonify({'success': False, 'error': 'المسافة يجب أن تكون قيمة موجبة'}), 400
        except (ValueError, TypeError):
            return jsonify({'success': False, 'error': 'distance_cm يجب أن يكون رقماً'}), 400
        
        # حفظ البيانات
        global iot_data
        iot_data['distance_cm'] = distance_cm
        iot_data['timestamp'] = datetime.now().isoformat()
        
        return jsonify({
            'success': True,
            'message': 'تم تحديث البيانات بنجاح',
            'distance_cm': distance_cm,
            'timestamp': iot_data['timestamp']
        })
    except Exception as e:
        return jsonify({'success': False, 'error': f'خطأ في الخادم: {str(e)}'}), 500

@app.route('/api/v1/iot/latest', methods=['GET'])
def iot_latest():
    # إرجاع آخر قراءة للمسافة
    global iot_data
    
    if iot_data['distance_cm'] is None:
        return jsonify({
            'success': False,
            'error': 'لا توجد بيانات متاحة',
            'distance_cm': None
        }), 404
    
    return jsonify({
        'success': True,
        'distance_cm': iot_data['distance_cm'],
        'timestamp': iot_data['timestamp']
    })

if __name__ == '__main__':
    init_db()
    start_simulator()
    print("=" * 50)
    print("وضوح Backend Server")
    print("=" * 50)
    print("الخادم يعمل على: http://127.0.0.1:5000")
    print("API Endpoints المتاحة:")
    print("  - POST /api/v1/auth/register")
    print("  - POST /api/v1/auth/login")
    print("  - GET  /api/v1/user/me")
    print("  - GET  /api/v1/status")
    print("  - GET  /api/v1/sim/current")
    print("  - POST /api/v1/iot/update")
    print("  - GET  /api/v1/iot/latest")
    print("  - GET  /api/v1/routes (للتطوير)")
    print("=" * 50)
    app.run(host='127.0.0.1', port=5000, debug=True)

