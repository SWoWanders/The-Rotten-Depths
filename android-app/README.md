# Android wrapper

Turns this web app into an installable Android APK using Capacitor.
Every push to `main` triggers `.github/workflows/android-apk.yml`, which runs
`build.sh` on GitHub's servers and posts the APK under **Releases → Latest**.

- `capacitor.config.json` — app ID, name, background colour
- `res/` — launcher icons (copied over Capacitor's defaults)
- `native/` — optional Java overrides (e.g. fullscreen MainActivity)
- `build.sh` — copies the web files, creates the Android project, builds

Signing: add repo secrets `ANDROID_KEYSTORE_B64` and `ANDROID_KEYSTORE_PASSWORD`
so every build is signed with the same key and installs over the last one.
Without them each build uses a throwaway key.

Nothing in here affects the GitHub Pages site.
