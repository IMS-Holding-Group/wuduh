#!/bin/bash
# سكريبت لبناء وتهيئة Flutter Web للرفع على Heroku

echo "Building Flutter Web..."
flutter build web --release

echo "Copying server files..."
cp server.py build/web/
cp Procfile build/web/
cp requirements.txt build/web/
cp static.json build/web/

echo "Done! Now go to build/web and run:"
echo "git init"
echo "git add ."
echo "git commit -m 'Deploy frontend'"
echo "heroku create wuduh-frontend --buildpack https://github.com/heroku/heroku-buildpack-static.git"
echo "git push heroku main"

