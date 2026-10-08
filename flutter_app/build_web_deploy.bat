@echo off
REM سكريبت لبناء وتهيئة Flutter Web للرفع على Heroku

echo Building Flutter Web...
flutter build web --release

echo Copying server files...
copy server.py build\web\
copy Procfile build\web\
copy requirements.txt build\web\
copy static.json build\web\

echo Done! Now go to build\web and run:
echo git init
echo git add .
echo git commit -m "Deploy frontend"
echo heroku create wuduh-frontend --buildpack https://github.com/heroku/heroku-buildpack-static.git
echo git push heroku main

pause

