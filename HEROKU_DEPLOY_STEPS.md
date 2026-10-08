# خطوات رفع التطبيق على Heroku

## 📦 الملفات التي تم إنشاؤها:

### Backend:
- ✅ `backend/runtime.txt` - إصدار Python
- ✅ `backend/Procfile` - أوامر التشغيل
- ✅ `backend/requirements.txt` - المكتبات المطلوبة

### Frontend:
- ✅ `flutter_app/server.py` - خادم Flask للـ Frontend
- ✅ `flutter_app/Procfile` - أوامر التشغيل
- ✅ `flutter_app/requirements.txt` - المكتبات المطلوبة
- ✅ `flutter_app/static.json` - إعدادات Static Buildpack
- ✅ `flutter_app/build_web_deploy.bat` - سكريبت تلقائي للبناء

---

## 🚀 خطوات الرفع:

### 1️⃣ رفع Backend:

```bash
cd backend
heroku login
heroku create wuduh-backend
git init
git add .
git commit -m "Deploy backend"
git push heroku main
```

### 2️⃣ بناء Frontend:

```bash
cd flutter_app
flutter build web --release
```

### 3️⃣ نسخ الملفات المطلوبة:

```bash
copy server.py build\web\
copy Procfile build\web\
copy requirements.txt build\web\
copy static.json build\web\
```

أو استخدم السكريبت:
```bash
build_web_deploy.bat
```

### 4️⃣ تحديث API URL:

في `flutter_app/lib/src/services/api_service.dart`، تأكد من وجود رابط Heroku في القائمة.

### 5️⃣ إعادة البناء:

```bash
flutter build web --release
copy server.py build\web\
copy Procfile build\web\
copy requirements.txt build\web\
copy static.json build\web\
```

### 6️⃣ رفع Frontend:

```bash
cd build\web
git init
git add .
git commit -m "Deploy frontend"
heroku create wuduh-frontend --buildpack https://github.com/heroku/heroku-buildpack-static.git
git push heroku main
```

---

## 📝 ملاحظات:

1. بعد رفع Backend، احصل على الرابط:
   ```bash
   heroku apps:info -a wuduh-backend
   ```

2. غيّر `baseUrl` في Flutter إلى رابط Backend.

3. أعد بناء Frontend وارفعه مرة أخرى.

4. للتحقق من الـ Logs:
   ```bash
   heroku logs --tail -a wuduh-backend
   heroku logs --tail -a wuduh-frontend
   ```

---

## ✅ جاهز للرفع!

