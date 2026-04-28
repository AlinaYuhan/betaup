# BetaUp Mobile Deployment

## 1. Prerequisites

- A working Flutter SDK. If `flutter.bat` is broken on Windows, use:
  `powershell -ExecutionPolicy Bypass -File .\tool\flutterw.ps1 --version`
- Android SDK and accepted licenses
- A public backend URL such as `https://api.example.com/api`

## 2. Required runtime defines

The mobile app expects the API base URL at build time:

```powershell
--dart-define=BETAUP_API_BASE_URL=https://api.example.com/api
```

The voice assistant now talks to the backend proxy. Do not put the DeepSeek key
into the Flutter build.

Configure these on the backend instead:

```bash
BETAUP_DEEPSEEK_API_KEY=your_deepseek_key
BETAUP_DEEPSEEK_ENDPOINT=https://api.deepseek.com/v1/chat/completions
BETAUP_DEEPSEEK_MODEL=deepseek-chat
```

## 3. Android sideload build

Debug APK:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\flutterw.ps1 build apk --debug --dart-define=BETAUP_API_BASE_URL=https://api.example.com/api
```

Release APK:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\flutterw.ps1 build apk --release --dart-define=BETAUP_API_BASE_URL=https://api.example.com/api
```

If your project is stored under a Windows path with Chinese or other non-ASCII
characters, prefer the helper script below. It builds through an ASCII junction
path to avoid `app.dill` / AOT snapshot errors:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_android.ps1 --release --dart-define=BETAUP_API_BASE_URL=https://api.example.com/api
```

Generated APK:

- `build\app\outputs\flutter-apk\app-release.apk`

## 4. Play Store ready signing

Create `android/key.properties`:

```properties
storeFile=C:/path/to/your-upload-keystore.jks
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

This file is ignored by git. The Android build also supports the same values
through environment variables:

- `BETAUP_ANDROID_STORE_FILE`
- `BETAUP_ANDROID_STORE_PASSWORD`
- `BETAUP_ANDROID_KEY_ALIAS`
- `BETAUP_ANDROID_KEY_PASSWORD`

If no release signing config is provided, the project falls back to the debug
key so local release builds still work.

## 5. Backend deployment notes

For real phones to use the app, the backend cannot stay on `localhost`.
You need:

- A public server or cloud VM
- Spring Boot running on that server
- A public HTTPS domain
- Persistent MySQL instead of local dev H2 if you want shared user data

Recommended production env vars:

```bash
SPRING_PROFILES_ACTIVE=mysql
BETAUP_DB_URL=jdbc:mysql://<host>:3306/<database>?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true
BETAUP_DB_USERNAME=<username>
BETAUP_DB_PASSWORD=<password>
BETAUP_JWT_SECRET=<strong_random_secret>
BETAUP_UPLOAD_DIR=/var/betaup/uploads
BETAUP_DEEPSEEK_API_KEY=<your_deepseek_key>
BETAUP_DEEPSEEK_ENDPOINT=https://api.deepseek.com/v1/chat/completions
BETAUP_DEEPSEEK_MODEL=deepseek-chat
```

## 6. Suggested rollout

1. Deploy the backend first and verify `https://your-domain/api/auth/status`.
2. Build an Android release APK with the public API URL.
3. Install the APK on your phone and verify login, posts, media, GPS, and voice assistant.
4. If you want store distribution, switch from debug signing fallback to your own upload keystore and build an AAB.
