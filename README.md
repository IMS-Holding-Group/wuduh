# وضوح (Wuduh) - دليل بناء المشروع

## 📋 ما هو المشروع؟

تطبيق جوال يساعد السائقين في الضباب. يتكون من:
- **Flutter App** (الواجهة) - مكتوب بـ Dart
- **Flask Server** (الخادم) - مكتوب بـ Python
- **SQLite Database** (قاعدة البيانات) - ملف محلي

---

## 🎓 شرح التقنيات المستخدمة (للمبتدئين جداً)

### ما هو Flutter؟ 🎨

**ببساطة**: Flutter هو أداة لصنع تطبيقات الجوال.

**التشبيه**: 
تخيل أنك تريد بناء بيت. Flutter يعطيك:
- الطوب (Widgets)
- الأدوات (الأوامر)
- التصميم (الألوان والخطوط)

**مثال بسيط**:
```dart
Text('مرحباً')  // هذا نص
```

هذا السطر يظهر كلمة "مرحباً" على الشاشة.

**لماذا Flutter؟**
- كود واحد يعمل على Android و iOS
- سريع وسهل
- واجهة جميلة

**ما الذي تحتاجه؟**
- لغة Dart (سهلة جداً)
- Flutter SDK (مجاني)

---

### ما هو Flask؟ 🐍

**ببساطة**: Flask هو أداة لصنع خادم (Server).

**التشبيه**:
تخيل مطعم:
- **Flask** = المطعم (الخادم)
- **الطاولات** = الـ Routes (العناوين)
- **الطاهي** = الكود الذي يعالج الطلبات
- **الزبون** = التطبيق (Flutter)

**مثال بسيط**:
```python
@app.route('/api/hello')
def hello():
    return 'مرحباً'
```

**شرح السطور**:
- السطر 1: "عندما يأتي شخص إلى `/api/hello`"
- السطر 2: "نفذ دالة `hello`"
- السطر 3: "أرسل له كلمة 'مرحباً'"

**كيف يعمل؟**
1. التطبيق يطلب: "أريد بيانات الطقس"
2. Flask يستقبل الطلب
3. Flask يعالج الطلب
4. Flask يرسل البيانات

**لماذا Flask؟**
- بسيط جداً
- سهل التعلم
- مناسب للمشاريع الصغيرة

**ما الذي تحتاجه؟**
- Python (مثبت مسبقاً على معظم الأجهزة)
- مكتبة Flask (نثبتها بـ `pip install flask`)

---

### ما هو SQLite؟ 💾

**ببساطة**: SQLite هي قاعدة بيانات (مكان تخزين البيانات).

**التشبيه**:
تخيل دفتر ملاحظات:
- **SQLite** = الدفتر
- **الصفحات** = الجداول (Tables)
- **السطور** = البيانات (Rows)
- **الأعمدة** = الحقول (Columns)

**مثال بسيط**:

**الجدول** (مثل صفحة في الدفتر):
```
| id | name    | age |
|----|---------|-----|
| 1  | أحمد    | 25  |
| 2  | سارة    | 30  |
```

**الكود**:
```python
# إضافة بيانات
INSERT INTO users (name, age) VALUES ('أحمد', 25)

# قراءة البيانات
SELECT * FROM users WHERE name = 'أحمد'
```

**شرح**:
- `INSERT` = أضف
- `SELECT` = اقرأ
- `WHERE` = بشرط

**لماذا SQLite؟**
- لا تحتاج خادم منفصل
- الملف موجود على جهازك
- سريعة وخفيفة
- سهلة الاستخدام

**ما الذي تحتاجه؟**
- Python (يأتي مع SQLite مدمج)
- لا حاجة لتثبيت شيء إضافي!

---

### ما هو Python؟ 🐍

**ببساطة**: Python هي لغة برمجة سهلة جداً.

**التشبيه**:
تخيل أنك تكتب قائمة تسوق:
```python
قائمة_الخضار = ['طماطم', 'خيار', 'بصل']
```

هذا الكود يخزن قائمة خضار!

**مثال بسيط**:
```python
# متغير (Variable)
الاسم = 'أحمد'
العمر = 25

# طباعة
print(f'اسمي {الاسم} وعمري {العمر}')
```

**النتيجة**: `اسمي أحمد وعمري 25`

**لماذا Python؟**
- سهلة جداً (مثل اللغة الإنجليزية)
- لا تحتاج أقواس معقدة
- مناسبة للمبتدئين

**ما الذي تحتاجه؟**
- Python 3.10.6 (أو أي إصدار 3.x)
- محرر نصوص (VS Code)

---

### ما هو Dart؟ 🎯

**ببساطة**: Dart هي لغة برمجة من Google لصنع تطبيقات Flutter.

**التشبيه**:
Dart مثل Python لكن لصنع تطبيقات الجوال.

**مثال بسيط**:
```dart
// متغير
String name = 'أحمد';
int age = 25;

// طباعة
print('اسمي $name وعمري $age');
```

**الفرق بين Python و Dart**:
- **Python**: للخوادم والبرامج
- **Dart**: لتطبيقات الجوال

**لماذا Dart؟**
- سهلة التعلم
- سريعة
- مناسبة لـ Flutter

**ما الذي تحتاجه؟**
- Flutter SDK (يأتي مع Dart)
- لا حاجة لتثبيت Dart منفصلاً

---

### ما هو HTTP؟ 🌐

**ببساطة**: HTTP هو طريقة التواصل بين التطبيق والخادم.

**التشبيه**:
تخيل الهاتف:
- **التطبيق** = أنت (تطلب)
- **HTTP** = الهاتف (الوسيلة)
- **الخادم** = صديقك (يرد)

**أنواع الطلبات**:
1. **GET** = "أعطني بيانات" (مثل: أريد بيانات الطقس)
2. **POST** = "احفظ بيانات" (مثل: سجل مستخدم جديد)
3. **PUT** = "عدّل بيانات" (مثل: غيّر الاسم)
4. **DELETE** = "احذف بيانات" (مثل: احذف المستخدم)

**مثال**:
```
التطبيق: GET /api/v1/weather
الخادم: {temp: 25, fog: 45}
```

**شرح**:
- `GET` = نوع الطلب (أريد قراءة)
- `/api/v1/weather` = العنوان (أين البيانات)
- `{temp: 25, fog: 45}` = البيانات المرسلة

---

### ما هو JSON? 📄

**ببساطة**: JSON هو طريقة لكتابة البيانات بشكل منظم.

**التشبيه**:
مثل قائمة في المطعم:
```json
{
  "الطبق": "بيتزا",
  "السعر": 50,
  "الحجم": "كبير"
}
```

**مثال بسيط**:
```json
{
  "name": "أحمد",
  "age": 25,
  "city": "الرياض"
}
```

**الفرق بين JSON والنص العادي**:
- **النص العادي**: `أحمد 25 الرياض` (غير منظم)
- **JSON**: `{"name":"أحمد","age":25}` (منظم)

**لماذا JSON؟**
- سهل القراءة
- سهل الكتابة
- يفهمه جميع اللغات

---

### ما هو API؟ 🔌

**ببساطة**: API هي طريقة للتطبيق للتواصل مع الخادم.

**التشبيه**:
تخيل مطعم:
- **القائمة** = API (ما يمكن طلبه)
- **الطاهي** = الخادم (يعمل الطلب)
- **الزبون** = التطبيق (يطلب)

**مثال**:
```
التطبيق: "أريد بيانات الطقس"
API: "/api/v1/weather"
الخادم: "ها هي: {temp: 25}"
```

**كيف يعمل؟**
1. التطبيق يطلب من API
2. API يرسل الطلب للخادم
3. الخادم يعالج ويعيد البيانات
4. API يرسل البيانات للتطبيق

**مثال حقيقي**:
```python
# في Flask (الخادم)
@app.route('/api/v1/weather')
def get_weather():
    return {'temp': 25, 'fog': 45}
```

```dart
// في Flutter (التطبيق)
final response = await http.get('http://127.0.0.1:5000/api/v1/weather');
print(response.body); // {'temp': 25, 'fog': 45}
```

---

### ما هو Widget في Flutter? 🧩

**ببساطة**: Widget هو قطعة من الواجهة.

**التشبيه**:
مثل قطع الليغو:
- كل قطعة = Widget
- تجمع القطع = واجهة كاملة

**أمثلة Widgets**:
```dart
Text('مرحباً')           // نص
Icon(Icons.home)         // أيقونة
Button(...)              // زر
Card(...)                // بطاقة
```

**كيف تجمعها؟**
```dart
Column(                  // عمود (من أعلى لأسفل)
  children: [
    Text('الاسم'),
    Text('العمر'),
    Button('حفظ'),
  ],
)
```

**النتيجة**:
```
الاسم
العمر
[زر حفظ]
```

---

### ما هو State (الحالة) في Flutter? 🔄

**ببساطة**: State هي البيانات التي تتغير.

**التشبيه**:
مثل عداد السرعة في السيارة:
- الرقم يتغير = State
- الشاشة تظهر الرقم = Widget

**مثال بسيط**:
```dart
int _count = 0;  // هذا State (يتغير)

void _increment() {
  setState(() {
    _count++;  // زيادة العدد
  });
}
```

**شرح**:
- `_count` = المتغير (State)
- `setState()` = "حدّث الواجهة"
- `_count++` = "زِد العدد"

**الفرق**:
- **StatelessWidget**: لا يتغير (مثل صورة)
- **StatefulWidget**: يتغير (مثل عداد)

---

### ما هو Database (قاعدة البيانات)? 💾

**ببساطة**: قاعدة البيانات هي مكان تخزين البيانات بشكل منظم.

**التشبيه**:
مثل خزانة ملفات:
- **الخزانة** = Database
- **الأدراج** = Tables (الجداول)
- **الملفات** = Rows (الصفوف)
- **المعلومات في الملف** = Columns (الأعمدة)

**مثال**:
```
الخزانة: قاعدة_البيانات
  ├─ درج: المستخدمون
  │   ├─ ملف: أحمد (id: 1, name: أحمد, age: 25)
  │   └─ ملف: سارة (id: 2, name: سارة, age: 30)
  └─ درج: الطلبات
      └─ ملف: طلب_1 (...)
```

**الكود**:
```python
# إنشاء جدول
CREATE TABLE users (
    id INTEGER,
    name TEXT,
    age INTEGER
)

# إضافة بيانات
INSERT INTO users (name, age) VALUES ('أحمد', 25)

# قراءة بيانات
SELECT * FROM users WHERE name = 'أحمد'
```

---

### ما هو Server (الخادم)? 🖥️

**ببساطة**: الخادم هو جهاز كمبيوتر يعمل 24/7 ويستقبل الطلبات.

**التشبيه**:
مثل موظف استقبال في فندق:
- **الخادم** = موظف الاستقبال
- **الطلبات** = طلبات النزلاء
- **الردود** = المعلومات المطلوبة

**كيف يعمل؟**
```
التطبيق: "أريد بيانات الطقس"
    ↓
الخادم: "انتظر... أحسب..."
    ↓
الخادم: "ها هي: {temp: 25}"
    ↓
التطبيق: "شكراً!"
```

**في مشروعنا**:
- الخادم = Flask (يعمل على جهازك)
- العنوان = `127.0.0.1:5000`
- الطلبات = HTTP Requests

---

### ما هو Client (العميل)? 📱

**ببساطة**: العميل هو التطبيق الذي يطلب البيانات.

**التشبيه**:
مثل الزبون في المطعم:
- **العميل** = أنت (تطلب)
- **الخادم** = المطعم (يعمل الطلب)

**في مشروعنا**:
- العميل = Flutter App
- يطلب من الخادم
- يستقبل البيانات
- يعرضها للمستخدم

---

### الخلاصة السريعة 📝

| التقنية | ما هي؟ | لماذا؟ |
|---------|--------|--------|
| **Flutter** | أداة صنع تطبيقات | كود واحد لجميع المنصات |
| **Flask** | أداة صنع خادم | بسيط وسهل |
| **SQLite** | قاعدة بيانات | لا تحتاج خادم منفصل |
| **Python** | لغة برمجة | سهلة جداً |
| **Dart** | لغة برمجة | لـ Flutter |
| **HTTP** | طريقة التواصل | معيار عالمي |
| **JSON** | تنسيق البيانات | سهل ومنظم |
| **API** | واجهة التواصل | يربط التطبيق بالخادم |

---

**💡 نصيحة**: ابدأ بفهم Python و Flutter، ثم انتقل للباقي تدريجياً!

---

## 🏗️ هيكل المشروع

```
wuduh/
├── flutter_app/          # تطبيق Flutter
│   ├── lib/
│   │   ├── main.dart                    # نقطة البداية
│   │   ├── src/
│   │   │   ├── ui/screens/             # الشاشات
│   │   │   ├── ui/widgets/             # المكونات
│   │   │   ├── services/               # خدمات API
│   │   │   └── models/                 # نماذج البيانات
│   │   └── themes/                     # الألوان والثيم
│   ├── assets/fonts/                   # الخطوط
│   └── web/                            # ملفات الويب
│
└── backend/             # خادم Flask
    ├── app.py                          # الملف الرئيسي
    ├── modules/
    │   ├── radar_simulator.py          # محاكاة الرادار
    │   ├── analyzer.py                 # تحليل المسارات
    │   └── rules_engine.py             # قواعد التنبيهات
    └── db/wuduh.sqlite                 # قاعدة البيانات
```

---

## 🚀 البناء خطوة بخطوة

### الخطوة 1: إعداد Backend

#### 1.1 الانتقال إلى مجلد Backend

```bash
cd C:\Users\TRSI\VSCode\Projects\flutterprojects\wuduh\backend
```

#### 1.2 تثبيت المكتبات

```bash
pip install -r requirements.txt
```

**ما الذي يحدث؟**
- يقرأ ملف `requirements.txt`
- يثبت: Flask, flask-cors, Werkzeug, itsdangerous

#### 1.3 تشغيل الخادم

```bash
python app.py
```

**النتيجة المتوقعة:**
```
==================================================
وضوح Backend Server
==================================================
الخادم يعمل على: http://127.0.0.1:5000
==================================================
```

**⚠️ اترك هذه النافذة مفتوحة!**

---

### الخطوة 2: إعداد Flutter App

#### 2.1 الانتقال إلى مجلد التطبيق

```bash
cd C:\Users\TRSI\VSCode\Projects\flutterprojects\wuduh\flutter_app
```

#### 2.2 تثبيت الحزم

```bash
flutter pub get
```

#### 2.3 تشغيل التطبيق

```bash
flutter run
```

---

## 📁 شرح الملفات الرئيسية

### Backend Files

#### `backend/app.py` - الملف الرئيسي للخادم

**ما يفعله:**
- ينشئ خادم Flask
- يعرّف جميع واجهات API
- يدير قاعدة البيانات

**الكود الأساسي:**

```python
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # يسمح بالاتصال من التطبيق

# مثال: واجهة بسيطة
@app.route('/api/v1/status', methods=['GET'])
def get_status():
    return jsonify({
        'status': 'running',
        'time': datetime.now().isoformat()
    })

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
```

**شرح الكود:**
- `Flask(__name__)` - ينشئ تطبيق Flask
- `CORS(app)` - يسمح للتطبيق بالاتصال
- `@app.route()` - يعرّف عنوان URL
- `jsonify()` - يحول البيانات إلى JSON

#### `backend/modules/radar_simulator.py` - محاكاة الرادار

**ما يفعله:**
- يولد بيانات الضباب والطقس
- يحاكي حركة المركبات
- يولد العوائق

**مثال الكود:**

```python
class RadarSimulator:
    def __init__(self, db_path, location):
        self.fog_level = 30.0  # مستوى الضباب
        self.temperature = 25.0  # درجة الحرارة
        self.vehicles = []  # قائمة المركبات
        
    def _update_weather(self):
        # تحديث الطقس كل ثانية
        self.fog_level = max(0, min(100, 
            self.fog_level + random.uniform(-5, 5)))
        
    def get_current_snapshot(self):
        # إرجاع البيانات الحالية
        return {
            'fog_level': self.fog_level,
            'temperature': self.temperature,
            'vehicles': self.vehicles
        }
```

**شرح الكود:**
- `__init__` - دالة البناء (تُنفذ عند إنشاء الكائن)
- `_update_weather()` - تحديث بيانات الطقس
- `get_current_snapshot()` - إرجاع البيانات الحالية

#### `backend/modules/analyzer.py` - تحليل المسارات

**ما يفعله:**
- يحسب المسارات من نقطة إلى أخرى
- يقيم مستوى الأمان لكل مسار

**مثال الكود:**

```python
def compute_routes(self, from_lat, from_lon, to_lat, to_lon):
    routes = []
    
    # حساب المسار الأول
    route1 = self._generate_direct_route(...)
    routes.append(route1)
    
    # حساب safety_score
    for route in routes:
        fog_score = (100 - route['fog_avg']) * 0.5
        obstacles_score = (10 - route['obstacles_count']) * 0.3
        route['safety_score'] = fog_score + obstacles_score
    
    return routes
```

**شرح الكود:**
- `compute_routes()` - يحسب المسارات
- `safety_score` - نقاط الأمان (كلما زادت = أكثر أماناً)

---

### Flutter Files

#### `flutter_app/lib/main.dart` - نقطة البداية

**ما يفعله:**
- يبدأ التطبيق
- يعرّف الشاشات والمسارات

**الكود الأساسي:**

```dart
void main() {
  runApp(const WuduhApp());
}

class WuduhApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وضوح',
      theme: AppTheme.darkTheme,
      routes: {
        '/': (context) => const HomeScreen(),
        '/route-setup': (context) => const RouteSetupScreen(),
      },
    );
  }
}
```

**شرح الكود:**
- `main()` - نقطة البداية (أول ما يُنفذ)
- `runApp()` - يبدأ التطبيق
- `MaterialApp` - التطبيق الرئيسي
- `routes` - قائمة الشاشات

#### `flutter_app/lib/src/services/api_service.dart` - الاتصال بالخادم

**ما يفعله:**
- يرسل طلبات HTTP للخادم
- يستقبل البيانات

**مثال الكود:**

```dart
class ApiService {
  // الحصول على بيانات المحاكاة
  Future<RadarSnapshot> getCurrentSimulation() async {
    final url = await getBaseUrl();
    final response = await http.get(
      Uri.parse('$url/api/v1/sim/current')
    );
    
    if (response.statusCode == 200) {
      return RadarSnapshot.fromJson(
        json.decode(response.body)
      );
    }
    throw Exception('فشل الاتصال');
  }
}
```

**شرح الكود:**
- `Future` - عملية غير متزامنة (تأخذ وقت)
- `async/await` - انتظار النتيجة
- `http.get()` - إرسال طلب GET
- `json.decode()` - تحويل JSON إلى كائن Dart

#### `flutter_app/lib/src/ui/screens/home_screen.dart` - الشاشة الرئيسية

**ما يفعله:**
- يعرض الخريطة والطقس
- يحدّث البيانات كل ثانيتين

**مثال الكود:**

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RadarSnapshot? _currentSnapshot;
  
  @override
  void initState() {
    super.initState();
    _loadData();  // تحميل البيانات عند البدء
  }
  
  Future<void> _loadData() async {
    final snapshot = await _apiService.getCurrentSimulation();
    setState(() {
      _currentSnapshot = snapshot;  // تحديث الواجهة
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentSnapshot != null
        ? SimpleMapWidget(snapshot: _currentSnapshot!)
        : CircularProgressIndicator(),
    );
  }
}
```

**شرح الكود:**
- `StatefulWidget` - ويدجت قابل للتحديث
- `initState()` - تُنفذ عند البدء
- `setState()` - يحدّث الواجهة
- `build()` - يبني الواجهة

---

## 🔧 كيفية بناء المشروع من الصفر

### 1. إنشاء Backend

#### الخطوة 1: إنشاء ملف `app.py`

```python
from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/api/v1/status', methods=['GET'])
def get_status():
    return jsonify({'status': 'running'})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
```

**شرح:**
- سطر 1-2: استيراد المكتبات
- سطر 4: إنشاء التطبيق
- سطر 5: تفعيل CORS
- سطر 7-9: تعريف واجهة API
- سطر 11-12: تشغيل الخادم

#### الخطوة 2: إنشاء `requirements.txt`

```
Flask==2.3.3
flask-cors==4.0.0
Werkzeug==2.3.7
itsdangerous==2.1.2
```

#### الخطوة 3: تثبيت المكتبات

```bash
pip install -r requirements.txt
```

#### الخطوة 4: تشغيل الخادم

```bash
python app.py
```

---

### 2. إنشاء Flutter App

#### الخطوة 1: إنشاء مشروع Flutter

```bash
flutter create wuduh_app
cd wuduh_app
```

#### الخطوة 2: إضافة المكتبات في `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  sqflite: ^2.3.0
  flutter_map: ^6.1.0
```

#### الخطوة 3: تثبيت المكتبات

```bash
flutter pub get
```

#### الخطوة 4: إنشاء `lib/main.dart`

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وضوح',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('وضوح')),
      body: Center(child: Text('مرحباً')),
    );
  }
}
```

#### الخطوة 5: تشغيل التطبيق

```bash
flutter run
```

---

## 📝 شرح الأكواد بالتفصيل

### مثال 1: واجهة API بسيطة

**الكود:**

```python
@app.route('/api/v1/hello', methods=['GET'])
def hello():
    name = request.args.get('name', 'زائر')
    return jsonify({
        'message': f'مرحباً {name}',
        'timestamp': datetime.now().isoformat()
    })
```

**الاستخدام:**

```bash
# في المتصفح أو Postman
GET http://127.0.0.1:5000/api/v1/hello?name=أحمد
```

**الرد:**

```json
{
  "message": "مرحباً أحمد",
  "timestamp": "2024-01-15T14:30:00"
}
```

**شرح السطور:**
- سطر 1: `@app.route()` - يعرّف العنوان `/api/v1/hello`
- سطر 2: `def hello()` - دالة تُنفذ عند الطلب
- سطر 3: `request.args.get()` - قراءة المعاملات من URL
- سطر 4-6: إرجاع JSON

---

### مثال 2: واجهة API مع POST

**الكود:**

```python
@app.route('/api/v1/user', methods=['POST'])
def create_user():
    data = request.json  # قراءة البيانات المرسلة
    
    username = data.get('username')
    password = data.get('password')
    
    # التحقق من البيانات
    if not username or not password:
        return jsonify({'error': 'البيانات ناقصة'}), 400
    
    # حفظ في قاعدة البيانات (مثال)
    # save_to_database(username, password)
    
    return jsonify({
        'success': True,
        'user_id': 1
    })
```

**الاستخدام (من Flutter):**

```dart
final response = await http.post(
  Uri.parse('http://127.0.0.1:5000/api/v1/user'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'username': 'ahmed',
    'password': '123456'
  }),
);
```

**شرح السطور:**
- سطر 1: `methods=['POST']` - نوع الطلب
- سطر 3: `request.json` - قراءة JSON المرسل
- سطر 5-6: استخراج البيانات
- سطر 9: التحقق من البيانات
- سطر 15: إرجاع النتيجة

---

### مثال 3: Flutter Widget بسيط

**الكود:**

```dart
class WeatherCard extends StatelessWidget {
  final double temperature;
  final double fogLevel;
  
  const WeatherCard({
    required this.temperature,
    required this.fogLevel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('الحرارة: $temperature°'),
            Text('الضباب: $fogLevel%'),
          ],
        ),
      ),
    );
  }
}
```

**الاستخدام:**

```dart
WeatherCard(
  temperature: 25.5,
  fogLevel: 45.0,
)
```

**شرح السطور:**
- سطر 1: `StatelessWidget` - ويدجت ثابت (لا يتغير)
- سطر 2-3: المتغيرات (parameters)
- سطر 5-8: البناء (constructor)
- سطر 10: `build()` - بناء الواجهة
- سطر 11-19: الواجهة (Card → Padding → Column → Text)

---

### مثال 4: Flutter StatefulWidget

**الكود:**

```dart
class CounterScreen extends StatefulWidget {
  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _count = 0;  // متغير الحالة
  
  void _increment() {
    setState(() {  // تحديث الواجهة
      _count++;    // زيادة العدد
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('العدد: $_count'),
            ElevatedButton(
              onPressed: _increment,
              child: Text('زيادة'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**شرح السطور:**
- سطر 1: `StatefulWidget` - ويدجت قابل للتحديث
- سطر 5: `State` - يحفظ الحالة
- سطر 6: `_count` - متغير الحالة
- سطر 8-12: دالة تحديث الحالة
- سطر 9: `setState()` - يحدّث الواجهة
- سطر 20: `$_count` - عرض القيمة

---

## 🗄️ قاعدة البيانات

### إنشاء الجداول

**الكود:**

```python
def init_db():
    conn = sqlite3.connect('wuduh.sqlite')
    cursor = conn.cursor()
    
    # إنشاء جدول المستخدمين
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            email TEXT
        )
    ''')
    
    conn.commit()
    conn.close()
```

**شرح:**
- `sqlite3.connect()` - الاتصال بقاعدة البيانات
- `CREATE TABLE` - إنشاء جدول
- `PRIMARY KEY` - المفتاح الأساسي
- `AUTOINCREMENT` - زيادة تلقائية
- `UNIQUE` - فريد (لا يتكرر)
- `NOT NULL` - مطلوب (لا يمكن أن يكون فارغاً)

### إدراج بيانات

**الكود:**

```python
def add_user(username, password, email):
    conn = sqlite3.connect('wuduh.sqlite')
    cursor = conn.cursor()
    
    password_hash = generate_password_hash(password)
    
    cursor.execute('''
        INSERT INTO users (username, password_hash, email)
        VALUES (?, ?, ?)
    ''', (username, password_hash, email))
    
    conn.commit()
    user_id = cursor.lastrowid
    conn.close()
    
    return user_id
```

**شرح:**
- `INSERT INTO` - إدراج بيانات
- `?` - placeholder (يتم استبداله بالقيم)
- `commit()` - حفظ التغييرات
- `lastrowid` - معرف السطر المضاف

### قراءة البيانات

**الكود:**

```python
def get_user(username):
    conn = sqlite3.connect('wuduh.sqlite')
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, username, email 
        FROM users 
        WHERE username = ?
    ''', (username,))
    
    user = cursor.fetchone()
    conn.close()
    
    return user
```

**شرح:**
- `SELECT` - قراءة البيانات
- `FROM` - من أي جدول
- `WHERE` - شرط البحث
- `fetchone()` - جلب سطر واحد

---

## 🔄 كيفية عمل التطبيق (تدفق البيانات)

### السيناريو: فتح الشاشة الرئيسية

```
1. المستخدم يفتح التطبيق
   ↓
2. main.dart يبدأ التطبيق
   ↓
3. HomeScreen تُحمّل
   ↓
4. initState() يُنفذ
   ↓
5. _loadData() يُستدعى
   ↓
6. ApiService.getCurrentSimulation()
   ↓
7. HTTP Request → http://127.0.0.1:5000/api/v1/sim/current
   ↓
8. Flask يستقبل الطلب
   ↓
9. radar_simulator.get_current_snapshot()
   ↓
10. إرجاع JSON
   ↓
11. Flutter يستقبل JSON
   ↓
12. RadarSnapshot.fromJson() يحول JSON إلى كائن
   ↓
13. setState() يحدّث الواجهة
   ↓
14. build() يعيد بناء الواجهة
   ↓
15. المستخدم يرى البيانات
```

---

## 🛠️ الأوامر الأساسية

### Backend

```bash
# تثبيت المكتبات
pip install -r requirements.txt

# تشغيل الخادم
python app.py

# تشغيل مع إعادة تحميل تلقائي (debug mode)
python app.py  # debug=True في الكود
```

### Flutter

```bash
# تثبيت الحزم
flutter pub get

# تشغيل التطبيق
flutter run

# بناء APK
flutter build apk

# بناء للويب
flutter build web

# تنظيف المشروع
flutter clean
```

---

## 📚 مصطلحات مهمة

### Backend (Python/Flask)

- **Route**: عنوان URL (مثل `/api/v1/status`)
- **Endpoint**: واجهة API (Route + Method)
- **Request**: الطلب من التطبيق
- **Response**: الرد من الخادم
- **JSON**: تنسيق البيانات
- **Database**: قاعدة البيانات

### Flutter (Dart)

- **Widget**: مكون واجهة المستخدم
- **State**: حالة الويدجت (البيانات المتغيرة)
- **Build**: بناء الواجهة
- **Async/Await**: عمليات غير متزامنة
- **Future**: وعد بنتيجة مستقبلية
- **setState**: تحديث الواجهة

---

## 🐛 حل المشاكل

### المشكلة: "ModuleNotFoundError"

**السبب**: المكتبة غير مثبتة

**الحل**:
```bash
pip install <اسم_المكتبة>
```

### المشكلة: "Package not found" في Flutter

**السبب**: الحزمة غير موجودة في `pubspec.yaml`

**الحل**:
1. أضف الحزمة في `pubspec.yaml`
2. شغّل `flutter pub get`

### المشكلة: "Connection refused"

**السبب**: الخادم غير قيد التشغيل

**الحل**:
1. تأكد من تشغيل `python app.py`
2. تحقق من العنوان: `127.0.0.1:5000`

---

## 📦 الملفات المهمة

### Backend

- `app.py` - الملف الرئيسي (يبدأ هنا)
- `modules/radar_simulator.py` - المحاكاة
- `modules/analyzer.py` - تحليل المسارات
- `modules/rules_engine.py` - قواعد التنبيهات
- `db/wuduh.sqlite` - قاعدة البيانات

### Flutter

- `lib/main.dart` - نقطة البداية
- `lib/src/services/api_service.dart` - الاتصال بالخادم
- `lib/src/ui/screens/` - الشاشات
- `lib/src/ui/widgets/` - المكونات
- `lib/themes/app_theme.dart` - الألوان والثيم

---

## ✅ قائمة التحقق

### قبل البدء

- [ ] Python 3.10.6 مثبت
- [ ] Flutter SDK مثبت
- [ ] VS Code أو محرر آخر

### إعداد Backend

- [ ] `cd backend`
- [ ] `pip install -r requirements.txt`
- [ ] `python app.py` يعمل

### إعداد Flutter

- [ ] `cd flutter_app`
- [ ] `flutter pub get`
- [ ] `flutter run` يعمل

---

## 🎯 الخطوات التالية

1. **فهم الكود**: اقرأ الملفات واحداً تلو الآخر
2. **تعديل بسيط**: غيّر نص أو لون
3. **إضافة ميزة**: أضف زر أو شاشة جديدة
4. **التجربة**: جرّب تغيير القيم

---

**نصيحة للمبتدئين**: ابدأ بقراءة `main.dart` ثم `app.py`، ثم انتقل تدريجياً للملفات الأخرى.
