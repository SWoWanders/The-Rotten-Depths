#!/usr/bin/env bash
# Wraps this repo's web app (index.html + assets) in a Capacitor Android shell
# and builds an unsigned release APK. Run by .github/workflows/android-apk.yml.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
cd "$HERE"

APP_ID="$(node -p "require('./capacitor.config.json').appId")"
VERSION_CODE="${VERSION_CODE:-1}"
VERSION_NAME="${VERSION_NAME:-1.0.$VERSION_CODE}"

echo "==> Copying web files into www/"
rm -rf www && mkdir www
tar -C "$ROOT" -cf - \
  --exclude './.git' --exclude './.github' --exclude './android-app' \
  --exclude './README.md' --exclude './.nojekyll' . | tar -C www -xf -
test -f www/index.html || { echo "::error::index.html not found in repo root"; exit 1; }

# App-only tweaks (the website itself is never changed):
#   overrides/  files copied over the web files
#   inject.html snippet inserted right after <head> in index.html
if [ -d overrides ]; then cp -r overrides/. www/; fi
if [ -f inject.html ]; then
  node -e '
    const fs=require("fs"); const f="www/index.html";
    const html=fs.readFileSync(f,"utf8"); const snip=fs.readFileSync("inject.html","utf8");
    if(!/<head[^>]*>/i.test(html)){console.error("::error::no <head> tag to inject into");process.exit(1)}
    fs.writeFileSync(f, html.replace(/<head[^>]*>/i, m=>m+"\n"+snip));
  '
fi

echo "==> Installing Capacitor"
npm install --no-audit --no-fund

echo "==> Creating Android project"
rm -rf android
npx cap add android
npx cap sync android

echo "==> Version $VERSION_NAME ($VERSION_CODE)"
sed -i -E "s/versionCode [0-9]+/versionCode $VERSION_CODE/; s/versionName \"[^\"]*\"/versionName \"$VERSION_NAME\"/" android/app/build.gradle

echo "==> App icons"
cp -r res/* android/app/src/main/res/

if [ -d native ]; then
  echo "==> Custom native code"
  PKG_DIR="android/app/src/main/java/$(echo "$APP_ID" | tr . /)"
  cp native/*.java "$PKG_DIR"/
fi

echo "==> Gradle build"
cd android
chmod +x gradlew
./gradlew assembleRelease --no-daemon --stacktrace
ls -la app/build/outputs/apk/release/
