# دليل رفع تطبيق وضوح (Wuduh) على الويب

## 📋 المحتويات
1. [بناء تطبيق Flutter للويب](#1-بناء-تطبيق-flutter-للويب)
2. [إعداد Backend (Flask)](#2-إعداد-backend-flask)
3. [خيارات الاستضافة](#3-خيارات-الاستضافة)
4. [خطوات الرفع لكل منصة](#4-خطوات-الرفع-لكل-منصة)

---

## 1. بناء تطبيق Flutter للويب

### الخطوة 1: تفعيل دعم الويب في Flutter
```bash
cd flutter_app
flutter config --enable-web
flutter devices  # للتأكد من ظهور Chrome
```

### الخطوة 2: بناء التطبيق
```bash
flutter build web --release
```

سيتم إنشاء الملفات في: `flutter_app/build/web/`

### الخطوة 3: تعديل إعدادات API
في ملف `flutter_app/lib/src/services/api_service.dart`، غيّر `baseUrl` إلى:
```dart
static const String baseUrl = 'https://your-backend-domain.com';
```

---

## 2. إعداد Backend (Flask)

### الخطوة 1: إعداد CORS
تأكد من أن `app.py` يحتوي على:
```python
from flask_cors import CORS
app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})  # للسماح بجميع المصادر
```

### الخطوة 2: إعدادات الإنتاج
أنشئ ملف `backend/config.py`:
```python
import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your-secret-key-here'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///wuduh.sqlite'
    DEBUG = False
```

---

## 3. خيارات الاستضافة

### 🥇 **Netlify** (الأفضل للـ Frontend)
**المميزات:**
- ✅ مجاني للاستخدام الشخصي
- ✅ رفع سهل (سحب وإفلات)
- ✅ HTTPS تلقائي
- ✅ CDN عالمي
- ✅ دعم CI/CD مع GitHub

**العيوب:**
- ❌ لا يدعم Python/Flask مباشرة (يحتاج Backend منفصل)

### 🥈 **Vercel** (مشابه لـ Netlify)
**المميزات:**
- ✅ مجاني
- ✅ أداء ممتاز
- ✅ دعم Serverless Functions (يمكن تشغيل Flask)

**العيوب:**
- ❌ يحتاج إعدادات إضافية للـ Backend

### 🥉 **Firebase Hosting** (جيد للـ Frontend + Backend)
**المميزات:**
- ✅ مجاني (بحدود)
- ✅ دعم Firebase Functions (Backend)
- ✅ CDN قوي

**العيوب:**
- ❌ يحتاج حساب Google
- ❌ إعدادات معقدة قليلاً

### 🌐 **Render** (الأفضل للـ Backend)
**المميزات:**
- ✅ مجاني للـ Backend
- ✅ دعم Python/Flask مباشرة
- ✅ قاعدة بيانات مجانية
- ✅ HTTPS تلقائي

**العيوب:**
- ❌ قد يكون بطيء في البداية (Free Tier)

### 🐳 **Railway** (ممتاز للـ Backend)
**المميزات:**
- ✅ مجاني ($5 رصيد شهري)
- ✅ دعم Python/Flask
- ✅ قاعدة بيانات SQLite أو PostgreSQL
- ✅ سريع جداً

---

## 4. خطوات الرفع لكل منصة

### 📦 **الخيار الموصى به: Netlify (Frontend) + Render (Backend)**

---

### 🎯 **الجزء 1: رفع Backend على Render**

#### الخطوة 1: إنشاء حساب على Render
1. اذهب إلى: https://render.com
2. سجل بحساب GitHub

#### الخطوة 2: إعداد المشروع
1. في GitHub، أنشئ ملف `backend/render.yaml`:
```yaml
services:
  - type: web
    name: wuduh-backend
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn app:app
    envVars:
      - key: PYTHON_VERSION
        value: 3.10.6
```

2. أنشئ ملف `backend/Procfile`:
```
web: gunicorn app:app --bind 0.0.0.0:$PORT
```

3. أضف `gunicorn` إلى `backend/requirements.txt`:
```
Flask==2.3.3
flask-cors==4.0.0
Werkzeug==2.3.7
itsdangerous==2.1.2
python-dateutil==2.8.2
gunicorn==21.2.0
```

#### الخطوة 3: رفع Backend
1. في Render Dashboard:
   - اضغط "New +" → "Web Service"
   - اربط مستودع GitHub
   - اختر المجلد `backend`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `gunicorn app:app --bind 0.0.0.0:$PORT`
   - اضغط "Create Web Service"

2. بعد النشر، ستحصل على رابط مثل: `https://wuduh-backend.onrender.com`

---

### 🎨 **الجزء 2: رفع Frontend على Netlify**

#### الطريقة 1: رفع يدوي (الأسهل)
1. اذهب إلى: https://app.netlify.com
2. سجل بحساب GitHub
3. في Dashboard:
   - اسحب مجلد `flutter_app/build/web` إلى Netlify
   - سيتم الرفع تلقائياً
   - ستحصل على رابط مثل: `https://random-name-123.netlify.app`

#### الطريقة 2: ربط GitHub (موصى به)
1. في Netlify Dashboard:
   - اضغط "Add new site" → "Import an existing project"
   - اختر مستودع GitHub
   - Build settings:
     - **Base directory:** `flutter_app`
     - **Build command:** `flutter build web --release`
     - **Publish directory:** `flutter_app/build/web`
   - اضغط "Deploy site"

#### الخطوة 3: تحديث API URL
1. في `flutter_app/lib/src/services/api_service.dart`:
```dart
static const String baseUrl = 'https://wuduh-backend.onrender.com';
```

2. أعد البناء:
```bash
flutter build web --release
```

3. في Netlify، اضغط "Trigger deploy" → "Clear cache and deploy site"

---

### 🔄 **الخيار البديل: Vercel (Frontend + Backend)**

#### رفع Frontend على Vercel:
1. اذهب إلى: https://vercel.com
2. سجل بحساب GitHub
3. اضغط "Add New Project"
4. اختر المستودع
5. Build Settings:
   - **Framework Preset:** Other
   - **Root Directory:** `flutter_app`
   - **Build Command:** `flutter build web --release`
   - **Output Directory:** `build/web`
6. اضغط "Deploy"

#### رفع Backend على Vercel (Serverless):
1. أنشئ ملف `backend/api/index.py`:
```python
from app import app

def handler(request):
    return app(request.environ, request.start_response)
```

2. أنشئ ملف `backend/vercel.json`:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "api/index.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "api/index.py"
    }
  ]
}
```

---

### 🚀 **الخيار السريع: Firebase Hosting**

#### الخطوة 1: تثبيت Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

#### الخطوة 2: تهيئة المشروع
```bash
cd flutter_app
firebase init hosting
# اختر: build/web كمجلد النشر
```

#### الخطوة 3: البناء والرفع
```bash
flutter build web --release
firebase deploy
```

---

## 📝 ملاحظات مهمة

### 1. تحديث CORS في Backend
في `backend/app.py`:
```python
CORS(app, resources={
    r"/api/*": {
        "origins": [
            "https://your-netlify-app.netlify.app",
            "https://your-vercel-app.vercel.app"
        ],
        "methods": ["GET", "POST", "PUT", "DELETE"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
```

### 2. متغيرات البيئة
في Render/Vercel، أضف متغيرات البيئة:
- `SECRET_KEY`: مفتاح سري للجلسات
- `DATABASE_URL`: رابط قاعدة البيانات (إن وجد)

### 3. قاعدة البيانات
- **SQLite:** يعمل محلياً فقط، لا يعمل على الاستضافة
- **PostgreSQL:** استخدم Render PostgreSQL (مجاني) أو Railway

### 4. تحديث قاعدة البيانات
في Render، أضف Build Command:
```bash
python -c "from app import init_db; init_db()"
```

---

## ✅ الخلاصة - الخيار الموصى به

**للبدء السريع:**
1. **Frontend:** Netlify (مجاني، سهل، سريع)
2. **Backend:** Render (مجاني، يدعم Python مباشرة)

**للأداء الأفضل:**
1. **Frontend:** Vercel (أسرع CDN)
2. **Backend:** Railway (أسرع، لكن يحتاج بطاقة ائتمانية)

---

## 🔗 روابط مفيدة

- [Netlify Docs](https://docs.netlify.com/)
- [Render Docs](https://render.com/docs)
- [Vercel Docs](https://vercel.com/docs)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

